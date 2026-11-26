/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#ifdef ERASE_CPP_ASSERTIONS
#define static_assert(...)
#endif

int static_assert_declaration_control(int value) {
  int result = value + 1;
  return result;
}

int static_assert_statement_control(int value) {
  static_assert(sizeof(int) > 0, "integer size");
  return value + 1;
}

int static_assert_block_control(int value) {
  if (value) {
    static_assert(sizeof(int) > 0, "integer size");
  }
  return value;
}

int static_assert_loop_control(bool flag) {
  while (flag) {
    static_assert(sizeof(int) > 0, "integer size");
  }
  return 1;
}

constexpr int static_assert_nearby_keyword_control(int value) noexcept {
  return value + 1;
}
