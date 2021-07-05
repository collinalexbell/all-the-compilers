(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the "hack" directory of this source tree.
 *
 *)

val find_policied_attribute :
  Nast.user_attribute list -> Typing_defs.ifc_fun_decl

val has_return_disposable_attribute : Nast.user_attribute list -> bool

val hint_to_type_opt :
  is_lambda:bool ->
  Decl_env.env ->
  Typing_reason.decl_t ->
  Nast.xhp_attr_hint option ->
  Typing_defs.decl_ty option

val make_param_ty :
  Decl_env.env ->
  is_lambda:bool ->
  Nast.fun_param ->
  Typing_defs.decl_ty Typing_defs_core.fun_param

(** Make function parameter for the partial-mode ellipsis parameter (unnamed, and untyped) *)
val make_ellipsis_param_ty :
  Decl_env.env -> Pos.t -> 'a Typing_defs.ty Typing_defs_core.fun_param

val ret_from_fun_kind :
  ?is_constructor:bool ->
  is_lambda:bool ->
  Decl_env.env ->
  Pos.t ->
  Ast_defs.fun_kind ->
  Nast.xhp_attr_hint option ->
  Typing_defs.decl_ty

val type_param :
  Decl_env.env -> Nast.tparam -> Typing_defs.decl_ty Typing_defs_core.tparam

val where_constraint :
  Decl_env.env ->
  Nast.xhp_attr_hint * 'a * Nast.xhp_attr_hint ->
  Typing_defs.decl_ty * 'a * Typing_defs.decl_ty

val check_params : Nast.fun_param list -> unit

val make_params :
  Decl_env.env ->
  is_lambda:bool ->
  Nast.fun_param list ->
  Typing_defs.decl_ty Typing_defs_core.fun_param list
