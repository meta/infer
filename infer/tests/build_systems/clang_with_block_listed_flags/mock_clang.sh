#!/usr/bin/env bash
# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

set -euo pipefail
for arg in "$@"; do
  if [[ $arg == -### ]] ||
     { [[ $arg == @* ]] && grep -q -- '-###' "${arg#@}"; }; then
    printf ' "%s" "-cc1" "-x" "c" "%s"\n' "$0" "$CLANG_CAPTURE_TEST_SOURCE"
    exit 0
  fi
done

if [[ $CLANG_CAPTURE_TEST_STREAM == corrupt ]]; then
  printf 'not a biniou AST\n'
fi
exit "$CLANG_CAPTURE_TEST_EXIT"
