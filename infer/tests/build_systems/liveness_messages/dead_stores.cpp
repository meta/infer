/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

struct Counter {
  Counter(const Counter& other) : n(other.n) {}
  int n;
};

int overwritten_local_bad(int a) {
  int x = a + 1;
  x = 3;
  return a;
}

void unused_copy_bad(const Counter& c) { Counter copy = c; }
