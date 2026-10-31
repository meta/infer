#!/bin/bash
# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#
# Exporting a long line costs time proportional to its length squared when the line has no
# terminator, because SourceManager has to find the start of the line for every location on
# it. Export one such line and fail if it takes more CPU time than a line of that length can
# justify. The limit is far above what the export costs when it is linear and far below what
# it costs when it is not, so the result does not depend on how busy the machine is.
set -u
CLANG=${CLANG:-clang++}
PLUGIN=${PLUGIN:?set PLUGIN to the path of FacebookClangPlugin.dylib}
ELEMENTS=${ELEMENTS:-100000}
CPU_LIMIT=${CPU_LIMIT:-60}

DIR=$(mktemp -d); trap 'rm -rf "$DIR"' EXIT
python3 -c "
import sys
n = int(sys.argv[1])
open(sys.argv[2] + '/blob.inc', 'w').write(','.join(str(i % 251) for i in range(n)))
open(sys.argv[2] + '/blob.cpp', 'w').write(
    'constexpr unsigned char kBlob[] = {\n#include \"blob.inc\"\n};\n'
    'const unsigned char* blob() { return kBlob; }\n')
" "$ELEMENTS" "$DIR" || exit 1

( ulimit -t "$CPU_LIMIT"
  "$CLANG" -std=c++20 -c "$DIR/blob.cpp" -o /dev/null -I"$DIR" \
    -Xclang -load -Xclang "$PLUGIN" \
    -Xclang -add-plugin -Xclang BiniouASTExporter \
    -Xclang -plugin-arg-BiniouASTExporter -Xclang - \
    -Xclang -plugin-arg-BiniouASTExporter -Xclang PREPEND_CURRENT_DIR=1 \
    -Xclang -plugin-arg-BiniouASTExporter -Xclang MAX_STRING_SIZE=65535 \
    > /dev/null 2>&1 )
STATUS=$?
if [ $STATUS -ne 0 ]; then
  printf '[!] exporting %s elements on an unterminated line used more than %ss of CPU\n' \
    "$ELEMENTS" "$CPU_LIMIT"
  exit 1
fi
printf '[+] exported %s elements on an unterminated line within %ss of CPU\n' \
  "$ELEMENTS" "$CPU_LIMIT"
