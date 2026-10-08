/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

void null_dereference_before_syntax_error_bad() {
  int* p = 0;
  *p = 42;
}

int syntax_error() { return UNDECLARED; }
