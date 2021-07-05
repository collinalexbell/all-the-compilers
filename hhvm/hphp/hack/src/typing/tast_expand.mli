(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the "hack" directory of this source tree.
 *
 *)

val expand_ty :
  ?var_hook:(Ident.t -> unit) ->
  ?pos:Pos.t ->
  Tast_env.env ->
  Typing_defs.locl_ty ->
  Typing_defs.locl_ty

val expand_program : Provider_context.t -> Tast.def list -> Tast.def list
