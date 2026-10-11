(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)
open! IStd

let with_input bytes f =
  let filename = Stdlib.Filename.temp_file "biniou_input" ".bin" in
  Exn.protect
    ~finally:(fun () -> Stdlib.Sys.remove filename)
    ~f:(fun () ->
      Out_channel.write_all filename ~data:bytes ;
      In_channel.with_file filename ~binary:true ~f )


let read_bytes input length =
  let position = Bi_inbuf.read input length in
  Stdlib.Bytes.sub_string input.Bi_inbuf.i_s position length


let buffer_growth _ =
  let large = String.make 70001 'x' in
  let larger = String.make 131080 'y' in
  with_input
    ("abc" ^ large ^ "tail" ^ larger ^ "z")
    (fun channel ->
      let input = Capture.biniou_input ~len:8 channel in
      OUnit2.assert_equal 7 (Bi_inbuf.try_preread input 7) ;
      List.iter ["abc"; large; "tail"; larger; "z"] ~f:(fun expected ->
          OUnit2.assert_equal ~cmp:String.equal expected (read_bytes input (String.length expected)) ) ;
      OUnit2.assert_equal (3 + 70001 + 4 + 131080 + 1) (input.i_offs + input.i_pos) ;
      OUnit2.assert_raises Bi_inbuf.End_of_input (fun () -> ignore (Bi_inbuf.read input 1)) )


let truncated_large_token _ =
  with_input "short input" (fun channel ->
      let input = Capture.biniou_input ~len:8 channel in
      OUnit2.assert_raises Bi_inbuf.End_of_input (fun () -> ignore (Bi_inbuf.read input 70001)) )


let tests =
  let open OUnit2 in
  [ QualifiedCppNameTests.tests
  ; "biniou_input"
    >::: [ "growth_preserves_bytes" >:: buffer_growth
         ; "truncated_large_token" >:: truncated_large_token ] ]
