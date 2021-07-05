%%%
%%% Step 3: env
%%%

-module(step3_env).

-export([main/1]).

main(_) ->
    loop(core:ns()).

loop(Env) ->
    case io:get_line(standard_io, "user> ") of
        eof -> io:format("~n");
        {error, Reason} -> exit(Reason);
        Line ->
            print(rep(string:strip(Line, both, $\n), Env)),
            loop(Env)
    end.

rep(Input, Env) ->
    try eval(read(Input), Env) of
        none -> none;
        Result -> printer:pr_str(Result, true)
    catch
        error:Reason -> printer:pr_str({error, Reason}, true)
    end.

read(Input) ->
    case reader:read_str(Input) of
        {ok, Value} -> Value;
        {error, Reason} -> error(Reason)
    end.

eval({list, [], _Meta}=AST, _Env) ->
    AST;
eval({list, [{symbol, "def!"}, {symbol, A1}, A2], _Meta}, Env) ->
    Result = eval(A2, Env),
    env:set(Env, {symbol, A1}, Result),
    Result;
eval({list, [{symbol, "def!"}, _A1, _A2], _Meta}, _Env) ->
    error("def! called with non-symbol");
eval({list, [{symbol, "def!"}|_], _Meta}, _Env) ->
    error("def! requires exactly two arguments");
eval({list, [{symbol, "let*"}, A1, A2], _Meta}, Env) ->
    NewEnv = env:new(Env),
    let_star(NewEnv, A1),
    eval(A2, NewEnv);
eval({list, [{symbol, "let*"}|_], _Meta}, _Env) ->
    error("let* requires exactly two arguments");
eval({list, List, Meta}, Env) ->
    case eval_ast({list, List, Meta}, Env) of
        {list, [{function, F, _MF}|A], _M1} -> erlang:apply(F, [A]);
        _ -> error("expected a list with a function")
    end;
eval(Value, Env) ->
    eval_ast(Value, Env).

eval_ast({symbol, _Sym}=Value, Env) ->
    env:get(Env, Value);
eval_ast({Type, Seq, _Meta}, Env) when Type == list orelse Type == vector ->
    {Type, lists:map(fun(Elem) -> eval(Elem, Env) end, Seq), nil};
eval_ast({map, M, _Meta}, Env) ->
    {map, maps:map(fun(_Key, Val) -> eval(Val, Env) end, M), nil};
eval_ast(Value, _Env) ->
    Value.

print(none) ->
    % if nothing meaningful was entered, print nothing at all
    ok;
print(Value) ->
    io:format("~s~n", [Value]).

let_star(Env, Bindings) ->
    % (let* (p (+ 2 3) q (+ 2 p)) (+ p q))
    % ;=>12
    Bind = fun({Name, Expr}) ->
        case Name of
            {symbol, _Sym} -> env:set(Env, Name, eval(Expr, Env));
            _ -> error("let* with non-symbol binding")
        end
    end,
    case Bindings of
        {Type, Binds, _Meta} when Type == list orelse Type == vector ->
            case list_to_proplist(Binds) of
                {error, Reason} -> error(Reason);
                Props -> lists:foreach(Bind, Props)
            end;
        _ -> error("let* with non-list bindings")
    end.

list_to_proplist(L) ->
    list_to_proplist(L, []).

list_to_proplist([], AccIn) ->
    lists:reverse(AccIn);
list_to_proplist([_H], _AccIn) ->
    {error, "mismatch in let* name/value bindings"};
list_to_proplist([K,V|T], AccIn) ->
    list_to_proplist(T, [{K, V}|AccIn]).
