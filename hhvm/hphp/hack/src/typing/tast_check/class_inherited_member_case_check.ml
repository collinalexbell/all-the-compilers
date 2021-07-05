(*
 * Copyright (c) 2018, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the "hack" directory of this source tree.
 *
 *)

open Aast
open Base
open Typing_defs
module Env = Tast_env
module Cls = Decl_provider.Class

let error_inherited_base member_type base_name parent_name base_elt parent_elt :
    unit =
  Errors.inherited_class_member_with_different_case
    member_type
    base_name
    parent_name
    (Lazy.force base_elt.ce_pos |> Pos_or_decl.unsafe_to_raw_pos)
    base_elt.ce_origin
    parent_elt.ce_origin
    (Lazy.force parent_elt.ce_pos)

let check_inheritance_case
    (member_type : string)
    (class_id : Aast.sid)
    ((name, elt) : string * class_elt)
    (acc : (string * class_elt) SMap.t) : (string * class_elt) SMap.t =
  let (p, cls_name) = class_id in
  let canonical_name = String.lowercase name in
  (match SMap.find_opt canonical_name acc with
  | Some (prev_name, prev_elt) when not (String.equal name prev_name) ->
    (match (elt.ce_origin, prev_elt.ce_origin) with
    (* If they are from the same class, there's already a parsing error *)
    | (a, b) when String.equal a b -> ()
    (* new is the current class *)
    | (base_cls, _) when String.equal cls_name base_cls ->
      error_inherited_base member_type name prev_name elt prev_elt
    (* prev is the current class *)
    | (_, base_cls) when String.equal cls_name base_cls ->
      error_inherited_base member_type prev_name name prev_elt elt
    (* Otherwise, this class inherited two methods that differ only by case *)
    | (class1, class2) ->
      Errors.multiple_inherited_class_member_with_different_case
        ~member_type
        ~name1:name
        ~name2:prev_name
        ~class1
        ~class2
        ~child_class:cls_name
        ~child_p:p
        ~p1:(Lazy.force elt.ce_pos)
        ~p2:(Lazy.force prev_elt.ce_pos))
  | _ -> ());
  SMap.add canonical_name (name, elt) acc

let check_inheritance_cases
    (member_type : string)
    (name : Aast.sid)
    (class_elts : (string * class_elt) list) =
  (* We keep a map of canonical names for each class element
     and iterate through the list. If we ever see two members with
     the same canonical name, we raise an error. *)
  let (_ : (string * class_elt) SMap.t) =
    List.fold_right
      ~f:(check_inheritance_case member_type name)
      ~init:SMap.empty
      class_elts
  in
  ()

let handler =
  object
    inherit Tast_visitor.handler_base

    method! at_class_ env c =
      if
        TypecheckerOptions.experimental_feature_enabled
          (Tast_env.get_tcopt env)
          TypecheckerOptions.experimental_case_sensitive_inheritance
      then
        (* Check if any methods, including inherited ones, interfere via canonical name *)
        let (_, cls_name) = c.c_name in
        let result = Env.get_class env cls_name in
        match result with
        | None -> ()
        | Some cls ->
          let methods = Cls.methods cls in
          let smethods = Cls.smethods cls in
          let all_methods = methods @ smethods in
          (* All methods are treated the same when it comes to inheritance *)
          (* Member type may be useful for properties, constants, etc later *)
          check_inheritance_cases "method" c.c_name all_methods
      else
        ()
  end
