// Copyright (c) Facebook, Inc. and its affiliates.
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the "hack" directory of this source tree.

mod syntax_smart_constructors_generated;

use parser_core_types::syntax_by_ref::arena_state::State as ArenaState;
use smart_constructors::NoState;

pub use crate::syntax_smart_constructors_generated::*;

pub trait StateType<R>: Clone {
    fn next(&mut self, inputs: &[&R]);
}

impl<R> StateType<R> for NoState {
    fn next(&mut self, _inputs: &[&R]) {}
}

impl<R> StateType<R> for ArenaState<'_> {
    fn next(&mut self, _inputs: &[&R]) {}
}
