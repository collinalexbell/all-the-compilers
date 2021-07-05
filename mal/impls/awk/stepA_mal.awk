@include "types.awk"
@include "reader.awk"
@include "printer.awk"
@include "env.awk"
@include "core.awk"

function READ(str)
{
	return reader_read_str(str)
}

# Return 0, an error or the unquote argument (second element of ast).
function starts_with(ast, sym,    idx, len)
{
	if (ast !~ /^\(/)
		return 0
	idx = substr(ast, 2)
	len = types_heap[idx]["len"]
	if (!len || types_heap[idx][0] != sym)
		return 0
	if (len != 2)
		return  "!\"'" sym "' expects 1 argument, not " (len - 1) "."
	return types_heap[idx][1]
}

function quasiquote(ast,    new_idx, ret, ast_idx, elt_i, elt, previous)
{
	if (ast !~ /^[(['{]/) {
		return ast
	}
	if (ast ~ /['\{]/) {
		new_idx = types_allocate()
		types_heap[new_idx][0] = "'quote"
		types_heap[new_idx][1] = ast
		types_heap[new_idx]["len"] = 2
		return "(" new_idx
	}
	ret = starts_with(ast, "'unquote")
	if (ret ~ /^!/) {
		types_release(ast)
		return ret
	}
	if (ret) {
		types_addref(ret)
		types_release(ast)
		return ret
	}
	new_idx = types_allocate()
	types_heap[new_idx]["len"] = 0
	ast_idx = substr(ast, 2)
	for (elt_i=types_heap[ast_idx]["len"]-1; 0<=elt_i; elt_i--) {
		elt = types_heap[ast_idx][elt_i]
		ret = starts_with(elt, "'splice-unquote")
		if (ret ~ /^!/) {
			types_release("(" new_idx)
			types_release(ast)
			return ret
		}
		if (ret) {
			previous = "(" new_idx
			new_idx = types_allocate()
			types_heap[new_idx][0] = "'concat"
			types_heap[new_idx][1] = types_addref(ret)
			types_heap[new_idx][2] = previous
			types_heap[new_idx]["len"] = 3
		} else {
			ret = quasiquote(types_addref(elt))
			if (ret ~ /^!/) {
				types_release(ast)
				return ret
			}
			previous = "(" new_idx
			new_idx = types_allocate()
			types_heap[new_idx][0] = "'cons"
			types_heap[new_idx][1] = ret
			types_heap[new_idx][2] = previous
			types_heap[new_idx]["len"] = 3
		}
	}
	if (ast ~ /^\[/) {
		previous = "(" new_idx
		new_idx = types_allocate()
		types_heap[new_idx][0] = "'vec"
		types_heap[new_idx][1] = previous
		types_heap[new_idx]["len"] = 2
	}
	types_release(ast)
	return "(" new_idx
}

function is_macro_call(ast, env,    idx, len, sym, f)
{
	if (ast !~ /^\(/) return 0
	idx = substr(ast, 2)
	len = types_heap[idx]["len"]
	if (len == 0) return 0
	sym = types_heap[idx][0]
	if (sym !~ /^'/) return 0
	f = env_get(env, sym)
	return f ~ /^\$/ && types_heap[substr(f, 2)]["is_macro"]
}

function macroexpand(ast, env,    idx, f_idx, new_env)
{
	while (is_macro_call(ast, env)) {
		idx = substr(ast, 2)
		f_idx = substr(env_get(env, types_heap[idx][0]), 2)
		new_env = env_new(types_heap[f_idx]["env"], types_heap[f_idx]["params"], idx)
		types_release(ast)
		if (new_env ~ /^!/) {
			return new_env
		}
		types_addref(ast = types_heap[f_idx]["body"])
		ast = EVAL(ast, new_env)
		env_release(new_env)
		if (ast ~ /^!/) {
			return ast
		}
	}
	return ast
}

function eval_ast(ast, env,    i, idx, len, new_idx, ret)
{
	switch (ast) {
	case /^'/:
		ret = env_get(env, ast)
		if (ret !~ /^!/) {
			types_addref(ret)
		}
		return ret
	case /^[([]/:
		idx = substr(ast, 2)
		len = types_heap[idx]["len"]
		new_idx = types_allocate()
		for (i = 0; i < len; ++i) {
			ret = EVAL(types_addref(types_heap[idx][i]), env)
			if (ret ~ /^!/) {
				types_heap[new_idx]["len"] = i
				types_release(substr(ast, 1, 1) new_idx)
				return ret
			}
			types_heap[new_idx][i] = ret
		}
		types_heap[new_idx]["len"] = len
		return substr(ast, 1, 1) new_idx
	case /^\{/:
		idx = substr(ast, 2)
		new_idx = types_allocate()
		for (i in types_heap[idx]) {
			if (i ~ /^[":]/) {
				ret = EVAL(types_addref(types_heap[idx][i]), env)
				if (ret ~ /^!/) {
					types_release("{" new_idx)
					return ret
				}
				types_heap[new_idx][i] = ret
			}
		}
		return "{" new_idx
	default:
		return ast
	}
}

function EVAL_def(ast, env,    idx, sym, ret, len)
{
	idx = substr(ast, 2)
	if (types_heap[idx]["len"] != 3) {
		len = types_heap[idx]["len"]
		types_release(ast)
		env_release(env)
		return "!\"Invalid argument length for 'def!'. Expects exactly 2 arguments, supplied" (len - 1) "."
	}
	sym = types_heap[idx][1]
	if (sym !~ /^'/) {
		types_release(ast)
		env_release(env)
		return "!\"Incompatible type for argument 1 of 'def!'. Expects symbol, supplied " types_typename(sym) "."
	}
	ret = EVAL(types_addref(types_heap[idx][2]), env)
	if (ret !~ /^!/) {
		env_set(env, sym, ret)
		types_addref(ret)
	}
	types_release(ast)
	env_release(env)
	return ret
}

function EVAL_let(ast, env,    ret_env,    idx, params, params_idx, params_len, new_env, i, sym, ret, body, len)
{
	idx = substr(ast, 2)
	if (types_heap[idx]["len"] != 3) {
		len = types_heap[idx]["len"]
		types_release(ast)
		env_release(env)
		return "!\"Invalid argument length for 'let*'. Expects exactly 2 arguments, supplied " (len - 1) "."
	}
	params = types_heap[idx][1]
	if (params !~ /^[([]/) {
		types_release(ast)
		env_release(env)
		return "!\"Incompatible type for argument 1 of 'let*'. Expects list or vector, supplied " types_typename(params) "."
	}
	params_idx = substr(params, 2)
	params_len = types_heap[params_idx]["len"]
	if (params_len % 2 != 0) {
		types_release(ast)
		env_release(env)
		return "!\"Invalid elements count for argument 1 of 'let*'. Expects even number of elements, supplied " params_len "."
	}
	new_env = env_new(env)
	env_release(env)
	for (i = 0; i < params_len; i += 2) {
		sym = types_heap[params_idx][i]
		if (sym !~ /^'/) {
			types_release(ast)
			env_release(new_env)
			return "!\"Incompatible type for odd element of argument 1 of 'let*'. Expects symbol, supplied " types_typename(sym) "."
		}
		ret = EVAL(types_addref(types_heap[params_idx][i + 1]), new_env)
		if (ret ~ /^!/) {
			types_release(ast)
			env_release(new_env)
			return ret
		}
		env_set(new_env, sym, ret)
	}
	types_addref(body = types_heap[idx][2])
	types_release(ast)
	ret_env[0] = new_env
	return body
}

function EVAL_defmacro(ast, env,    idx, sym, ret, len)
{
	idx = substr(ast, 2)
	if (types_heap[idx]["len"] != 3) {
		len = types_heap[idx]["len"]
		types_release(ast)
		env_release(env)
		return "!\"Invalid argument length for 'defmacro!'. Expects exactly 2 arguments, supplied" (len - 1) "."
	}
	sym = types_heap[idx][1]
	if (sym !~ /^'/) {
		types_release(ast)
		env_release(env)
		return "!\"Incompatible type for argument 1 of 'defmacro!'. Expects symbol, supplied " types_typename(sym) "."
	}
	ret = EVAL(types_addref(types_heap[idx][2]), env)
	types_release(ast)
	if (ret ~ /^!/) {
		env_release(env)
		return ret
	}
	if (ret !~ /^\$/) {
		types_release(ret)
		env_release(env)
		return "!\"Incompatible type for argument 2 of 'defmacro!'. Expects function, supplied " types_typename(ret) "."
	}
	types_heap[substr(ret, 2)]["is_macro"] = 1
	env_set(env, sym, ret)
	types_addref(ret)
	env_release(env)
	return ret
}

function EVAL_try(ast, env,    catch_body, catch_env,    idx, catch, catch_idx, catch_sym, ret, len, str)
{
	idx = substr(ast, 2)
	len = types_heap[idx]["len"]
	if (len != 2 && len != 3) {
		types_release(ast)
		env_release(env)
		return "!\"Invalid argument length for 'try*'. Expects 1 or 2 arguments, supplied" (len - 1) "."
	}
	if (len == 2) {
		ret = EVAL(types_addref(types_heap[idx][1]), env)
		types_release(ast)
		env_release(env)
		return ret
	}
	catch = types_heap[idx][2]
	if (catch !~ /^\(/) {
		types_release(ast)
		env_release(env)
		return "!\"Incompatible type for argument 2 of 'try*'. Expects list, supplied " types_typename(catch) "."
	}
	catch_idx = substr(catch, 2)
	if (types_heap[catch_idx]["len"] != 3) {
		len = types_heap[catch_idx]["len"]
		types_release(ast)
		env_release(env)
		return "!\"Invalid elements count for argument 2 of 'try*'. Expects exactly 3 elements, supplied " len "."
	}
	if (types_heap[catch_idx][0] != "'catch*") {
		str = printer_pr_str(types_heap[catch_idx][0])
		types_release(ast)
		env_release(env)
		return "!\"Invalid first element of argument 2 of 'try*'. Expects symbol 'catch*', supplied '" str "'."
	}
	catch_sym = types_heap[catch_idx][1]
	if (catch_sym !~ /^'/) {
		types_release(ast)
		env_release(env)
		return "!\"Incompatible type for second element of argument 2 of 'try*'. Expects symbol, supplied " types_typename(catch_sym) "."
	}
	ret = EVAL(types_addref(types_heap[idx][1]), env)
	if (ret !~ /^!/) {
		types_release(ast)
		env_release(env)
		return ret
	}
	types_addref(catch_body[0] = types_heap[catch_idx][2])
	catch_env[0] = env_new(env)
	env_release(env)
	env_set(catch_env[0], catch_sym, substr(ret, 2))
	types_release(ast)
	return ""
}

function EVAL_do(ast, env,    idx, len, i, body, ret)
{
	idx = substr(ast, 2)
	len = types_heap[idx]["len"]
	if (len == 1) {
		types_release(ast)
		env_release(env)
		return "!\"Invalid argument length for 'do'. Expects at least 1 argument, supplied" (len - 1) "."
	}
	for (i = 1; i < len - 1; ++i) {
		ret = EVAL(types_addref(types_heap[idx][i]), env)
		if (ret ~ /^!/) {
			types_release(ast)
			env_release(env)
			return ret
		}
		types_release(ret)
	}
	types_addref(body = types_heap[idx][len - 1])
	types_release(ast)
	return body
}

function EVAL_if(ast, env,    idx, len, ret, body)
{
	idx = substr(ast, 2)
	len = types_heap[idx]["len"]
	if (len != 3 && len != 4) {
		types_release(ast)
		return "!\"Invalid argument length for 'if'. Expects 2 or 3 arguments, supplied " (len - 1) "."
	}
	ret = EVAL(types_addref(types_heap[idx][1]), env)
	if (ret ~ /^!/) {
		types_release(ast)
		return ret
	}
	types_release(ret)
	switch (ret) {
	case "#nil":
	case "#false":
		if (len == 3) {
			body = "#nil"
		} else {
			types_addref(body = types_heap[idx][3])
		}
		break
	default:
		types_addref(body = types_heap[idx][2])
		break
	}
	types_release(ast)
	return body
}

function EVAL_fn(ast, env,    idx, params, params_idx, params_len, i, sym, f_idx, len)
{
	idx = substr(ast, 2)
	if (types_heap[idx]["len"] != 3) {
		len = types_heap[idx]["len"]
		types_release(ast)
		env_release(env)
		return "!\"Invalid argument length for 'fn*'. Expects exactly 2 arguments, supplied " (len - 1) "."
	}
	params = types_heap[idx][1]
	if (params !~ /^[([]/) {
		types_release(ast)
		env_release(env)
		return "!\"Incompatible type for argument 1 of 'fn*'. Expects list or vector, supplied " types_typename(params) "."
	}
	params_idx = substr(params, 2)
	params_len = types_heap[params_idx]["len"]
	for (i = 0; i < params_len; ++i) {
		sym = types_heap[params_idx][i]
		if (sym !~ /^'/) {
			types_release(ast)
			env_release(env)
			return "!\"Incompatible type for element of argument 1 of 'fn*'. Expects symbol, supplied " types_typename(sym) "."
		}
		if (sym == "'&" && i + 2 != params_len) {
			types_release(ast)
			env_release(env)
			return "!\"Symbol '&' should be followed by last parameter. Parameter list length is " params_len ", position of symbol '&' is " (i + 1) "."
		}
	}
	f_idx = types_allocate()
	types_addref(types_heap[f_idx]["params"] = types_heap[idx][1])
	types_addref(types_heap[f_idx]["body"] = types_heap[idx][2])
	types_heap[f_idx]["env"] = env
	types_release(ast)
	return "$" f_idx
}

function EVAL(ast, env,    body, new_ast, ret, idx, len, f, f_idx, ret_body, ret_env)
{
	env_addref(env)
	for (;;) {
		if (ast !~ /^\(/) {
			ret = eval_ast(ast, env)
			types_release(ast)
			env_release(env)
			return ret
		}
		if (types_heap[substr(ast, 2)]["len"] == 0) {
			env_release(env)
			return ast
		}
		ast = macroexpand(ast, env)
		if (ast ~ /^!/) {
			env_release(env)
			return ast
		}
		if (ast !~ /^\(/) {
			ret = eval_ast(ast, env)
			types_release(ast)
			env_release(env)
			return ret
		}
		idx = substr(ast, 2)
		len = types_heap[idx]["len"]
		switch (types_heap[idx][0]) {
		case "'def!":
			return EVAL_def(ast, env)
		case "'let*":
			ast = EVAL_let(ast, env,    ret_env)
			if (ast ~ /^!/) {
				return ast
			}
			env = ret_env[0]
			continue
		case "'quote":
			if (len != 2) {
				types_release(ast)
				env_release(env)
				return "!\"Invalid argument length for 'quote'. Expects exactly 1 argument, supplied " (len - 1) "."
			}
			types_addref(body = types_heap[idx][1])
			types_release(ast)
			env_release(env)
			return body
		case "'quasiquoteexpand":
			env_release(env)
			if (len != 2) {
				types_release(ast)
				return "!\"Invalid argument length for 'quasiquoteexpand'. Expects exactly 1 argument, supplied " (len - 1) "."
			}
			types_addref(body = types_heap[idx][1])
			types_release(ast)
			return quasiquote(body)
		case "'quasiquote":
			if (len != 2) {
				types_release(ast)
				env_release(env)
				return "!\"Invalid argument length for 'quasiquote'. Expects exactly 1 argument, supplied " (len - 1) "."
			}
			types_addref(body = types_heap[idx][1])
			types_release(ast)
			ast = quasiquote(body)
			if (ast ~ /^!/) {
				env_release(env)
				return ast
			}
			continue
		case "'defmacro!":
			return EVAL_defmacro(ast, env)
		case "'macroexpand":
			if (len != 2) {
				types_release(ast)
				env_release(env)
				return "!\"Invalid argument length for 'macroexpand'. Expects exactly 1 argument, supplied " (len - 1) "."
			}
			types_addref(body = types_heap[idx][1])
			types_release(ast)
			ret = macroexpand(body, env)
			env_release(env)
			return ret
		case "'try*":
			ret = EVAL_try(ast, env,    ret_body, ret_env)
			if (ret != "") {
				return ret
			}
			ast = ret_body[0]
			env = ret_env[0]
			continue
		case "'do":
			ast = EVAL_do(ast, env)
			if (ast ~ /^!/) {
				return ast
			}
			continue
		case "'if":
			ast = EVAL_if(ast, env)
			if (ast !~ /^['([{]/) {
				env_release(env)
				return ast
			}
			continue
		case "'fn*":
			return EVAL_fn(ast, env)
		default:
			new_ast = eval_ast(ast, env)
			types_release(ast)
			env_release(env)
			if (new_ast ~ /^!/) {
				return new_ast
			}
			idx = substr(new_ast, 2)
			f = types_heap[idx][0]
			f_idx = substr(f, 2)
			switch (f) {
			case /^\$/:
				env = env_new(types_heap[f_idx]["env"], types_heap[f_idx]["params"], idx)
				if (env ~ /^!/) {
					types_release(new_ast)
					return env
				}
				types_addref(ast = types_heap[f_idx]["body"])
				types_release(new_ast)
				continue
			case /^%/:
				f_idx = types_heap[f_idx]["func"]
			case /^&/:
				ret = @f_idx(idx)
				types_release(new_ast)
				return ret
			default:
				types_release(new_ast)
				return "!\"First element of list must be function, supplied " types_typename(f) "."
			}
		}
	}
}

function PRINT(expr,    str)
{
	str = printer_pr_str(expr, 1)
	types_release(expr)
	return str
}

function rep(str,    ast, expr)
{
	ast = READ(str)
	if (ast ~ /^!/) {
		return ast
	}
	expr = EVAL(ast, repl_env)
	if (expr ~ /^!/) {
		return expr
	}
	return PRINT(expr)
}

function eval(idx)
{
	if (types_heap[idx]["len"] != 2) {
		return "!\"Invalid argument length for builtin function 'eval'. Expects exactly 1 argument, supplied " (types_heap[idx]["len"] - 1) "."
	}
	return EVAL(types_addref(types_heap[idx][1]), repl_env)
}

function main(str, ret, i, idx)
{
	repl_env = env_new()
	for (i in core_ns) {
		env_set(repl_env, i, core_ns[i])
	}

	env_set(repl_env, "'eval", "&eval")

	rep("(def! *host-language* \"GNU awk\")")
	rep("(def! not (fn* (a) (if a false true)))")
	rep("(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \"\\nnil)\")))))")
	rep("(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw \"odd number of forms to cond\")) (cons 'cond (rest (rest xs)))))))")

	idx = types_allocate()
	env_set(repl_env, "'*ARGV*", "(" idx)
	if (ARGC > 1) {
		for (i = 2; i < ARGC; ++i) {
			types_heap[idx][i - 2] = "\"" ARGV[i]
		}
		types_heap[idx]["len"] = ARGC - 2
		ARGC = 1
		rep("(load-file \"" ARGV[1] "\")")
		return
	}
	types_heap[idx]["len"] = 0

	rep("(println (str \"Mal [\" *host-language* \"]\"))")
	while (1) {
		printf("user> ")
		if (getline str <= 0) {
			break
		}
		ret = rep(str)
		if (ret ~ /^!/) {
			print "ERROR: " printer_pr_str(substr(ret, 2))
		} else {
			print ret
		}
	}
}

BEGIN {
	main()
	env_check(0)
	env_dump()
	types_dump()
	exit(0)
}
