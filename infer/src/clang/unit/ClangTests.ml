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


let with_argfile args f =
  let filename = Stdlib.Filename.temp_file "clang_arguments" ".rsp" in
  Exn.protect
    ~finally:(fun () -> Stdlib.Sys.remove filename)
    ~f:(fun () ->
      Out_channel.write_all filename ~data:(String.concat ~sep:"\n" args ^ "\n") ;
      f ("@" ^ filename) )


let assert_filtered expected args =
  let actual =
    ClangCommand.mk ~is_driver:false ClangQuotes.SingleQuotes ~prog:"clang" ~args
    |> ClangCommand.get_orig_argv
  in
  OUnit2.assert_equal ~cmp:(List.equal String.equal) ~printer:(String.concat ~sep:" ")
    ("clang" :: expected) actual


let kept_flags = ["-Ikept"; "-DKEEP=1"; "-std=c++17"]

let direct_pair _ = assert_filtered kept_flags (["-mllvm"; "-inline-threshold=7"] @ kept_flags)

let contained_pair _ =
  with_argfile
    (["-mllvm"; "-inline-threshold=7"] @ kept_flags)
    (fun file -> assert_filtered kept_flags [file])


let response_flag_direct_value _ =
  with_argfile ["-mllvm"] (fun file ->
      assert_filtered kept_flags ([file; "-inline-threshold=7"] @ kept_flags) )


let direct_flag_response_value _ =
  with_argfile ("-inline-threshold=7" :: kept_flags) (fun file ->
      assert_filtered kept_flags ["-mllvm"; file] )


let response_flag_response_value _ =
  with_argfile ["-mllvm"] (fun first ->
      with_argfile ("-inline-threshold=7" :: kept_flags) (fun second ->
          assert_filtered kept_flags [first; second] ) )


let forwarded_response_value _ =
  with_argfile ["-Xclang"; "-mllvm"] (fun first ->
      with_argfile
        (["-Xclang"; "-inline-threshold=7"] @ kept_flags)
        (fun second -> assert_filtered kept_flags [first; second]) )


let nested_response_value _ =
  with_argfile ["-inline-threshold=7"; "-Ikept"] (fun inner ->
      with_argfile (inner :: List.tl_exn kept_flags) (fun outer ->
          assert_filtered kept_flags ["-mllvm"; outer] ) )


let repeated_response_value _ =
  with_argfile ("-inline-threshold=7" :: kept_flags) (fun file ->
      assert_filtered
        (kept_flags @ ["-DKEEP=0"] @ kept_flags)
        ["-mllvm"; file; "-DKEEP=0"; "-mllvm"; file] )


let blank_lines_before_value _ =
  with_argfile
    ([""; "  "; "-inline-threshold=7"] @ kept_flags)
    (fun file -> assert_filtered kept_flags ["-mllvm"; file])


let quoted_empty_value _ =
  with_argfile ("\"\"" :: kept_flags) (fun file ->
      assert_filtered kept_flags ["-index-store-path"; file] )


let unchanged_response _ =
  with_argfile kept_flags (fun file -> assert_filtered [file; file] [file; file])


let recursive_response_terminates _ =
  with_argfile [] (fun file ->
      let filename = String.chop_prefix_exn file ~prefix:"@" in
      Out_channel.write_all filename ~data:(file ^ "\n-Ikept\n") ;
      assert_filtered [file] [file] )


let tests =
  let open OUnit2 in
  [ QualifiedCppNameTests.tests
  ; "biniou_input"
    >::: [ "growth_preserves_bytes" >:: buffer_growth
         ; "truncated_large_token" >:: truncated_large_token ]
  ; "clang_command_args"
    >::: [ "direct_pair" >:: direct_pair
         ; "contained_pair" >:: contained_pair
         ; "response_flag_direct_value" >:: response_flag_direct_value
         ; "direct_flag_response_value" >:: direct_flag_response_value
         ; "response_flag_response_value" >:: response_flag_response_value
         ; "forwarded_response_value" >:: forwarded_response_value
         ; "nested_response_value" >:: nested_response_value
         ; "repeated_response_value" >:: repeated_response_value
         ; "blank_lines_before_value" >:: blank_lines_before_value
         ; "quoted_empty_value" >:: quoted_empty_value
         ; "unchanged_response" >:: unchanged_response
         ; "recursive_response_terminates" >:: recursive_response_terminates ] ]
