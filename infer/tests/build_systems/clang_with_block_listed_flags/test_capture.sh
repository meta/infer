#!/usr/bin/env bash
# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

set -euo pipefail
infer_bin=$(realpath "$1")
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/infer-clang-capture.XXXXXX")
last_log=""
cleanup() {
  local code=$?
  if [[ $code != 0 && -f $last_log ]]; then sed -n '1,160p' "$last_log"; fi
  rm -rf -- "$test_dir"
}
trap cleanup EXIT
source_file="$source_dir/capture_regression.c"
blocked=(--clang-block-listed-flags-with-arg=-bogus-one
         --clang-block-listed-flags-with-arg=-bogus-two
         --clang-block-listed-flags-with-arg=-bogus-three)

assert_absent() {
  if grep -Eq "$1" "$2"; then
    sed -n '1,160p' "$2"
    return 1
  fi
}

capture_filtered() {
  local name=$1
  shift
  last_log="$test_dir/$name.log"
  "$infer_bin" capture --no-progress-bar --jobs 1 "${blocked[@]}" \
    --results-dir "$test_dir/$name" -- clang -Xclang -disable-O0-optnone \
    -Xclang -D -Xclang CAPTURE_FLAG=1 \
    "$@" -c "$source_file" -o "$test_dir/$name.o" > "$test_dir/$name.log" 2>&1 ||
    { sed -n '1,160p' "$test_dir/$name.log"; return 1; }
  "$infer_bin" debug --results-dir "$test_dir/$name" --procedures --procedures-name \
    --no-procedures-source-file | grep -q 'capture_ok'
  printf 'PASS: %s\n' "$name"
}

capture_filtered direct -Xclang -bogus-one=alpha=message \
  -Xclang -bogus-two=beta=message -Xclang -bogus-three=gamma=message
capture_filtered response "@$source_dir/flags.rsp"
capture_filtered separate_argument -Xclang -mllvm -Xclang -unsupported-llvm-option
capture_filtered response_separate_argument "@$source_dir/pending_arg.rsp" \
  -Xclang -unsupported-llvm-option
capture_filtered response_trailing_wrapper "@$source_dir/wrapper.rsp" -bogus-one=alpha=message

last_log="$test_dir/compilation_database.log"
sed "s@%source_dir%@$source_dir@g" "$source_dir/compile_commands.json.in" \
  > "$test_dir/compile_commands.json"
"$infer_bin" capture --keep-going --no-progress-bar --jobs 1 \
  --results-dir "$test_dir/compilation_database" \
  --compilation-database "$test_dir/compile_commands.json" > "$last_log" 2>&1
grep -q '1 of 2 compilation commands failed' "$last_log"
"$infer_bin" debug --results-dir "$test_dir/compilation_database" --procedures \
  --procedures-name --no-procedures-source-file | grep -q 'capture_ok'
printf 'PASS: compilation_database_keep_going\n'

# A private copy gives this test its own compiler path without changing the real installation.
bin_dir=$(dirname "$infer_bin")
native_bin="$infer_bin"
if [[ -x $bin_dir/infer.exe ]]; then native_bin="$bin_dir/infer.exe"; fi
mock_root="$test_dir/runtime"
mock_bin="$mock_root/infer/bin"
mock_compiler="$mock_root/facebook-clang-plugins/clang/install/bin/clang"
mkdir -p "$mock_bin" "$(dirname "$mock_compiler")"
cp "$native_bin" "$mock_bin/infer.exe"
if [[ $infer_bin == "$native_bin" ]]; then
  ln -s infer.exe "$mock_bin/infer"
else
  cp "$infer_bin" "$mock_bin/infer"
fi
for resource in config etc lib; do
  ln -s "$bin_dir/../$resource" "$mock_root/infer/$resource"
done
if [[ -d $bin_dir/../libso ]]; then
  ln -s "$bin_dir/../libso" "$mock_root/infer/libso"
fi
cp "$source_dir/mock_clang.sh" "$mock_compiler"
chmod +x "$mock_compiler"

check_stream() {
  local name=$1 compiler_exit=$2 stream=$3 keep_going=$4
  local options=() code
  last_log="$test_dir/$name.log"
  if [[ $keep_going == yes ]]; then options=(--keep-going); fi
  set +e
  # Bash 3.2 reports an empty array as unset under `set -u`, so guard the expansion.
  CLANG_CAPTURE_TEST_EXIT=$compiler_exit CLANG_CAPTURE_TEST_STREAM=$stream \
    CLANG_CAPTURE_TEST_SOURCE=$source_file \
    "$mock_bin/infer" capture --no-progress-bar --jobs 1 ${options[@]+"${options[@]}"} \
    --results-dir "$test_dir/$name" -- clang -c "$source_file" \
    > "$test_dir/$name.log" 2>&1
  code=$?
  set -e
  if [[ $compiler_exit != 0 ]]; then
    test "$code" -eq "$compiler_exit"
    grep -q 'did not run successfully' "$test_dir/$name.log"
    assert_absent 'End_of_input|ERROR RUNNING CAPTURE|Uncaught Internal Error' "$test_dir/$name.log"
  else
    assert_absent 'did not run successfully' "$test_dir/$name.log"
    if [[ $keep_going == yes ]]; then
      test "$code" -eq 0
      grep -q 'ERROR RUNNING CAPTURE' "$test_dir/$name.log"
    else
      test "$code" -ne 0
      grep -q 'Uncaught Internal Error' "$test_dir/$name.log"
    fi
  fi
  printf 'PASS: %s\n' "$name"
}

check_stream failed_empty 7 empty no
check_stream failed_corrupt 7 corrupt no
check_stream failed_empty_keep_going 7 empty yes
check_stream failed_corrupt_keep_going 7 corrupt yes
check_stream successful_empty 0 empty no
check_stream successful_corrupt 0 corrupt no
check_stream successful_empty_keep_going 0 empty yes
check_stream successful_corrupt_keep_going 0 corrupt yes

bash "$source_dir/test_static_assert.sh" "$infer_bin"
python3 "$source_dir/test_libcxx_warning.py" "$infer_bin"
