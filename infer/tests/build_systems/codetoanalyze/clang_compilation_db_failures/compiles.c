/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

void null_dereference_in_compiled_file_bad() {
  int* p = 0;
  *p = 42;
}
