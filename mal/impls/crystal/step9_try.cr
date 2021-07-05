#! /usr/bin/env crystal run

require "readline"
require "./reader"
require "./printer"
require "./types"
require "./env"
require "./core"
require "./error"

# Note:
# Employed downcase names because Crystal prohibits uppercase names for methods

module Mal
  extend self

  def func_of(env, binds, body)
    ->(args : Array(Mal::Type)) {
      new_env = Mal::Env.new(env, binds, args)
      eval(body, new_env)
    }.as(Mal::Func)
  end

  def eval_ast(ast, env)
    return ast.map { |n| eval(n, env).as(Mal::Type) } if ast.is_a? Mal::List

    val = ast.unwrap

    Mal::Type.new case val
    when Mal::Symbol
      if e = env.get(val.str)
        e
      else
        eval_error "'#{val.str}' not found"
      end
    when Mal::List
      val.each_with_object(Mal::List.new) { |n, l| l << eval(n, env) }
    when Mal::Vector
      val.each_with_object(Mal::Vector.new) { |n, l| l << eval(n, env) }
    when Array(Mal::Type)
      val.map { |n| eval(n, env).as(Mal::Type) }
    when Mal::HashMap
      val.each { |k, v| val[k] = eval(v, env) }
      val
    else
      val
    end
  end

  def read(str)
    read_str str
  end

  def starts_with(list, symbol)
    if list.size == 2
      head = list.first.unwrap
      head.is_a? Mal::Symbol && head.str == symbol
    end
  end

  def quasiquote_elts(list)
    acc = Mal::Type.new(Mal::List.new)
    list.reverse.each do |elt|
      elt_val = elt.unwrap
      if elt_val.is_a? Mal::List && starts_with(elt_val, "splice-unquote")
        acc = Mal::Type.new(
          Mal::List.new << gen_type(Mal::Symbol, "concat") << elt_val[1] << acc
        )
      else
        acc = Mal::Type.new(
          Mal::List.new << gen_type(Mal::Symbol, "cons") << quasiquote(elt) << acc
        )
      end
    end
    acc
  end

  def quasiquote(ast)
    ast_val = ast.unwrap
    case ast_val
    when Mal::List
      if starts_with(ast_val,"unquote")
        ast_val[1]
      else
        quasiquote_elts(ast_val)
      end
    when Mal::Vector
      Mal::Type.new(
        Mal::List.new << gen_type(Mal::Symbol, "vec") << quasiquote_elts(ast_val)
      )
    when Mal::HashMap, Mal::Symbol
      Mal::Type.new (
        Mal::List.new << gen_type(Mal::Symbol, "quote") << ast
      )
    else
      ast
    end
  end

  def macro_call?(ast, env)
    list = ast.unwrap
    return false unless list.is_a? Mal::List
    return false if list.empty?

    sym = list.first.unwrap
    return false unless sym.is_a? Mal::Symbol

    func = env.find(sym.str).try(&.data[sym.str])
    return false unless func && func.macro?

    true
  end

  def macroexpand(ast, env)
    while macro_call?(ast, env)
      # Already checked in macro_call?
      list = ast.unwrap.as(Mal::List)
      func_sym = list[0].unwrap.as(Mal::Symbol)
      func = env.get(func_sym.str).unwrap

      case func
      when Mal::Func
        ast = func.call(list[1..-1])
      when Mal::Closure
        ast = func.fn.call(list[1..-1])
      else
        eval_error "macro '#{func_sym.str}' must be function: #{ast}"
      end
    end

    ast
  end

  macro invoke_list(l, env)
    f = eval({{l}}.first, {{env}}).unwrap
    args = eval_ast({{l}}[1..-1].to_mal, {{env}})
    case f
    when Mal::Closure
      ast = f.ast
      {{env}} = Mal::Env.new(f.env, f.params, args)
      next # TCO
    when Mal::Func
      return f.call args
    else
      eval_error "expected function as the first argument: #{f}"
    end
  end

  def eval(ast, env)
    # 'next' in 'do...end' has a bug in crystal 0.7.1
    # https://github.com/manastech/crystal/issues/659
    while true
      list = ast.unwrap

      return eval_ast(ast, env) unless list.is_a? Mal::List
      return ast if list.empty?

      ast = macroexpand(ast, env)

      list = ast.unwrap

      return eval_ast(ast, env) unless list.is_a? Mal::List
      return ast if list.empty?

      head = list.first.unwrap

      return invoke_list(list, env) unless head.is_a? Mal::Symbol

      return Mal::Type.new case head.str
      when "def!"
        eval_error "wrong number of argument for 'def!'" unless list.size == 3
        a1 = list[1].unwrap
        eval_error "1st argument of 'def!' must be symbol: #{a1}" unless a1.is_a? Mal::Symbol
        env.set(a1.str, eval(list[2], env))
      when "let*"
        eval_error "wrong number of argument for 'def!'" unless list.size == 3

        bindings = list[1].unwrap
        eval_error "1st argument of 'let*' must be list or vector" unless bindings.is_a? Array
        eval_error "size of binding list must be even" unless bindings.size.even?

        new_env = Mal::Env.new env
        bindings.each_slice(2) do |binding|
          key, value = binding
          name = key.unwrap
          eval_error "name of binding must be specified as symbol #{name}" unless name.is_a? Mal::Symbol
          new_env.set(name.str, eval(value, new_env))
        end

        ast, env = list[2], new_env
        next # TCO
      when "do"
        if list.empty?
          ast = Mal::Type.new nil
          next
        end

        eval_ast(list[1..-2].to_mal, env)
        ast = list.last
        next # TCO
      when "if"
        ast = unless eval(list[1], env).unwrap
          list.size >= 4 ? list[3] : Mal::Type.new(nil)
        else
          list[2]
        end
        next # TCO
      when "fn*"
        params = list[1].unwrap
        unless params.is_a? Array
          eval_error "'fn*' parameters must be list or vector: #{params}"
        end
        Mal::Closure.new(list[2], params, env, func_of(env, params, list[2]))
      when "quote"
        list[1]
      when "quasiquoteexpand"
        quasiquote list[1]
      when "quasiquote"
        ast = quasiquote list[1]
        next # TCO
      when "defmacro!"
        eval_error "wrong number of argument for 'defmacro!'" unless list.size == 3
        a1 = list[1].unwrap
        eval_error "1st argument of 'defmacro!' must be symbol: #{a1}" unless a1.is_a? Mal::Symbol
        env.set(a1.str, eval(list[2], env).tap { |n| n.is_macro = true })
      when "macroexpand"
        macroexpand(list[1], env)
      when "try*"
        catch_list = list.size >= 3 ? list[2].unwrap : Mal::Type.new(nil)
        return eval(list[1], env) unless catch_list.is_a? Mal::List

        catch_head = catch_list.first.unwrap
        return eval(list[1], env) unless catch_head.is_a? Mal::Symbol
        return eval(list[1], env) unless catch_head.str == "catch*"

        begin
          eval(list[1], env)
        rescue e : Mal::RuntimeException
          new_env = Mal::Env.new(env, [catch_list[1]], [e.thrown])
          eval(catch_list[2], new_env)
        rescue e
          new_env = Mal::Env.new(env, [catch_list[1]], [Mal::Type.new e.message])
          eval(catch_list[2], new_env)
        end
      else
        invoke_list(list, env)
      end
    end
  end

  def print(result)
    pr_str(result, true)
  end

  def rep(str)
    print(eval(read(str), REPL_ENV))
  end
end

REPL_ENV = Mal::Env.new nil
Mal::NS.each { |k, v| REPL_ENV.set(k, Mal::Type.new(v)) }
REPL_ENV.set("eval", Mal::Type.new ->(args : Array(Mal::Type)) { Mal.eval(args[0], REPL_ENV) })
Mal.rep "(def! not (fn* (a) (if a false true)))"
Mal.rep "(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \"\nnil)\")))))"
Mal.rep "(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw \"odd number of forms to cond\")) (cons 'cond (rest (rest xs)))))))"

argv = Mal::List.new
REPL_ENV.set("*ARGV*", Mal::Type.new argv)

unless ARGV.empty?
  if ARGV.size > 1
    ARGV[1..-1].each do |a|
      argv << Mal::Type.new(a)
    end
  end

  begin
    Mal.rep "(load-file \"#{ARGV[0]}\")"
  rescue e
    STDERR.puts e
  end
  exit
end

while line = Readline.readline("user> ", true)
  begin
    puts Mal.rep(line)
  rescue e : Mal::RuntimeException
    STDERR.puts "Error: #{pr_str(e.thrown, true)}"
  rescue e
    STDERR.puts "Error: #{e}"
  end
end
