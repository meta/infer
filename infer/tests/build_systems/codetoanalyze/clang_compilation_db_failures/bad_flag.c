/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// Two unknown flags produce separate driver errors. Parallel capture must report
// this command as failed even when it keeps going with the other files.

void null_dereference_in_file_not_captured() {
  int* p = 0;
  *p = 42;
}
