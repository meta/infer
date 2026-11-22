(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd
open RustMir2TextualTest

let%expect_test "basic_tuple" =
  let source =
    {|
fn main() {
    let mut x = (1, 2);
    let one = x.0;
    let two = x.1;
    x.0 = two;
    x.1 = one;
}
    |}
  in
  test source ;
  [%expect
    {|
    .source_language = "Rust"

    define dummy::main() : void {
      local var_0: void, x_1: __infer_rust_tuple_class<int,int>, one_2: int, two_3: int, var_4: int, var_5: int
      #node_0:
          store &var_0 <- null:void
          store &x_1.__infer_rust_tuple_class<int,int>.0 <- 1:int
          store &x_1.__infer_rust_tuple_class<int,int>.1 <- 2:int
          n0:int = load &x_1.__infer_rust_tuple_class<int,int>.0
          store &one_2 <- n0:int
          n1:int = load &x_1.__infer_rust_tuple_class<int,int>.1
          store &two_3 <- n1:int
          n2:int = load &two_3
          store &var_4 <- n2:int
          n3:int = load &var_4
          store &x_1.__infer_rust_tuple_class<int,int>.0 <- n3:int
          n4:int = load &one_2
          store &var_5 <- n4:int
          n5:int = load &var_5
          store &x_1.__infer_rust_tuple_class<int,int>.1 <- n5:int
          store &var_0 <- null:void
          n6:void = load &var_0
          ret n6

    }

    type __infer_rust_tuple_class<int,int> = {0: int; 1: int}
    |}]


let%expect_test "basic_struct" =
  let source =
    {|
fn main() {
    struct Point {
        x: i32,
        y: i32,
    }

    let mut p = Point { x: 1, y: 2 };
    let one = p.x;
    let two = p.y;
    p.x = two;
    p.y = one;
}
|}
  in
  test source ;
  [%expect
    {|
    .source_language = "Rust"

    type dummy::main::Point = {x: int; y: int}

    define dummy::main() : void {
      local var_0: void, p_1: dummy::main::Point, one_2: int, two_3: int, var_4: int, var_5: int
      #node_0:
          store &var_0 <- null:void
          store &p_1.dummy::main::Point.x <- 1:int
          store &p_1.dummy::main::Point.y <- 2:int
          n0:int = load &p_1.dummy::main::Point.x
          store &one_2 <- n0:int
          n1:int = load &p_1.dummy::main::Point.y
          store &two_3 <- n1:int
          n2:int = load &two_3
          store &var_4 <- n2:int
          n3:int = load &var_4
          store &p_1.dummy::main::Point.x <- n3:int
          n4:int = load &one_2
          store &var_5 <- n4:int
          n5:int = load &var_5
          store &p_1.dummy::main::Point.y <- n5:int
          store &var_0 <- null:void
          n6:void = load &var_0
          ret n6

    }
    |}]


let%expect_test "basic_array" =
  let source =
    {|
fn main() {
    let mut x = [4, 5, 6];
    let four = x[0];
    let five = x[1];
    x[0] = five;
    x[1] = four;
}
|}
  in
  test source ;
  [%expect
    {|
    .source_language = "Rust"

    define dummy::main() : void {
      local var_0: void, x_1: int[], four_2: int, var_3: int, five_4: int, var_5: int, var_6: int, var_7: int, var_8: int, var_9: int
      #node_0:
          store &var_0 <- null:void
          store &x_1[0] <- 4:int
          store &x_1[1] <- 5:int
          store &x_1[2] <- 6:int
          store &var_3 <- 0:int
          n0:int = load &var_3
          n1:int = load &x_1[n0]
          store &four_2 <- n1:int
          store &var_5 <- 1:int
          n2:int = load &var_5
          n3:int = load &x_1[n2]
          store &five_4 <- n3:int
          n4:int = load &five_4
          store &var_6 <- n4:int
          store &var_7 <- 0:int
          n5:int = load &var_7
          n6:int = load &var_6
          store &x_1[n5] <- n6:int
          n7:int = load &four_2
          store &var_8 <- n7:int
          store &var_9 <- 1:int
          n8:int = load &var_9
          n9:int = load &var_8
          store &x_1[n8] <- n9:int
          store &var_0 <- null:void
          n10:void = load &var_0
          ret n10

    }
    |}]


let%expect_test "slice_index" =
  let source =
    {|
struct Point { x: i32, y: i32 }

fn get(v: &[i32], i: usize) -> i32 { v[3] + v[i] }
fn set(v: &mut [i32], i: usize, x: i32) { v[i] = x; }
fn len(v: &[i32]) -> usize { v.len() }
fn first_elem<T: Copy>(v: &[T]) -> T { v[0] }
fn sum_x(pts: &[Point], i: usize) -> i32 { pts[i].x + pts[0].y }
fn nested(m: &[&[i32]], i: usize, j: usize) -> i32 { m[i][j] }

fn main() {
    let mut a = [1, 2, 3, 4];
    set(&mut a, 0, 5);
    let _ = get(&a, 1);
    let _ = len(&a);
    let _ = first_elem(&a);
    let pts = [Point { x: 1, y: 2 }];
    let _ = sum_x(&pts, 0);
    let row: &[i32] = &a;
    let m = [row];
    let _ = nested(&m, 0, 1);
}
|}
  in
  test source ;
  [%expect
    {|
    .source_language = "Rust"

    type dummy::Point = {x: int; y: int}

    define dummy::get(v_1: .rust_mut = "const" .rust_pointer = "reference" *int[], i_2: int) : int {
      local var_0: int, var_3: int, var_4: int, var_5: int, var_6: int, var_7: int
      #node_0:
          store &var_4 <- 3:int
          n0:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &v_1
          n1:int = load &var_4
          n2:int = load n0[n1]
          store &var_3 <- n2:int
          n3:int = load &i_2
          store &var_6 <- n3:int
          n4:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &v_1
          n5:int = load &var_6
          n6:int = load n4[n5]
          store &var_5 <- n6:int
          n7:int = load &var_3
          n8:int = load &var_5
          store &var_7 <- __sil_plusa_int(n7, n8):int
          n9:int = load &var_7
          store &var_0 <- n9:int
          n10:int = load &var_0
          ret n10

    }

    define dummy::set(v_1: .rust_mut = "mut" .rust_pointer = "reference" *int[], i_2: int, x_3: int) : void {
      local var_0: void, var_4: int, var_5: int
      #node_0:
          store &var_0 <- null:void
          n0:int = load &x_3
          store &var_4 <- n0:int
          n1:int = load &i_2
          store &var_5 <- n1:int
          n2:.rust_mut = "mut" .rust_pointer = "reference" *int[] = load &v_1
          n3:int = load &var_5
          n4:int = load &var_4
          store n2[n3] <- n4:int
          store &var_0 <- null:void
          n5:void = load &var_0
          ret n5

    }

    define dummy::len(v_1: .rust_mut = "const" .rust_pointer = "reference" *int[]) : int {
      local var_0: int, var_2: .rust_mut = "const" .rust_pointer = "reference" *int[]
      #node_0:
          n0:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &v_1
          store &var_2 <- n0:.rust_mut = "const" .rust_pointer = "reference" *int[]
          n1:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &v_1
          n2 = __rust_retag(&var_2, n1, 0)
          n3:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &var_2
          n4 = core::slice::{[T]}::len(n3)
          store &var_0 <- n4:int
          jmp node_2
          .handlers node_1

      #node_1:
          throw "UnwindResume"

      #node_2:
          n5:int = load &var_0
          ret n5

    }

    define dummy::first_elem(v_1: .rust_mut = "const" .rust_pointer = "reference" *void[]) : void {
      local var_0: void, var_2: int
      #node_0:
          store &var_2 <- 0:int
          n0:.rust_mut = "const" .rust_pointer = "reference" *void[] = load &v_1
          n1:int = load &var_2
          n2:void = load n0[n1]
          store &var_0 <- n2:void
          n3:void = load &var_0
          ret n3

    }

    define dummy::sum_x(pts_1: .rust_mut = "const" .rust_pointer = "reference" *dummy::Point[], i_2: int) : int {
      local var_0: int, var_3: int, var_4: int, var_5: int, var_6: int, var_7: int
      #node_0:
          n0:int = load &i_2
          store &var_4 <- n0:int
          n1:.rust_mut = "const" .rust_pointer = "reference" *dummy::Point[] = load &pts_1
          n2:int = load &var_4
          n3:int = load n1[n2].dummy::Point.x
          store &var_3 <- n3:int
          store &var_6 <- 0:int
          n4:.rust_mut = "const" .rust_pointer = "reference" *dummy::Point[] = load &pts_1
          n5:int = load &var_6
          n6:int = load n4[n5].dummy::Point.y
          store &var_5 <- n6:int
          n7:int = load &var_3
          n8:int = load &var_5
          store &var_7 <- __sil_plusa_int(n7, n8):int
          n9:int = load &var_7
          store &var_0 <- n9:int
          n10:int = load &var_0
          ret n10

    }

    define dummy::nested(m_1: .rust_mut = "const" .rust_pointer = "reference" *(.rust_mut = "const" .rust_pointer = "reference" *int[])[], i_2: int, j_3: int) : int {
      local var_0: int, var_4: int, var_5: int, var_6: .rust_mut = "const" .rust_pointer = "reference" *int[], var_7: .rust_mut = "const" .rust_pointer = "reference" *int[]
      #node_0:
          n0:int = load &i_2
          store &var_4 <- n0:int
          n1:int = load &j_3
          store &var_5 <- n1:int
          n2:.rust_mut = "const" .rust_pointer = "reference" *(.rust_mut = "const" .rust_pointer = "reference" *int[])[] = load &m_1
          n3:int = load &var_4
          n4:.rust_mut = "const" .rust_pointer = "reference" *int[] = load n2[n3]
          store &var_6 <- n4:.rust_mut = "const" .rust_pointer = "reference" *int[]
          n5:.rust_mut = "const" .rust_pointer = "reference" *(.rust_mut = "const" .rust_pointer = "reference" *int[])[] = load &m_1
          n6:int = load &var_4
          n7:.rust_mut = "const" .rust_pointer = "reference" *int[] = load n5[n6]
          store &var_7 <- n7:.rust_mut = "const" .rust_pointer = "reference" *int[]
          n8:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &var_7
          n9:int = load &var_5
          n10:int = load n8[n9]
          store &var_0 <- n10:int
          n11:int = load &var_0
          ret n11

    }

    define dummy::main() : void {
      local var_0: void, a_1: int[], var_2: void, var_3: .rust_mut = "mut" .rust_pointer = "reference" *int[], var_4: .rust_mut = "mut" .rust_pointer = "reference" *int[], var_5: .rust_mut = "mut" .rust_pointer = "reference" *int[], var_6: int, var_7: .rust_mut = "const" .rust_pointer = "reference" *int[], var_8: .rust_mut = "const" .rust_pointer = "reference" *int[], var_9: .rust_mut = "const" .rust_pointer = "reference" *int[], var_10: int, var_11: .rust_mut = "const" .rust_pointer = "reference" *int[], var_12: .rust_mut = "const" .rust_pointer = "reference" *int[], var_13: .rust_mut = "const" .rust_pointer = "reference" *int[], var_14: int, var_15: .rust_mut = "const" .rust_pointer = "reference" *int[], var_16: .rust_mut = "const" .rust_pointer = "reference" *int[], var_17: .rust_mut = "const" .rust_pointer = "reference" *int[], pts_18: dummy::Point[], var_19: dummy::Point, var_20: int, var_21: .rust_mut = "const" .rust_pointer = "reference" *dummy::Point[], var_22: .rust_mut = "const" .rust_pointer = "reference" *dummy::Point[], var_23: .rust_mut = "const" .rust_pointer = "reference" *dummy::Point[], row_24: .rust_mut = "const" .rust_pointer = "reference" *int[], var_25: .rust_mut = "const" .rust_pointer = "reference" *int[], var_26: .rust_mut = "const" .rust_pointer = "reference" *int[], m_27: (.rust_mut = "const" .rust_pointer = "reference" *int[])[], var_28: .rust_mut = "const" .rust_pointer = "reference" *int[], var_29: int, var_30: .rust_mut = "const" .rust_pointer = "reference" *(.rust_mut = "const" .rust_pointer = "reference" *int[])[], var_31: .rust_mut = "const" .rust_pointer = "reference" *(.rust_mut = "const" .rust_pointer = "reference" *int[])[], var_32: .rust_mut = "const" .rust_pointer = "reference" *(.rust_mut = "const" .rust_pointer = "reference" *int[])[]
      #node_0:
          store &var_0 <- null:void
          store &a_1[0] <- 1:int
          store &a_1[1] <- 2:int
          store &a_1[2] <- 3:int
          store &a_1[3] <- 4:int
          store &var_5 <- &a_1:.rust_mut = "mut" .rust_pointer = "reference" *int[]
          n0 = __rust_retag(&var_5, &a_1, 1)
          n1:.rust_mut = "mut" .rust_pointer = "reference" *int[] = load &var_5
          store &var_4 <- n1:.rust_mut = "mut" .rust_pointer = "reference" *int[]
          n2:.rust_mut = "mut" .rust_pointer = "reference" *int[] = load &var_5
          n3 = __rust_retag(&var_4, n2, 1)
          n4:.rust_mut = "mut" .rust_pointer = "reference" *int[] = load &var_4
          store &var_3 <- __sil_cast(<.rust_mut = "mut" .rust_pointer = "reference" *int[]>, n4):.rust_mut = "mut" .rust_pointer = "reference" *int[]
          n5:.rust_mut = "mut" .rust_pointer = "reference" *int[] = load &var_3
          n6 = dummy::set(n5, 0, 5)
          store &var_2 <- n6:void
          jmp node_2
          .handlers node_1

      #node_1:
          throw "UnwindResume"

      #node_2:
          store &var_9 <- &a_1:.rust_mut = "const" .rust_pointer = "reference" *int[]
          n7 = __rust_retag(&var_9, &a_1, 0)
          n8:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &var_9
          store &var_8 <- n8:.rust_mut = "const" .rust_pointer = "reference" *int[]
          n9:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &var_9
          n10 = __rust_retag(&var_8, n9, 0)
          n11:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &var_8
          store &var_7 <- __sil_cast(<.rust_mut = "const" .rust_pointer = "reference" *int[]>, n11):.rust_mut = "const" .rust_pointer = "reference" *int[]
          n12:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &var_7
          n13 = dummy::get(n12, 1)
          store &var_6 <- n13:int
          jmp node_4
          .handlers node_3

      #node_3:
          throw "UnwindResume"

      #node_4:
          store &var_13 <- &a_1:.rust_mut = "const" .rust_pointer = "reference" *int[]
          n14 = __rust_retag(&var_13, &a_1, 0)
          n15:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &var_13
          store &var_12 <- n15:.rust_mut = "const" .rust_pointer = "reference" *int[]
          n16:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &var_13
          n17 = __rust_retag(&var_12, n16, 0)
          n18:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &var_12
          store &var_11 <- __sil_cast(<.rust_mut = "const" .rust_pointer = "reference" *int[]>, n18):.rust_mut = "const" .rust_pointer = "reference" *int[]
          n19:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &var_11
          n20 = dummy::len(n19)
          store &var_10 <- n20:int
          jmp node_6
          .handlers node_5

      #node_5:
          throw "UnwindResume"

      #node_6:
          store &var_17 <- &a_1:.rust_mut = "const" .rust_pointer = "reference" *int[]
          n21 = __rust_retag(&var_17, &a_1, 0)
          n22:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &var_17
          store &var_16 <- n22:.rust_mut = "const" .rust_pointer = "reference" *int[]
          n23:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &var_17
          n24 = __rust_retag(&var_16, n23, 0)
          n25:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &var_16
          store &var_15 <- __sil_cast(<.rust_mut = "const" .rust_pointer = "reference" *int[]>, n25):.rust_mut = "const" .rust_pointer = "reference" *int[]
          n26:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &var_15
          n27 = dummy::first_elem(n26)
          store &var_14 <- n27:int
          jmp node_8
          .handlers node_7

      #node_7:
          throw "UnwindResume"

      #node_8:
          store &var_19.dummy::Point.x <- 1:int
          store &var_19.dummy::Point.y <- 2:int
          n28:dummy::Point = load &var_19
          store &pts_18[0] <- n28:dummy::Point
          store &var_23 <- &pts_18:.rust_mut = "const" .rust_pointer = "reference" *dummy::Point[]
          n29 = __rust_retag(&var_23, &pts_18, 0)
          n30:.rust_mut = "const" .rust_pointer = "reference" *dummy::Point[] = load &var_23
          store &var_22 <- n30:.rust_mut = "const" .rust_pointer = "reference" *dummy::Point[]
          n31:.rust_mut = "const" .rust_pointer = "reference" *dummy::Point[] = load &var_23
          n32 = __rust_retag(&var_22, n31, 0)
          n33:.rust_mut = "const" .rust_pointer = "reference" *dummy::Point[] = load &var_22
          store &var_21 <- __sil_cast(<.rust_mut = "const" .rust_pointer = "reference" *dummy::Point[]>, n33):.rust_mut = "const" .rust_pointer = "reference" *dummy::Point[]
          n34:.rust_mut = "const" .rust_pointer = "reference" *dummy::Point[] = load &var_21
          n35 = dummy::sum_x(n34, 0)
          store &var_20 <- n35:int
          jmp node_10
          .handlers node_9

      #node_9:
          throw "UnwindResume"

      #node_10:
          store &var_26 <- &a_1:.rust_mut = "const" .rust_pointer = "reference" *int[]
          n36 = __rust_retag(&var_26, &a_1, 0)
          n37:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &var_26
          store &var_25 <- n37:.rust_mut = "const" .rust_pointer = "reference" *int[]
          n38:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &var_26
          n39 = __rust_retag(&var_25, n38, 0)
          n40:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &var_25
          store &row_24 <- __sil_cast(<.rust_mut = "const" .rust_pointer = "reference" *int[]>, n40):.rust_mut = "const" .rust_pointer = "reference" *int[]
          n41:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &row_24
          store &var_28 <- n41:.rust_mut = "const" .rust_pointer = "reference" *int[]
          n42:.rust_mut = "const" .rust_pointer = "reference" *int[] = load &var_28
          store &m_27[0] <- n42:.rust_mut = "const" .rust_pointer = "reference" *int[]
          store &var_32 <- &m_27:.rust_mut = "const" .rust_pointer = "reference" *(.rust_mut = "const" .rust_pointer = "reference" *int[])[]
          n43 = __rust_retag(&var_32, &m_27, 0)
          n44:.rust_mut = "const" .rust_pointer = "reference" *(.rust_mut = "const" .rust_pointer = "reference" *int[])[] = load &var_32
          store &var_31 <- n44:.rust_mut = "const" .rust_pointer = "reference" *(.rust_mut = "const" .rust_pointer = "reference" *int[])[]
          n45:.rust_mut = "const" .rust_pointer = "reference" *(.rust_mut = "const" .rust_pointer = "reference" *int[])[] = load &var_32
          n46 = __rust_retag(&var_31, n45, 0)
          n47:.rust_mut = "const" .rust_pointer = "reference" *(.rust_mut = "const" .rust_pointer = "reference" *int[])[] = load &var_31
          store &var_30 <- __sil_cast(<.rust_mut = "const" .rust_pointer = "reference" *(.rust_mut = "const" .rust_pointer = "reference" *int[])[]>, n47):.rust_mut = "const" .rust_pointer = "reference" *(.rust_mut = "const" .rust_pointer = "reference" *int[])[]
          n48:.rust_mut = "const" .rust_pointer = "reference" *(.rust_mut = "const" .rust_pointer = "reference" *int[])[] = load &var_30
          n49 = dummy::nested(n48, 0, 1)
          store &var_29 <- n49:int
          jmp node_12
          .handlers node_11

      #node_11:
          throw "UnwindResume"

      #node_12:
          store &var_0 <- null:void
          n50:void = load &var_0
          ret n50

    }

    declare core::slice::{[T]}::len(.rust_mut = "const" .rust_pointer = "reference" *void[]) : int

    declare core::marker::Destruct::drop_in_place(.rust_mut = "mut" .rust_pointer = "pointer" *void) : void

    declare core::clone::Clone::clone(.rust_mut = "const" .rust_pointer = "reference" *void) : void

    declare core::clone::impls::{core::clone::Clone for i32}::clone(.rust_mut = "const" .rust_pointer = "reference" *int) : int
    |}]


let%expect_test "distance" =
  let source =
    {|
fn main() {
    let p = Point { x: 1, y: 2 };
    let _ = distance(p);
}

fn distance(p: Point) -> i32 {
    p.x * p.x + p.y * p.y
}

struct Point {
    x: i32,
    y: i32,
}

|}
  in
  test source ;
  [%expect
    {|
    .source_language = "Rust"

    type dummy::Point = {x: int; y: int}

    define dummy::main() : void {
      local var_0: void, p_1: dummy::Point, var_2: int, var_3: dummy::Point
      #node_0:
          store &var_0 <- null:void
          store &p_1.dummy::Point.x <- 1:int
          store &p_1.dummy::Point.y <- 2:int
          n0:dummy::Point = load &p_1
          store &var_3 <- n0:dummy::Point
          n1:dummy::Point = load &var_3
          n2 = dummy::distance(n1)
          store &var_2 <- n2:int
          jmp node_2
          .handlers node_1

      #node_1:
          throw "UnwindResume"

      #node_2:
          store &var_0 <- null:void
          n3:void = load &var_0
          ret n3

    }

    define dummy::distance(p_1: dummy::Point) : int {
      local var_0: int, var_2: int, var_3: int, var_4: int, var_5: int, var_6: int, var_7: int, var_8: int, var_9: int, var_10: int
      #node_0:
          n0:int = load &p_1.dummy::Point.x
          store &var_3 <- n0:int
          n1:int = load &p_1.dummy::Point.x
          store &var_4 <- n1:int
          n2:int = load &var_3
          n3:int = load &var_4
          store &var_5 <- __sil_mult_int(n2, n3):int
          n4:int = load &var_5
          store &var_2 <- n4:int
          n5:int = load &p_1.dummy::Point.y
          store &var_7 <- n5:int
          n6:int = load &p_1.dummy::Point.y
          store &var_8 <- n6:int
          n7:int = load &var_7
          n8:int = load &var_8
          store &var_9 <- __sil_mult_int(n7, n8):int
          n9:int = load &var_9
          store &var_6 <- n9:int
          n10:int = load &var_2
          n11:int = load &var_6
          store &var_10 <- __sil_plusa_int(n10, n11):int
          n12:int = load &var_10
          store &var_0 <- n12:int
          n13:int = load &var_0
          ret n13

    }
    |}]


let%expect_test "empty_struct" =
  let source =
    {|
struct Adder;

impl Adder {
    fn add(&self, a : i32, b : i32) -> i32 {
        a + b
    }
}

fn main() {
    let adder = Adder; // no fields
    let three = adder.add(1,2);
}

|}
  in
  test source ;
  [%expect
    {|
    .source_language = "Rust"

    type dummy::Adder = {}

    define dummy::main() : void {
      local var_0: void, adder_1: dummy::Adder, three_2: int, var_3: .rust_mut = "const" .rust_pointer = "reference" *dummy::Adder
      #node_0:
          store &var_0 <- null:void
          store &var_3 <- &adder_1:.rust_mut = "const" .rust_pointer = "reference" *dummy::Adder
          n0 = __rust_retag(&var_3, &adder_1, 0)
          n1:.rust_mut = "const" .rust_pointer = "reference" *dummy::Adder = load &var_3
          n2 = dummy::{dummy::Adder}::add(n1, 1, 2)
          store &three_2 <- n2:int
          jmp node_2
          .handlers node_1

      #node_1:
          throw "UnwindResume"

      #node_2:
          store &var_0 <- null:void
          n3:void = load &var_0
          ret n3

    }

    define dummy::{dummy::Adder}::add(self_1: .rust_mut = "const" .rust_pointer = "reference" *dummy::Adder, a_2: int, b_3: int) : int {
      local var_0: int, var_4: int, var_5: int, var_6: int
      #node_0:
          n0:int = load &a_2
          store &var_4 <- n0:int
          n1:int = load &b_3
          store &var_5 <- n1:int
          n2:int = load &var_4
          n3:int = load &var_5
          store &var_6 <- __sil_plusa_int(n2, n3):int
          n4:int = load &var_6
          store &var_0 <- n4:int
          n5:int = load &var_0
          ret n5

    }
    |}]


let%expect_test "nested_type" =
  let source =
    {|
fn main() {
    let x = Foo { array: [1, 2], tuple: (3, 4) };
}

struct Foo {
    array: [i32; 2],
    tuple: (i32, i32),
}
|}
  in
  test source ;
  [%expect
    {|
    .source_language = "Rust"

    type dummy::Foo = {array: int[]; tuple: __infer_rust_tuple_class<int,int>}

    define dummy::main() : void {
      local var_0: void, x_1: dummy::Foo, var_2: int[], var_3: __infer_rust_tuple_class<int,int>
      #node_0:
          store &var_0 <- null:void
          store &var_2[0] <- 1:int
          store &var_2[1] <- 2:int
          store &var_3.__infer_rust_tuple_class<int,int>.0 <- 3:int
          store &var_3.__infer_rust_tuple_class<int,int>.1 <- 4:int
          n0:int[] = load &var_2
          store &x_1.dummy::Foo.array <- n0:int[]
          n1:__infer_rust_tuple_class<int,int> = load &var_3
          store &x_1.dummy::Foo.tuple <- n1:__infer_rust_tuple_class<int,int>
          store &var_0 <- null:void
          n2:void = load &var_0
          ret n2

    }

    type __infer_rust_tuple_class<int,int> = {0: int; 1: int}
    |}]


let%expect_test "multiple_tuples" =
  let source =
    {|
fn main() {
    let x = (1, 2);
    let y = (2, 3);
    let z = ([3],[4]);
    let aa = ((1,2,3),(4,5,6));
}
    |}
  in
  test source ;
  [%expect
    {|
    .source_language = "Rust"

    define dummy::main() : void {
      local var_0: void, x_1: __infer_rust_tuple_class<int,int>, y_2: __infer_rust_tuple_class<int,int>, z_3: __infer_rust_tuple_class<int[],int[]>, var_4: int[], var_5: int[], aa_6: __infer_rust_tuple_class<__infer_rust_tuple_class<int,int,int>,__infer_rust_tuple_class<int,int,int>>, var_7: __infer_rust_tuple_class<int,int,int>, var_8: __infer_rust_tuple_class<int,int,int>
      #node_0:
          store &var_0 <- null:void
          store &x_1.__infer_rust_tuple_class<int,int>.0 <- 1:int
          store &x_1.__infer_rust_tuple_class<int,int>.1 <- 2:int
          store &y_2.__infer_rust_tuple_class<int,int>.0 <- 2:int
          store &y_2.__infer_rust_tuple_class<int,int>.1 <- 3:int
          store &var_4[0] <- 3:int
          store &var_5[0] <- 4:int
          n0:int[] = load &var_4
          store &z_3.__infer_rust_tuple_class<int[],int[]>.0 <- n0:int[]
          n1:int[] = load &var_5
          store &z_3.__infer_rust_tuple_class<int[],int[]>.1 <- n1:int[]
          store &var_7.__infer_rust_tuple_class<int,int,int>.0 <- 1:int
          store &var_7.__infer_rust_tuple_class<int,int,int>.1 <- 2:int
          store &var_7.__infer_rust_tuple_class<int,int,int>.2 <- 3:int
          store &var_8.__infer_rust_tuple_class<int,int,int>.0 <- 4:int
          store &var_8.__infer_rust_tuple_class<int,int,int>.1 <- 5:int
          store &var_8.__infer_rust_tuple_class<int,int,int>.2 <- 6:int
          n2:__infer_rust_tuple_class<int,int,int> = load &var_7
          store &aa_6.__infer_rust_tuple_class<__infer_rust_tuple_class<int,int,int>,__infer_rust_tuple_class<int,int,int>>.0 <- n2:__infer_rust_tuple_class<int,int,int>
          n3:__infer_rust_tuple_class<int,int,int> = load &var_8
          store &aa_6.__infer_rust_tuple_class<__infer_rust_tuple_class<int,int,int>,__infer_rust_tuple_class<int,int,int>>.1 <- n3:__infer_rust_tuple_class<int,int,int>
          store &var_0 <- null:void
          n4:void = load &var_0
          ret n4

    }

    type __infer_rust_tuple_class<__infer_rust_tuple_class<int,int,int>,__infer_rust_tuple_class<int,int,int>> = {
    0: __infer_rust_tuple_class<int,int,int>; 1: __infer_rust_tuple_class<int,int,int>}

    type __infer_rust_tuple_class<int,int> = {0: int; 1: int}

    type __infer_rust_tuple_class<int,int,int> = {0: int; 1: int; 2: int}

    type __infer_rust_tuple_class<int[],int[]> = {0: int[]; 1: int[]}
    |}]
