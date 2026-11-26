#!/usr/bin/env bash
# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

set -euo pipefail
infer_bin=$(realpath "$1")
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
bin_dir=$(dirname "$infer_bin")
# Normalise the directory but keep the `clang` name: infer picks its integration from the
# basename of the compiler, and the shipped `clang` is a symlink to a versioned binary, so
# resolving it yields e.g. `clang-21` and infer stops with "Unsupported build command".
clang_dir=$(cd -- "$bin_dir/../../facebook-clang-plugins/clang/install/bin" && pwd -P)
compiler="$clang_dir/clang"
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/infer-static-assert.XXXXXX")
last_log=""
cleanup() {
  local code=$?
  if [[ $code != 0 && -f $last_log ]]; then sed -n '1,160p' "$last_log"; fi
  rm -rf -- "$test_dir"
}
trap cleanup EXIT
cp "$source_dir/static_assert_capture.cpp" "$test_dir/capture.cpp"
cp "$source_dir/static_assert_controls.cpp" "$test_dir/controls.cpp"

check_compiler() {
  local language=$1 standard=$2 outcome=$3 code
  # bash 3.2 reports an empty array as unset under `set -u`, so guard the expansions.
  local options=()
  if [[ $outcome == failure ]]; then options=(-DASSERTION_SHOULD_FAIL); fi
  local name="$language-$standard-$outcome"
  last_log="$test_dir/$name-raw.log"
  set +e
  "$compiler" -x "$language" "-std=$standard" ${options[@]+"${options[@]}"} \
    -fsyntax-only "$test_dir/capture.cpp" > "$last_log" 2>&1
  code=$?
  set -e
  if [[ $outcome == success ]]; then test "$code" -eq 0; else test "$code" -ne 0; fi
  last_log="$test_dir/$name-capture.log"
  set +e
  "$infer_bin" capture --jobs 1 --no-progress-bar --results-dir "$test_dir/$name" \
    --project-root "$test_dir" -- "$compiler" -x "$language" "-std=$standard" \
    ${options[@]+"${options[@]}"} -c "$test_dir/capture.cpp" -o "$test_dir/$name.o" > "$last_log" 2>&1
  code=$?
  set -e
  if [[ $outcome == success ]]; then
    test "$code" -eq 0
    "$infer_bin" debug --results-dir "$test_dir/$name" --procedures --procedures-name \
      --no-procedures-source-file | grep -q static_assert_ordinary_declaration_control
  else
    test "$code" -ne 0
    grep -q 'static assertion failed' "$last_log"
    if grep -Eq 'End_of_input|ERROR RUNNING CAPTURE|Uncaught Internal Error' "$last_log"; then
      return 1
    fi
  fi
  printf 'PASS: static_assert %s\n' "$name"
}

for standard in c++11 c++14 c++17 c++20; do
  check_compiler c++ "$standard" success
  check_compiler c++ "$standard" failure
done
check_compiler c c11 success
check_compiler c c11 failure

for mode in erased keyword; do
  options=()
  if [[ $mode == erased ]]; then options=(-DERASE_CPP_ASSERTIONS); fi
  last_log="$test_dir/controls-$mode.log"
  "$infer_bin" capture --frontend-tests --jobs 1 --no-progress-bar \
    --results-dir "$test_dir/controls-$mode" --project-root "$test_dir" -- \
    "$compiler" -x c++ -std=c++20 ${options[@]+"${options[@]}"} -c "$test_dir/controls.cpp" \
    -o "$test_dir/controls-$mode.o" > "$last_log" 2>&1
  mv "$test_dir/controls.cpp.test.dot" "$test_dir/controls-$mode.dot"
done
diff -u "$test_dir/controls-erased.dot" "$test_dir/controls-keyword.dot"
printf 'PASS: static_assert declarations and nearby keywords preserve CFGs\n'

for mode in restored keyword; do
  options=()
  if [[ $mode == restored ]]; then options=(-DRESTORE_CPP_KEYWORD); fi
  last_log="$test_dir/reports-$mode.log"
  "$infer_bin" run --jobs 1 --no-progress-bar --results-dir "$test_dir/reports-$mode" \
    --project-root "$test_dir" -- "$compiler" -x c++ -std=c++20 ${options[@]+"${options[@]}"} \
    -c "$test_dir/capture.cpp" -o "$test_dir/reports-$mode.o" > "$last_log" 2>&1
done
python3 - "$test_dir" <<'PY'
import json
import sys
from pathlib import Path
root = Path(sys.argv[1])
before = (root / 'reports-restored/report.json').read_bytes()
after = (root / 'reports-keyword/report.json').read_bytes()
assert before == after, 'Restored keyword and normal capture reports differ'
reports = json.loads(after)
assert len(reports) == 1, reports
assert reports[0]['bug_type'] == 'NULLPTR_DEREFERENCE', reports
assert reports[0]['procedure'].startswith('static_assert_runtime_null_bad'), reports
PY
printf 'PASS: static_assert compile-time lambda is clear and runtime null reports\n'
