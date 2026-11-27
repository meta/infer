/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

static_assert(sizeof(int) > 0, "integer size");

static_assert([] {
#pragma pack(push, 1)
  struct PackedRecord {
    char first;
    int second;
  };
#pragma pack(pop)
  return sizeof(PackedRecord) == sizeof(char) + sizeof(int);
}(), "packed layout");

int static_assert_ordinary_declaration_control(int value) {
  int result = value + 1;
  return result;
}

int static_assert_function_control(int value) {
  static_assert(sizeof(int) > 0);
  return value + 1;
}

constexpr int static_assert_nearby_keyword_control(int value) noexcept {
  return value + 1;
}
