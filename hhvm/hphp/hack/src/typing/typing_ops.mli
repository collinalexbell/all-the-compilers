(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the "hack" directory of this source tree.
 *
 *)

(** Add constraint or check that ty_sub is subtype of ty_super in envs *)
val sub_type_i :
  ?is_coeffect:bool ->
  Pos.t ->
  Typing_reason.ureason ->
  Typing_env_types.env ->
  Typing_defs.internal_type ->
  Typing_defs.internal_type ->
  Errors.typing_error_callback ->
  Typing_env_types.env

val sub_type_i_res :
  Pos.t ->
  Typing_reason.ureason ->
  Typing_env_types.env ->
  Typing_defs.internal_type ->
  Typing_defs.internal_type ->
  Errors.typing_error_callback ->
  (Typing_env_types.env, Typing_env_types.env) result

val sub_type :
  Pos.t ->
  Typing_reason.ureason ->
  Typing_env_types.env ->
  Typing_defs.locl_ty ->
  Typing_defs.locl_ty ->
  Errors.typing_error_callback ->
  Typing_env_types.env

val sub_type_res :
  Pos.t ->
  Typing_reason.ureason ->
  Typing_env_types.env ->
  Typing_defs.locl_ty ->
  Typing_defs.locl_ty ->
  Errors.typing_error_callback ->
  (Typing_env_types.env, Typing_env_types.env) result

val sub_type_decl :
  ?is_coeffect:bool ->
  on_error:Errors.error_from_reasons_callback ->
  Pos_or_decl.t ->
  Typing_reason.ureason ->
  Typing_env_types.env ->
  Typing_defs.decl_ty ->
  Typing_defs.decl_ty ->
  Typing_env_types.env

val unify_decl :
  Pos_or_decl.t ->
  Typing_reason.ureason ->
  Typing_env_types.env ->
  Errors.error_from_reasons_callback ->
  Typing_defs.decl_ty ->
  Typing_defs.decl_ty ->
  Typing_env_types.env
