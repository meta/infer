/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if defined(WARNING_ENABLED)
#pragma clang diagnostic warning "-Wuser-defined-warnings"
#elif defined(WARNING_AS_ERROR)
#pragma clang diagnostic error "-Wuser-defined-warnings"
#endif

#if defined(MATCHING_WARNING_ENABLED) || defined(MATCHING_WARNING_AS_ERROR)
#include <type_traits>
namespace std {
template <class Function, class First, class Second>
using __invokable = is_invocable<Function, First, Second>;
}
#define _LIBCPP_DIAGNOSE_WARNING(...) \
  __attribute__((diagnose_if(__VA_ARGS__, "warning")))
template <class _Tp, class _Compare>
_LIBCPP_DIAGNOSE_WARNING(!std::__invokable<_Compare const&, _Tp const&, _Tp const&>::value,
                       "the specified comparator type does not provide a const call operator")
int comparator_check();
struct Value {};
struct MutableCompare { bool operator()(const Value&, const Value&); };
#if defined(MATCHING_WARNING_AS_ERROR)
#pragma clang diagnostic error "-Wuser-defined-warnings"
#else
#pragma clang diagnostic warning "-Wuser-defined-warnings"
#endif
void matched_warning_control() { comparator_check<Value, MutableCompare>(); }
#elif defined(DIRECT_COMPARATORS)
#include <type_traits>
struct Value { bool compare(const Value&) const; };
struct ConstCompare { bool operator()(const Value&, const Value&) const; };
struct MutableCompare { bool operator()(const Value&, const Value&); };
struct VoidCompare { void operator()(const Value&, const Value&) const; };
struct RefCompare { bool operator()(const Value&, const Value&) const&; };
using FunctionCompare = bool (*)(const Value&, const Value&);
using MemberCompare = bool (Value::*)(const Value&) const;
template <class Function> constexpr bool matches_standard() {
  return __infer_capture::is_directly_invokable<
             const Function&, const Value&, const Value&>::value ==
         std::is_invocable<const Function&, const Value&, const Value&>::value;
}
static_assert(matches_standard<ConstCompare>(), "const comparator");
static_assert(matches_standard<MutableCompare>(), "mutable comparator");
static_assert(matches_standard<VoidCompare>(), "void return");
static_assert(matches_standard<RefCompare>(), "reference qualifier");
static_assert(matches_standard<FunctionCompare>(), "function pointer");
// Generic invocation accepts a member pointer, but ordered containers call
// their comparator directly. This unsupported comparator deliberately differs.
static_assert(std::is_invocable<const MemberCompare&, const Value&, const Value&>::value,
              "member pointer is invocable");
static_assert(!__infer_capture::is_directly_invokable<
                  const MemberCompare&, const Value&, const Value&>::value,
              "member pointer is not directly callable");
int direct_comparator_control() { return 0; }
#elif defined(ERROR_ATTRIBUTE) || defined(ERROR_IN_WARNING_MACRO)
#if defined(ERROR_ATTRIBUTE)
#define _LIBCPP_DIAGNOSE_ERROR(...) \
  __attribute__((diagnose_if(__VA_ARGS__, "error")))
#define GUARD _LIBCPP_DIAGNOSE_ERROR
#else
#define _LIBCPP_DIAGNOSE_WARNING(...) \
  __attribute__((diagnose_if(__VA_ARGS__, "error")))
#define GUARD _LIBCPP_DIAGNOSE_WARNING
#endif
void guard(int value) GUARD(value < 0, "diagnostic guard");
void error_control() { guard(-1); }
#elif defined(RUNTIME_MACRO)
int macro_runtime_deref(int* pointer) { return *pointer; }
#define _LIBCPP_DIAGNOSE_WARNING(...) macro_runtime_deref(__VA_ARGS__)
int runtime_macro_null_bad() {
  return _LIBCPP_DIAGNOSE_WARNING(static_cast<int*>(nullptr));
}
#else
#define _LIBCPP_DIAGNOSE_WARNING(...) \
  __attribute__((diagnose_if(__VA_ARGS__, "warning")))
#if defined(WARNING_ENABLED) || defined(WARNING_AS_ERROR) || defined(LATE_WARNING_AS_ERROR)
void guard(int value) _LIBCPP_DIAGNOSE_WARNING(value < 0, "diagnostic guard");
#if defined(LATE_WARNING_AS_ERROR)
#pragma clang diagnostic error "-Wuser-defined-warnings"
#endif
void warning_control() { guard(-1); }
#else
// Model a generic invocation check that eagerly inspects an incomplete pointee.
// The container diagnostic only needs the comparator's actual binary call.
namespace std {
template <class> struct diagnostic_key;
template <class Key> struct diagnostic_key<Key* const&> { using type = Key; };
template <class Function, class First, class Second> struct __invokable {
  static constexpr bool value = sizeof(typename diagnostic_key<First>::type) > 0;
};
}
template <class Type> struct Compare { bool operator()(const Type&, const Type&) const; };
template <class _Tp, class _Compare>
#if defined(NONMATCHING_CONDITION)
_LIBCPP_DIAGNOSE_WARNING(sizeof(_Tp) == 0, "incomplete diagnostic key")
#else
_LIBCPP_DIAGNOSE_WARNING(!std::__invokable<_Compare const&, _Tp const&, _Tp const&>::value,
                       "the specified comparator type does not provide a const call operator")
#endif
int comparator_check();
template <class Type> struct Container {
  static_assert(sizeof(comparator_check<Type, Compare<Type>>()), "comparator result");
};
struct Key {
#if defined(NONMATCHING_CONDITION)
  Container<Key> values;
#else
  Container<Key*> values;
#endif
  explicit operator bool() const { return true; }
};
bool warning_contextual_bool(Key& key) { return key && true; }
#if defined(ASSERT_FALSE)
static_assert(false, "language assertion must fail");
#endif
#endif
#endif
