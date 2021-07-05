%%
%% %CopyrightBegin%
%%
%% Copyright Ericsson AB 2019-2020. All Rights Reserved.
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

%%
-module(dtls_api_SUITE).

%% Callback functions
-export([all/0,
         groups/0,
         init_per_suite/1,
         end_per_suite/1,
         init_per_group/2,
         end_per_group/2,
         init_per_testcase/2,
         end_per_testcase/2]).

%% Testcases
-export([dtls_listen_owner_dies/0,
         dtls_listen_owner_dies/1,
         dtls_listen_close/0,
         dtls_listen_close/1,
         dtls_listen_reopen/0,
         dtls_listen_reopen/1,
         dtls_listen_two_sockets_1/0,
         dtls_listen_two_sockets_1/1,
         dtls_listen_two_sockets_2/0,
         dtls_listen_two_sockets_2/1,
         dtls_listen_two_sockets_3/0,
         dtls_listen_two_sockets_3/1,
         dtls_listen_two_sockets_4/0,
         dtls_listen_two_sockets_4/1,
         dtls_listen_two_sockets_5/0,
         dtls_listen_two_sockets_5/1,
         dtls_listen_two_sockets_6/0,
         dtls_listen_two_sockets_6/1
        ]).

%%--------------------------------------------------------------------
%% Common Test interface functions -----------------------------------
%%--------------------------------------------------------------------
all() ->
    [
     {group, 'dtlsv1.2'},
     {group, 'dtlsv1'}
    ].

groups() ->
    [
     {'dtlsv1.2', [],  api_tests()},
     {'dtlsv1', [],  api_tests()}
    ].

api_tests() ->
    [
     dtls_listen_owner_dies,
     dtls_listen_close,
     dtls_listen_reopen,
     dtls_listen_two_sockets_1,
     dtls_listen_two_sockets_2,
     dtls_listen_two_sockets_3,
     dtls_listen_two_sockets_4,
     dtls_listen_two_sockets_5,
     dtls_listen_two_sockets_6
    ].

init_per_suite(Config0) ->
    catch crypto:stop(),
    try crypto:start() of
	ok ->
	    ssl_test_lib:clean_start(),
	    ssl_test_lib:make_rsa_cert(Config0)
    catch _:_ ->
	    {skip, "Crypto did not start"}
    end.

end_per_suite(_Config) ->
    ssl:stop(),
    application:unload(ssl),
    application:stop(crypto).


init_per_group(GroupName, Config) ->
    ssl_test_lib:init_per_group(GroupName, Config).

end_per_group(GroupName, Config) ->
    ssl_test_lib:end_per_group(GroupName, Config).

init_per_testcase(Testcase, Config)
  when Testcase =:= dtls_listen_two_sockets_1 orelse
       Testcase =:= dtls_listen_two_sockets_5 orelse
       Testcase =:= dtls_listen_two_sockets_6 ->
    case ssl:listen(0, [{protocol, dtls}, {ip, {127,0,0,2}}]) of
        {ok, S} ->
            test_listen_on_all_interfaces(S, Config),
            ssl:close(S),
            ssl_test_lib:ct_log_supported_protocol_versions(Config),
            ct:timetrap({seconds, 10}),
            maybe_skip_tc_on_windows(Testcase, Config);
        {error, _} ->
            {skip, "127.0.0.x address not available"}
    end;
init_per_testcase(_TestCase, Config) ->
    ssl_test_lib:ct_log_supported_protocol_versions(Config),
    ct:timetrap({seconds, 10}),
    Config.

end_per_testcase(_TestCase, Config) ->     
    Config.

%%--------------------------------------------------------------------
%% Test Cases --------------------------------------------------------
%%--------------------------------------------------------------------

dtls_listen_owner_dies() ->
    [{doc, "Test that you can start new DTLS 'listner' if old owner dies"}].

dtls_listen_owner_dies(Config) when is_list(Config) ->    
    ClientOpts = ssl_test_lib:ssl_options(client_rsa_opts, Config),
    ServerOpts = ssl_test_lib:ssl_options(server_rsa_opts, Config),
    {_, ServerNode, Hostname} = ssl_test_lib:run_where(Config),

    Port = ssl_test_lib:inet_port(ServerNode),
    Test = self(),
    Pid = spawn(fun() -> {ok, _} =
                             ssl:listen(Port, [{protocol, dtls} | ServerOpts]),
                         {error, _} = ssl:listen(Port, [{protocol, dtls} | ServerOpts]),
                         Test ! {self(), listened}
                end),
    receive
        {Pid, listened} ->
            ok
    end,
    {ok, LSocket} = ssl:listen(Port, [{protocol, dtls} | ServerOpts]),
    spawn(fun() -> 
                  {ok, ASocket} = ssl:transport_accept(LSocket),
                  {ok, Socket} = ssl:handshake(ASocket),
                   receive 
                       {ssl, Socket, "from client"} ->
                           ssl:send(Socket, "from server"),
                           ssl:close(Socket)
                   end
          end),
    {ok, Client} = ssl:connect(Hostname, Port, ClientOpts),

    ssl:send(Client, "from client"),
    receive 
        {ssl, Client, "from server"} ->
            ssl:close(Client)
    end.


dtls_listen_close() ->
    [{doc, "Test that you close a DTLS 'listner' socket"}].

dtls_listen_close(Config) when is_list(Config) ->    
    ServerOpts = ssl_test_lib:ssl_options(server_rsa_opts, Config),
    {_, ServerNode, _Hostname} = ssl_test_lib:run_where(Config),

    Port = ssl_test_lib:inet_port(ServerNode),
    {ok, ListenSocket} = ssl:listen(Port, [{protocol, dtls} | ServerOpts]),
    ok = ssl:close(ListenSocket).


dtls_listen_reopen() ->
    [{doc, "Test that you close a DTLS 'listner' socket and open a new one for the same port"}].

dtls_listen_reopen(Config) when is_list(Config) -> 
    ClientOpts = ssl_test_lib:ssl_options(client_rsa_opts, Config),
    ServerOpts = ssl_test_lib:ssl_options(server_rsa_opts, Config),
    {_, ServerNode, Hostname} = ssl_test_lib:run_where(Config),

    Port = ssl_test_lib:inet_port(ServerNode),
    {ok, LSocket0} = ssl:listen(Port, [{protocol, dtls} | ServerOpts]),
     spawn(fun() ->
                  {ok, ASocket} = ssl:transport_accept(LSocket0),
                   {ok, Socket} = ssl:handshake(ASocket),
                   receive
                       {ssl, Socket, "from client"} ->
                           ssl:send(Socket, "from server 1"),
                           ssl:close(Socket)
                   end
           end),
    {ok, Client1} = ssl:connect(Hostname, Port, ClientOpts),
    ok = ssl:close(LSocket0),
    {ok, LSocket1} = ssl:listen(Port, [{protocol, dtls} | ServerOpts]),
    spawn(fun() ->
                  {ok, ASocket} = ssl:transport_accept(LSocket1),
                  {ok, Socket} = ssl:handshake(ASocket),
                  receive
                      {ssl, Socket, "from client"} ->
                          ssl:send(Socket, "from server 2"),
                          ssl:close(Socket)
                   end
          end),
    {ok, Client2} = ssl:connect(Hostname, Port, [{protocol, dtls} | ClientOpts]),
    ssl:send(Client2, "from client"),
    ssl:send(Client1, "from client"),
    receive
        {ssl, Client1, "from server 1"} ->
            ssl:close(Client1)
    end,
    receive
        {ssl, Client2, "from server 2"} ->
            ssl:close(Client2)
    end.

dtls_listen_two_sockets_1() ->
    [{doc, "Test with two DTLS dockets: 127.0.0.2:Port, 127.0.0.3:Port"}].
dtls_listen_two_sockets_1(_Config) when is_list(_Config) ->
    {ok, S1} = ssl:listen(0, [{protocol, dtls}, {ip, {127,0,0,2}}]),
    {ok, {_, Port}} = ssl:sockname(S1),
    {ok, S2} = ssl:listen(Port, [{protocol, dtls}, {ip, {127,0,0,3}}]),
    ssl:close(S1),
    ssl:close(S2),
    ok.

dtls_listen_two_sockets_2() ->
    [{doc, "Test with two DTLS dockets: <all_interfaces>:Port, <all_interfaces>:Port"}].
dtls_listen_two_sockets_2(_Config) when is_list(_Config) ->
    {ok, S1} = ssl:listen(0, [{protocol, dtls}]),
    {ok, {_, Port}} = ssl:sockname(S1),
    {error, already_listening} =
        ssl:listen(Port, [{protocol, dtls}]),
    ssl:close(S1),
    ok.

dtls_listen_two_sockets_3() ->
    [{doc, "Test with two DTLS dockets: <all_interfaces>:Port, <all_interfaces>:Port"}].
dtls_listen_two_sockets_3(_Config) when is_list(_Config) ->
    {ok, S1} = ssl:listen(0, [{protocol, dtls}]),
    {ok, {_, Port}} = ssl:sockname(S1),
    {error, already_listening} =
        ssl:listen(Port, [{protocol, dtls}]),
    ssl:close(S1),
    {ok, S2} = ssl:listen(Port, [{protocol, dtls}]),
    ssl:close(S2),
    ok.

dtls_listen_two_sockets_4() ->
  [{doc, "Test with two DTLS dockets: process1 - <all_interfaces>:Port, process2 - <all_interfaces>:Port"}].
dtls_listen_two_sockets_4(_Config) when is_list(_Config) ->
    Test = self(),
    Pid = spawn(fun() ->
                  {ok, S1} = ssl:listen(0, [{protocol, dtls}]),
                  {ok, {_, Port0}} = ssl:sockname(S1),
                  Test ! {self(), Port0}
                end),
    Port =
        receive
            {Pid, Port1} ->
                Port1
        end,
    {ok, S2} =
        ssl:listen(Port, [{protocol, dtls}]),
    ssl:close(S2),
    ok.

dtls_listen_two_sockets_5() ->
    [{doc, "Test with two DTLS dockets: <all_interfaces>:Port, 127.0.0.3:Port"}].
dtls_listen_two_sockets_5(_Config) when is_list(_Config) ->
    {ok, S1} = ssl:listen(0, [{protocol, dtls}]),
    {ok, {_, Port}} = ssl:sockname(S1),
    {error, already_listening} =
        ssl:listen(Port, [{protocol, dtls}, {ip, {127,0,0,3}}]),
    ssl:close(S1),
    {ok, S2} =
        ssl:listen(Port, [{protocol, dtls}, {ip, {127,0,0,3}}]),
    {error, already_listening} =
        ssl:listen(Port, [{protocol, dtls}]),
    ssl:close(S2),
    ok.

dtls_listen_two_sockets_6() ->
    [{doc, "Test with two DTLS dockets: 127.0.0.3:Port, 0.0.0.0:Port"}].
dtls_listen_two_sockets_6(_Config) when is_list(_Config) ->
    {ok, S1} = ssl:listen(0, [{protocol, dtls}, {ip, {127,0,0,3}}]),
    {ok, {_, Port}} = ssl:sockname(S1),
    {error, already_listening} =
        ssl:listen(Port, [{protocol, dtls}, {ip, {0,0,0,0}}]),
    ssl:close(S1),
    ok.

%%--------------------------------------------------------------------
%% Internal functions ------------------------------------------------
%%--------------------------------------------------------------------

%% Helper function for init_per_testcase.
test_listen_on_all_interfaces(S0, Config) ->
    {ok, {_, Port}} = ssl:sockname(S0),
    case ssl:listen(Port, [{protocol, dtls}, {ip, {0,0,0,0}}]) of
        {ok, S1} ->
            ssl:close(S0),
            ssl:close(S1),
            {skip, "Testcase is not supported on this OS."};
        {error, _} ->
            Config
    end.

maybe_skip_tc_on_windows(Testcase, Config)
  when Testcase =:= dtls_listen_two_sockets_5 orelse
       Testcase =:= dtls_listen_two_sockets_6 ->
    case os:type() of
        {win32, _} ->
            {skip, "Testcase not supported in Windows"};
        _ ->
            Config
    end;
maybe_skip_tc_on_windows(_, Config) ->
    Config.
