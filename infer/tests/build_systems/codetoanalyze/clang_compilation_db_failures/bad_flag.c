/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// The compilation command of this file has an unknown flag, so clang does not
// parse the file and nothing in it is captured.

void null_dereference_in_file_not_captured() {
  int* p = 0;
  *p = 42;
}
