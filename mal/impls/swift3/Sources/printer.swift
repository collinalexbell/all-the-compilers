
func pr_str(_ obj: MalVal, _ print_readably: Bool = true) -> String {
    switch obj {
    case MalVal.MalList(let lst, _):
        let elems = lst.map { pr_str($0, print_readably) }
        return "(" + elems.joined(separator: " ")  + ")"
    case MalVal.MalVector(let lst, _):
        let elems = lst.map { pr_str($0, print_readably) }
        return "[" + elems.joined(separator: " ")  + "]"
    case MalVal.MalHashMap(let dict, _):
        let elems = dict.map {
            pr_str(MalVal.MalString($0), print_readably) +
            " " + pr_str($1, print_readably)
        }
        return "{" + elems.joined(separator: " ")  + "}"
    case MalVal.MalString(let str):
        //print("kw: '\(str[str.startIndex])'")
        if str.characters.count > 0 && str[str.startIndex] == "\u{029e}" {
            return ":" + str[str.index(after: str.startIndex)..<str.endIndex]
        } else if print_readably {
            let s1 = str.replacingOccurrences(of: "\\", with: "\\\\")
            let s2 = s1.replacingOccurrences(of: "\"", with: "\\\"")
            let s3 = s2.replacingOccurrences(of: "\n", with: "\\n")
            return "\"" + s3 + "\""
        } else {
            return str
        }
    case MalVal.MalSymbol(let str):
        return str
    case MalVal.MalInt(let i): return String(i)
    case MalVal.MalNil:        return "nil"
    case MalVal.MalFalse:      return "false"
    case MalVal.MalTrue:       return "true"
    case MalVal.MalFunc(_, nil, _, _, _, _):
        return "#<native function>"
    case MalVal.MalFunc(_, let ast, _, let params, _, _):
        return "(fn* \(pr_str(params![0])) \(pr_str(ast![0])))"
    case MalVal.MalAtom(let ma):
        return "(atom \(pr_str(ma.val, print_readably)))"
    default:
        return String(describing:obj)
    }
}
