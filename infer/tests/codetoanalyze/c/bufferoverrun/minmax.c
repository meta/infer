/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

int exact_min_minus_min_linear_CAF(int x) {
  int size1[1];
  int y = 28;
  if (x < 5)
    y = x + 10;
  // y = [10 + min(18, x), 28]
  if (y > 28) {
    size1[-1] = 0;
  }
  return y;
}

int underapprox_min_minus_min_linear_CAF(int x) {
  int size1[1];
  int y = 10;
  if (x < 5)
    y = x + 20;
  // y = [20 + min(-10, x), 24]
  if (y > 24) {
    size1[-1] = 0;
  }
  return y;
}

void exact_min_plus_min_plus_min_UNDERRUN(int x, int b) {
  int size1[1];
  int y = exact_min_minus_min_linear_CAF(x);
  if (b)
    y = underapprox_min_minus_min_linear_CAF(x);
  y -= 29;
  // [-19 + min(0, x), -1]
  size1[y] = 0;
}

int random();

int exact_minmax_sym(int x) {
  if (random()) {
    if (x > 1) {
      x = 1;
    } // [min(1, x), 1]
    x = x + 1; // [1 + min(1, x), 2]
  } // [min(2, x), max(2, x)]
  return x;
}

void call_exact_minmax_sym_Good() {
  int x = 5;
  int a[x];
  a[exact_minmax_sym(x) - 1] = 0;
}

void call_exact_minmax_sym_Bad() {
  int x = 5;
  int a[x];
  a[exact_minmax_sym(x)] = 0;
}

int exact_max_plus_max_sym(int x, int b) {
  int k = x;
  if (k < -1) {
    k = -1;
  } // [max(-1, x), max(-1, x)]
  k = k + 1; // [0, 1 + max(-1, x)]
  int m = x;
  if (m < 2) {
    m = 2;
  } // [2, max(2, x)]
  return b ? k : m; // [0, 1 + max(1, x)]
}

void call_exact_max_plus_max_sym_Bad() {
  char a[2];
  // the return value is 2 when the second branch is taken
  a[exact_max_plus_max_sym(-20, random())] = 0;
}

void call_exact_max_plus_max_sym_Good() {
  char a[3];
  a[exact_max_plus_max_sym(-20, random())] = 0;
}

int exact_min_minus_max_sym(int x, int b) {
  int p = x;
  if (p < 0) {
    p = 0;
  }
  int q = x;
  if (q < 8) {
    q = 8;
  }
  int u = 0 - p; // [-max(0, x), 0]
  int v = 5 - q; // [5 - max(8, x), -3]
  return b ? u : v; // [-max(3, x), 0]
}

void call_exact_min_minus_max_sym_Bad() {
  int a[10];
  // the return value is -3 when the second branch is taken
  a[exact_min_minus_max_sym(0, random())] = 0;
}

void call_exact_min_minus_max_sym_Good() {
  int a[10];
  a[exact_min_minus_max_sym(0, random()) + 3] = 0;
}

unsigned int exact_max_plus_max_unsigned(unsigned int x, int b) {
  unsigned int k = x;
  if (k < 1) {
    k = 1;
  }
  k = k + 1; // [1, 1 + max(1, x)]
  unsigned int m = x;
  if (m < 4) {
    m = 4;
  }
  // [4, max(4, x)]
  return b ? k : m; // [1, 1 + max(3, x)]
}

void call_exact_max_plus_max_unsigned_Bad() {
  char a[4];
  // the return value is 4 when the second branch is taken
  a[exact_max_plus_max_unsigned(0, random())] = 0;
}

void call_exact_max_plus_max_unsigned_Good() {
  char a[5];
  a[exact_max_plus_max_unsigned(0, random())] = 0;
}
