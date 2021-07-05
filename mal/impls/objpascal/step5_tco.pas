program Mal;

{$H+} // Use AnsiString

Uses sysutils,
     CMem,
     fgl,
     mal_readline,
     mal_types,
     mal_func,
     reader,
     printer,
     mal_env,
     core;

var
    Repl_Env : TEnv;
    Line     : string;
    I        : longint;
    Key      : string;

// read
function READ(const Str: string) : TMal;
begin
    READ := read_str(Str);
end;

// eval
// Forward declation since eval_ast call it
function EVAL(Ast: TMal; Env: TEnv) : TMal; forward;

function eval_ast(Ast: TMal; Env: TEnv) : TMal;
var
    OldArr, NewArr   : TMalArray;
    OldDict, NewDict : TMalDict;
    I                : longint;
begin
    if Ast is TMalSymbol then
    begin
        eval_ast := Env.Get((Ast as TMalSymbol));
    end
    else if Ast is TMalList then
    begin
        OldArr := (Ast as TMalList).Val;
        SetLength(NewArr, Length(OldArr));
        for I := 0 to Length(OldArr)-1 do
        begin
            NewArr[I] := EVAL(OldArr[I], Env);
        end;
        if Ast is TMalVector then
            eval_ast := TMalVector.Create(NewArr)
        else
            eval_ast := TMalList.Create(NewArr);
    end
    else if Ast is TMalHashMap then
    begin
        OldDict := (Ast as TMalHashMap).Val;
        NewDict := TMalDict.Create;
        I := 0;
        while I < OldDict.Count do
        begin
            NewDict[OldDict.Keys[I]] := EVAL(OldDict[OldDict.Keys[I]], Env);
            I := I + 1;
        end;
        eval_ast := TMalHashMap.Create(NewDict);
    end
    else
        eval_ast := Ast;
end;

function EVAL(Ast: TMal; Env: TEnv) : TMal;
var
    Lst    : TMalList;
    Arr    : TMalArray;
    Arr1   : TMalArray;
    A0Sym  : string;
    LetEnv : TEnv;
    Cond   : TMal;
    I      : longint;
    Fn     : TMalFunc;
    Args   : TMalArray;
begin
  while true do
  begin
    if Ast.ClassType <> TMalList then
        Exit(eval_ast(Ast, Env));

    // Apply list
    Lst := (Ast as TMalList);
    Arr := Lst.Val;
    if Length(Arr) = 0 then
        Exit(Ast);
    if Arr[0] is TMalSymbol then
        A0Sym := (Arr[0] as TMalSymbol).Val
    else
        A0Sym := '__<*fn*>__';

    case A0Sym of
    'def!':
        Exit(Env.Add((Arr[1] as TMalSymbol), EVAL(Arr[2], ENV)));
    'let*':
        begin
            LetEnv := TEnv.Create(Env);
            Arr1 := (Arr[1] as TMalList).Val;
            I := 0;
            while I < Length(Arr1) do
            begin
                LetEnv.Add((Arr1[I] as TMalSymbol), EVAL(Arr1[I+1], LetEnv));
                Inc(I,2);
            end;
            Env := LetEnv;
            Ast := Arr[2]; // TCO
        end;
    'do':
        begin
            eval_ast(TMalList.Create(copy(Arr,1, Length(Arr)-2)), Env);
            Ast := Arr[Length(Arr)-1]; // TCO
        end;
    'if':
        begin
            Cond := EVAL(Arr[1], Env);
            if (Cond is TMalNil) or (Cond is TMalFalse) then
                if Length(Arr) > 3 then
                    Ast := Arr[3] // TCO
                else
                    Exit(TMalNil.Create)
            else
                Ast := Arr[2]; // TCO
        end;
    'fn*':
        begin
            Exit(TMalFunc.Create(Arr[2], Env, (Arr[1] as TMalList)));
        end;
    else
        begin
            Arr := (eval_ast(Ast, Env) as TMalList).Val;
            if Arr[0] is TMalFunc then
            begin
                Fn := Arr[0] as TMalFunc;
                if Length(Arr) < 2 then
                    SetLength(Args, 0)
                else
                    Args := copy(Arr, 1, Length(Arr)-1);
                if Fn.Ast = nil then
                    Exit(Fn.Val(Args))
                else
                begin
                    Env := TEnv.Create(Fn.Env, Fn.Params, Args);
                    Ast := Fn.Ast; // TCO
                end

            end
            else
                raise Exception.Create('invalid apply');
        end;
    end;
  end;
end;

// print
function PRINT(Exp: TMal) : string;
begin
    PRINT := pr_str(Exp, True);
end;

// repl
function REP(Str: string) : string;
begin
    REP := PRINT(EVAL(READ(Str), Repl_Env));
end;

begin
    Repl_Env := TEnv.Create;

    // core.pas: defined using Pascal
    for I := 0 to core.NS.Count-1 do
    begin
        Key := core.NS.Keys[I];
        Repl_Env.Add(TMalSymbol.Create(Key),
                     TMalFunc.Create(core.NS[Key]));
    end;

    // core.mal: defined using language itself
    REP('(def! not (fn* (a) (if a false true)))');

    while True do
    begin
        try
            Line := _readline('user> ');
            if Line = '' then continue;
            WriteLn(REP(Line))
        except
            On E : MalEOF do Halt(0);
            On E : Exception do
            begin
                WriteLn('Error: ' + E.message);
                WriteLn('Backtrace:');
                WriteLn(GetBacktrace(E));
            end;
        end;
    end;
end.
