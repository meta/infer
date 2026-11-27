/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#ifdef RESTORE_CPP_KEYWORD
#undef static_assert
#endif

#ifdef __cplusplus
#ifdef static_assert
#error "Infer must preserve the C++ static_assert keyword"
#endif

#ifdef ASSERTION_SHOULD_FAIL
static_assert(false, "intentional assertion failure");
#else
static_assert(sizeof(int) > 0, "integer size");
#endif

#if __cplusplus >= 201703L
static_assert(sizeof(int) > 0);

static_assert([] {
#pragma pack(push, 1)
  struct PackedRecord {
    char first;
    int second;
  };
#pragma pack(pop)
  return sizeof(PackedRecord) == sizeof(char) + sizeof(int);
}(), "packed layout");

// This lambda is only evaluated at compile time. Its runtime-only branch
// must not introduce a null report when assertions are captured.
static_assert([] {
  if (__builtin_is_constant_evaluated()) {
    return true;
  }
  int* pointer = nullptr;
  return *pointer == 0;
}(), "compile-time evaluation");
#endif

int static_assert_runtime_null_bad() {
  int* pointer = nullptr;
  return *pointer;
}

#else
// Model the pre-existing C macro for the raw-compiler reference as well.
#ifndef __INFER__
#define static_assert(...)
#endif
#ifndef static_assert
#error "Infer must preserve its legacy C macro"
#endif
static_assert(0, "legacy C macro");
#ifdef ASSERTION_SHOULD_FAIL
_Static_assert(0, "intentional assertion failure");
#else
_Static_assert(sizeof(int) > 0, "integer size");
#endif
#endif

int static_assert_ordinary_declaration_control(int value) {
  int result = value + 1;
  return result;
}
