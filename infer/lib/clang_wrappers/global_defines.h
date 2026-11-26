/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

// macro to help distinguish between infer compilation and normal one
#define __INFER__ 1

// set _FORTIFY_SOURCE to 0 to prevent it from changing some function prototypes
// https://securityblog.redhat.com/2014/03/26/fortify-and-you/
// We always do it when building models so we should do same thing
// when building any source code
#define _FORTIFY_SOURCE 0

// Keep the legacy C macro, but let C++ use its keyword. A function-like
// macro rejects preprocessor directives inside the assertion's operand.
#ifndef __cplusplus
#define static_assert(...)
#else
#ifndef __INFER_CAPTURE_DIRECT_INVOKE_TRAIT
#define __INFER_CAPTURE_DIRECT_INVOKE_TRAIT
// Check the call performed by an ordered container without instantiating
// generic invocation candidates on a key whose class may still be incomplete.
namespace __infer_capture {
template <class T> T&& declval();
template <class...> using void_t = void;
template <class Function, class First, class Second, class = void>
struct is_directly_invokable {
  enum { value = false };
};
template <class Function, class First, class Second>
struct is_directly_invokable<
    Function, First, Second,
    void_t<decltype(declval<Function>()(declval<First>(), declval<Second>()))>> {
  enum { value = true };
};
}
#endif
#endif
