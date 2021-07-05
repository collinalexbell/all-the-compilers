entity step6_file is
end entity step6_file;

library STD;
use STD.textio.all;
library WORK;
use WORK.pkg_readline.all;
use WORK.types.all;
use WORK.printer.all;
use WORK.reader.all;
use WORK.env.all;
use WORK.core.all;

architecture test of step6_file is

  shared variable repl_env: env_ptr;

  procedure mal_READ(str: in string; ast: out mal_val_ptr; err: out mal_val_ptr) is
  begin
    read_str(str, ast, err);
  end procedure mal_READ;

  -- Forward declaration
  procedure EVAL(in_ast: inout mal_val_ptr; in_env: inout env_ptr; result: out mal_val_ptr; err: out mal_val_ptr);

  procedure apply_func(fn: inout mal_val_ptr; args: inout mal_val_ptr; result: out mal_val_ptr; err: out mal_val_ptr);

  procedure fn_eval(args: inout mal_val_ptr; result: out mal_val_ptr; err: out mal_val_ptr) is
  begin
    EVAL(args.seq_val(0), repl_env, result, err);
  end procedure fn_eval;

  procedure fn_swap(args: inout mal_val_ptr; result: out mal_val_ptr; err: out mal_val_ptr) is
    variable atom: mal_val_ptr := args.seq_val(0);
    variable fn: mal_val_ptr := args.seq_val(1);
    variable call_args_seq: mal_seq_ptr;
    variable call_args, eval_res, sub_err: mal_val_ptr;
  begin
    call_args_seq := new mal_seq(0 to args.seq_val'length - 2);
    call_args_seq(0) := atom.seq_val(0);
    call_args_seq(1 to call_args_seq'length - 1) := args.seq_val(2 to args.seq_val'length - 1);
    new_seq_obj(mal_list, call_args_seq, call_args);
    apply_func(fn, call_args, eval_res, sub_err);
    if sub_err /= null then
      err := sub_err;
      return;
    end if;
    atom.seq_val(0) := eval_res;
    result := eval_res;
  end procedure fn_swap;

  procedure apply_native_func(func_sym: inout mal_val_ptr; args: inout mal_val_ptr; result: out mal_val_ptr; err: out mal_val_ptr) is
  begin
    if func_sym.string_val.all = "eval" then
      fn_eval(args, result, err);
    elsif func_sym.string_val.all = "swap!" then
      fn_swap(args, result, err);
    else
      eval_native_func(func_sym, args, result, err);
    end if;
  end procedure apply_native_func;

  procedure apply_func(fn: inout mal_val_ptr; args: inout mal_val_ptr; result: out mal_val_ptr; err: out mal_val_ptr) is
    variable fn_env: env_ptr;
  begin
    case fn.val_type is
      when mal_nativefn =>
        apply_native_func(fn, args, result, err);
      when mal_fn =>
        new_env(fn_env, fn.func_val.f_env, fn.func_val.f_args, args);
        EVAL(fn.func_val.f_body, fn_env, result, err);
      when others =>
        new_string("not a function", err);
        return;
    end case;
  end procedure apply_func;

  procedure eval_ast_seq(ast_seq: inout mal_seq_ptr; env: inout env_ptr; result: inout mal_seq_ptr; err: out mal_val_ptr) is
    variable eval_err: mal_val_ptr;
  begin
    result := new mal_seq(0 to ast_seq'length - 1);
    for i in result'range loop
      EVAL(ast_seq(i), env, result(i), eval_err);
      if eval_err /= null then
        err := eval_err;
        return;
      end if;
    end loop;
  end procedure eval_ast_seq;

  procedure eval_ast(ast: inout mal_val_ptr; env: inout env_ptr; result: out mal_val_ptr; err: out mal_val_ptr) is
    variable key, val, eval_err, env_err: mal_val_ptr;
    variable new_seq: mal_seq_ptr;
    variable i: integer;
  begin
    case ast.val_type is
      when mal_symbol =>
        env_get(env, ast, val, env_err);
        if env_err /= null then
          err := env_err;
          return;
        end if;
        result := val;
        return;
      when mal_list | mal_vector | mal_hashmap =>
        eval_ast_seq(ast.seq_val, env, new_seq, eval_err);
        if eval_err /= null then
          err := eval_err;
          return;
        end if;
        new_seq_obj(ast.val_type, new_seq, result);
        return;
      when others =>
        result := ast;
        return;
    end case;
  end procedure eval_ast;

  procedure EVAL(in_ast: inout mal_val_ptr; in_env: inout env_ptr; result: out mal_val_ptr; err: out mal_val_ptr) is
    variable i: integer;
    variable ast, evaled_ast, a0, call_args, val, vars, sub_err, fn: mal_val_ptr;
    variable env, let_env, fn_env: env_ptr;
  begin
    ast := in_ast;
    env := in_env;
    loop
      if ast.val_type /= mal_list then
        eval_ast(ast, env, result, err);
        return;
      end if;

      if ast.seq_val'length = 0 then
        result := ast;
        return;
      end if;

      a0 := ast.seq_val(0);
      if a0.val_type = mal_symbol then
        if a0.string_val.all = "def!" then
          EVAL(ast.seq_val(2), env, val, sub_err);
          if sub_err /= null then
            err := sub_err;
            return;
          end if;
          env_set(env, ast.seq_val(1), val);
          result := val;
          return;

        elsif a0.string_val.all = "let*" then
          vars := ast.seq_val(1);
          new_env(let_env, env);
          i := 0;
          while i < vars.seq_val'length loop
            EVAL(vars.seq_val(i + 1), let_env, val, sub_err);
            if sub_err /= null then
              err := sub_err;
              return;
            end if;
            env_set(let_env, vars.seq_val(i), val);
            i := i + 2;
          end loop;
          env := let_env;
          ast := ast.seq_val(2);
          next; -- TCO

        elsif a0.string_val.all = "do" then
          for i in 1 to ast.seq_val'high - 1 loop
            EVAL(ast.seq_val(i), env, result, sub_err);
            if sub_err /= null then
              err := sub_err;
              return;
            end if;
          end loop;
          ast := ast.seq_val(ast.seq_val'high);
          next; -- TCO

        elsif a0.string_val.all = "if" then
          EVAL(ast.seq_val(1), env, val, sub_err);
          if sub_err /= null then
            err := sub_err;
            return;
          end if;
          if val.val_type = mal_nil or val.val_type = mal_false then
            if ast.seq_val'length > 3 then
              ast := ast.seq_val(3);
            else
              new_nil(result);
              return;
            end if;
          else
            ast := ast.seq_val(2);
          end if;
          next; -- TCO

        elsif a0.string_val.all = "fn*" then
          new_fn(ast.seq_val(2), ast.seq_val(1), env, result);
          return;

        end if;
      end if;

      eval_ast(ast, env, evaled_ast, sub_err);
      if sub_err /= null then
        err := sub_err;
        return;
      end if;
      seq_drop_prefix(evaled_ast, 1, call_args);
      fn := evaled_ast.seq_val(0);
      case fn.val_type is
        when mal_nativefn =>
          apply_native_func(fn, call_args, result, err);
          return;
        when mal_fn =>
          new_env(fn_env, fn.func_val.f_env, fn.func_val.f_args, call_args);
          env := fn_env;
          ast := fn.func_val.f_body;
          next; -- TCO
        when others =>
          new_string("not a function", err);
          return;
      end case;
    end loop;
  end procedure EVAL;

  procedure mal_PRINT(exp: inout mal_val_ptr; result: out line) is
  begin
    pr_str(exp, true, result);
  end procedure mal_PRINT;

  procedure RE(str: in string; env: inout env_ptr; result: out mal_val_ptr; err: out mal_val_ptr) is
    variable ast, read_err: mal_val_ptr;
  begin
    mal_READ(str, ast, read_err);
    if read_err /= null then
      err := read_err;
      result := null;
      return;
    end if;
    if ast = null then
      result := null;
      return;
    end if;
    EVAL(ast, env, result, err);
  end procedure RE;

  procedure REP(str: in string; env: inout env_ptr; result: out line; err: out mal_val_ptr) is
    variable eval_res, eval_err: mal_val_ptr;
  begin
    RE(str, env, eval_res, eval_err);
    if eval_err /= null then
      err := eval_err;
      result := null;
      return;
    end if;
    mal_PRINT(eval_res, result);
  end procedure REP;

  procedure set_argv(e: inout env_ptr; program_file: inout line) is
    variable argv_var_name: string(1 to 6) := "*ARGV*";
    variable argv_sym, argv_list: mal_val_ptr;
    file f: text;
    variable status: file_open_status;
    variable one_line: line;
    variable seq: mal_seq_ptr;
    variable element: mal_val_ptr;
  begin
    program_file := null;
    seq := new mal_seq(0 to -1);
    file_open(status, f, external_name => "vhdl_argv.tmp", open_kind => read_mode);
    if status = open_ok then
      if not endfile(f) then
        readline(f, program_file);
        while not endfile(f) loop
          readline(f, one_line);
          new_string(one_line.all, element);
          seq := new mal_seq'(seq.all & element);
        end loop;
      end if;
      file_close(f);
    end if;
    new_seq_obj(mal_list, seq, argv_list);
    new_symbol(argv_var_name, argv_sym);
    env_set(e, argv_sym, argv_list);
  end procedure set_argv;

  procedure repl is
    variable is_eof: boolean;
    variable program_file, input_line, result: line;
    variable eval_sym, eval_fn, dummy_val, err: mal_val_ptr;
    variable outer: env_ptr;
    variable eval_func_name: string(1 to 4) := "eval";
  begin
    outer := null;
    new_env(repl_env, outer);

    -- core.EXT: defined using VHDL (see core.vhdl)
    define_core_functions(repl_env);
    new_symbol(eval_func_name, eval_sym);
    new_nativefn(eval_func_name, eval_fn);
    env_set(repl_env, eval_sym, eval_fn);
    set_argv(repl_env, program_file);

    -- core.mal: defined using the language itself
    RE("(def! not (fn* (a) (if a false true)))", repl_env, dummy_val, err);
    RE("(def! load-file (fn* (f) (eval (read-string (str " & '"' & "(do " & '"' & " (slurp f) " & '"' & "\nnil)" & '"' & ")))))", repl_env, dummy_val, err);

    if program_file /= null then
      REP("(load-file " & '"' & program_file.all & '"' & ")", repl_env, result, err);
      return;
    end if;

    loop
      mal_readline("user> ", is_eof, input_line);
      exit when is_eof;
      next when input_line'length = 0;
      REP(input_line.all, repl_env, result, err);
      if err /= null then
        pr_str(err, false, result);
        result := new string'("Error: " & result.all);
      end if;
      if result /= null then
        mal_printline(result.all);
      end if;
      deallocate(result);
      deallocate(err);
    end loop;
    mal_printline("");
  end procedure repl;

begin
  repl;
end architecture test;
