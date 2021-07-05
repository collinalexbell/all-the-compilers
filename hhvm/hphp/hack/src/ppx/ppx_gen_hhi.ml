(*
 * Copyright (c) 2013-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the "flow" directory of this source tree.
 *
 *)

(* Ppxlib based PPX, used by both dune and BUCK.
 * This file is the dune entry point.
 *)
open Ppxlib

(**
 Read hhi and hsl files from the file system into memory, as AST nodes,
 to used by the ppx rewrite to replace [%hhi_contents] with this. *)
let get_hhi_contents hhi_dir hsl_dir =
  let open Ast_helper in
  Ppx_gen_hhi_common.get_hhis hhi_dir hsl_dir
  |> List.map (fun (name, contents) ->
         Exp.tuple
           [
             Exp.constant (Const.string name);
             Exp.constant (Const.string contents);
           ])
  |> Exp.array

let hhi_dir : string option ref = ref None

let hsl_dir : string option ref = ref None

let hhi_cache = ref None

(* Whenever we see [%hhi_contents], replace it with all of the hhis *)
let expand_function ~loc:_ ~path:_ =
  match !hhi_cache with
  | Some result -> result
  | None ->
    let hhi_dir =
      match !hhi_dir with
      | None -> raise (Arg.Bad "-hhi-dir is mandatory")
      | Some dir -> dir
    in
    let hsl_dir =
      match !hsl_dir with
      | None -> raise (Arg.Bad "-hsl-dir is mandatory")
      | Some dir -> dir
    in
    let result = get_hhi_contents hhi_dir hsl_dir in
    hhi_cache := Some result;
    result

let rule =
  Context_free.Rule.extension
    (Extension.declare
       "hhi_contents"
       Extension.Context.expression
       Ast_pattern.(pstr nil)
       expand_function)

let set_hhi_dir dir = hhi_dir := Some dir

let set_hsl_dir dir = hsl_dir := Some dir

let () =
  Driver.add_arg
    "-hhi-dir"
    (Arg.String set_hhi_dir)
    ~doc:"<dir> directory of the hhis sources";
  Driver.add_arg
    "-hsl-dir"
    (Arg.String set_hsl_dir)
    ~doc:"<dir> directory of the generated HHIs for the HSL";
  Driver.register_transformation ~rules:[rule] "ppx_gen_hhi"
