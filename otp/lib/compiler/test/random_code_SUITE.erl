%%
%% %CopyrightBegin%
%%
%% Copyright Ericsson AB 2020. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%% %CopyrightEnd%
%%

-module(random_code_SUITE).

-export([all/0, suite/0, groups/0,
         init_per_suite/1, end_per_suite/1]).

-export([compile/1]).

suite() ->
    [{ct_hooks,[ts_install_cth]}].

all() ->
    [{group,property_tests}].

groups() ->
    [{property_tests,[parallel],
      [compile]}].

init_per_suite(Config0) ->
    case ct_property_test:init_per_suite(Config0) of
        [_|_]=Config ->
            try proper_erlang_abstract_code:module() of
                _ ->
                    Config
            catch
                error:undef ->
                    {skip,"No proper_erlang_abstract_code module"}
            end;
        Other ->
            Other
    end.

end_per_suite(Config) ->
    Config.

compile(Config) ->
    true = ct_property_test:quickcheck(compile_prop:compile(), Config),
    ok.
