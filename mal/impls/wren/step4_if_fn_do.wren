import "./env" for Env
import "./readline" for Readline
import "./reader" for MalReader
import "./printer" for Printer
import "./types" for MalSymbol, MalList, MalVector, MalMap
import "./core" for Core

class Mal {
  static read(str) {
    return MalReader.read_str(str)
  }

  static eval_ast(ast, env) {
    if (ast is MalSymbol) {
      return env.get(ast.value)
    } else if (ast is MalList) {
      return MalList.new(ast.elements.map { |e| eval(e, env) }.toList)
    } else if (ast is MalVector) {
      return MalVector.new(ast.elements.map { |e| eval(e, env) }.toList)
    } else if (ast is MalMap) {
      var m = {}
      for (e in ast.data) {
        m[e.key] = eval(e.value, env)
      }
      return MalMap.new(m)
    } else {
      return ast
    }
  }

  static eval(ast, env) {
    if (!(ast is MalList)) return eval_ast(ast, env)
    if (ast.isEmpty) return ast
    if (ast[0] is MalSymbol) {
      if (ast[0].value == "def!") {
        return env.set(ast[1].value, eval(ast[2], env))
      } else if (ast[0].value == "let*") {
        var letEnv = Env.new(env)
        var i = 0
        while (i < ast[1].count) {
          letEnv.set(ast[1][i].value, eval(ast[1][i + 1], letEnv))
          i = i + 2
        }
        return eval(ast[2], letEnv)
      } else if (ast[0].value == "do") {
        return eval_ast(ast.rest, env)[-1]
      } else if (ast[0].value == "if") {
        var condval = eval(ast[1], env)
        if (condval) {
          return eval(ast[2], env)
        } else {
          return ast.count > 3 ? eval(ast[3], env) : null
        }
      } else if (ast[0].value == "fn*") {
        return Fn.new { |a| eval(ast[2], Env.new(env, ast[1].elements, a)) }
      }
    }
    var evaled_ast = eval_ast(ast, env)
    var f = evaled_ast[0]
    return f.call(evaled_ast[1..-1])
  }

  static print(ast) {
    return Printer.pr_str(ast)
  }

  static rep(str) {
    return print(eval(read(str), __repl_env))
  }

  static main() {
    __repl_env = Env.new()
    // core.wren: defined in wren
    for (e in Core.ns) { __repl_env.set(e.key, e.value) }
    // core.mal: defined using the language itself
    rep("(def! not (fn* (a) (if a false true)))")
    while (true) {
      var line = Readline.readLine("user> ")
      if (line == null) break
      if (line != "") {
        var fiber = Fiber.new { System.print(rep(line)) }
        fiber.try()
        if (fiber.error) System.print("Error: %(fiber.error)")
      }
    }
    System.print()
  }
}

Mal.main()
