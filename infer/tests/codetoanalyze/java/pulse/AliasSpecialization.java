/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

package codetoanalyze.java.infer;

// Calls whose callee summary only applies once the callee is specialized for aliasing in the
// caller. If no summary applies, nothing after the call is analyzed.
public class AliasSpecialization {

  static final class Node {
    Node next;
    int[] arr;

    Node() {
      this.next = this;
      this.arr = new int[8];
    }
  }

  static int sink = 0;

  static int readArrayAndFieldArray(Node p, int[] q, int k) {
    p = p.next;
    sink += q[k & 7];
    sink += p.arr[k & 7];
    return sink + k;
  }

  // one alias is needed at the call: [p == p.next]
  public static void separateArraysThenNullDerefBad() {
    Node n = new Node();
    int[] a = new int[8];
    sink += readArrayAndFieldArray(n, a, 5);
    StringBuilder b = null;
    sink += b.length();
  }

  // two aliases are needed at the call: [p == p.next] and [q == p.arr]
  public static void sharedArrayThenNullDerefBad() {
    Node n = new Node();
    int[] a = n.arr;
    sink += readArrayAndFieldArray(n, a, 5);
    StringBuilder b = null;
    sink += b.length();
  }

  static int writeTwoCells(int[] q, int k) {
    q[k & 7] = 1;
    q[0] = 2;
    return sink + k;
  }

  // the two cells written by the callee are distinct
  public static void distinctCellsThenNullDerefBad() {
    int[] a = new int[8];
    sink += writeTwoCells(a, 1);
    Object o = null;
    o.toString();
  }

  // the two cells written by the callee are the same cell, and alias specialization does not
  // support array accesses yet
  public static void FN_coincidingCellsThenNullDerefBad() {
    int[] a = new int[8];
    sink += writeTwoCells(a, 0);
    Object o = null;
    o.toString();
  }
}
