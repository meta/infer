/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
package codetoanalyze.kotlin.pulse

class LateinitResource {
  fun use(): Boolean = true
}

class Lateinit {
  private lateinit var resource: LateinitResource
  private var optional: LateinitResource? = null

  // The compiler guards the read with a call that throws when the property is unset and pushes
  // a null afterwards, so that null is unreachable and this is not a null dereference.
  fun readLateinitOk(): Boolean = resource.use()

  fun readLateinitAfterAssigningOk(): Boolean {
    resource = LateinitResource()
    return resource.use()
  }

  fun safeCallOnNullableOk(): Boolean = optional?.use() ?: false

  fun notNullAssertionOnNullLocalBad(): Boolean {
    val r: LateinitResource? = null
    return r!!.use()
  }

  fun notNullAssertionOnNullFieldBad(): Boolean {
    optional = null
    return optional!!.use()
  }

  fun takesNotNull(r: LateinitResource): Boolean = r.use()

  fun passNullToNotNullParameterBad(): Boolean {
    val r: LateinitResource? = null
    return takesNotNull(r as LateinitResource)
  }
}
