package desugar

import (
	"fmt"

	"github.com/cloe-lang/cloe/src/lib/ast"
	"github.com/cloe-lang/cloe/src/lib/consts"
	"github.com/cloe-lang/cloe/src/lib/debug"
	"github.com/cloe-lang/cloe/src/lib/gensym"
)

func desugarMutualRecursionStatement(x interface{}) []interface{} {
	y := ast.Convert(func(x interface{}) interface{} {
		switch x := x.(type) {
		case ast.DefFunction:
			ls := make([]interface{}, 0, len(x.Lets()))

			for _, l := range x.Lets() {
				ls = append(ls, desugarMutualRecursionStatement(l)...)
			}

			return ast.NewDefFunction(x.Name(), x.Signature(), ls, x.Body(), x.DebugInfo())
		case ast.MutualRecursion:
			return desugarMutualRecursion(x)
		}

		return nil
	}, x)

	if ys, ok := y.([]interface{}); ok {
		return ys
	}

	return []interface{}{y}
}

func desugarMutualRecursion(mr ast.MutualRecursion) []interface{} {
	fs := mr.DefFunctions()
	unrecs := make([]interface{}, 0, len(fs))

	for _, f := range fs {
		unrecs = append(unrecs, createUnrecursiveFunction(indexDefFunctions(fs...), f))
	}

	recsList := gensym.GenSym()
	recs := make([]interface{}, 0, len(fs))

	for i, f := range fs {
		recs = append(
			recs,
			ast.NewLetVar(
				f.Name(),
				ast.NewPApp(
					consts.Names.IndexFunction,
					[]interface{}{recsList, fmt.Sprint(i + 1)},
					f.DebugInfo())))
	}

	return append(
		unrecs,
		append(
			[]interface{}{ast.NewLetVar(
				recsList,
				ast.NewPApp("$ys", letStatementsToNames(unrecs), mr.DebugInfo()))},
			recs...)...)
}

func createUnrecursiveFunction(n2i map[string]int, f ast.DefFunction) ast.DefFunction {
	arg := gensym.GenSym()

	return replaceNames(
		arg,
		n2i,
		ast.NewDefFunction(
			gensym.GenSym(),
			prependPositionalsToSig([]string{arg}, f.Signature()),
			f.Lets(),
			f.Body(),
			f.DebugInfo()),
		f.DebugInfo()).(ast.DefFunction)
}

func indexDefFunctions(fs ...ast.DefFunction) map[string]int {
	n2i := make(map[string]int)

	for i, f := range fs {
		n2i[f.Name()] = i + 1
	}

	if len(n2i) != len(fs) {
		panic("Duplicate names were found among mutually-recursive functions")
	}

	return n2i
}

func replaceNames(funcList string, n2i map[string]int, x interface{}, di *debug.Info) interface{} {
	return ast.Convert(func(x interface{}) interface{} {
		switch x := x.(type) {
		case string:
			if i, ok := n2i[x]; ok {
				return ast.NewPApp(
					consts.Names.IndexFunction,
					[]interface{}{funcList, fmt.Sprint(i)},
					di)
			}

			return x
		case ast.DefFunction:
			n2i := copyNameToIndex(n2i)

			for n := range signatureToNames(x.Signature()) {
				delete(n2i, n)
			}

			ls := make([]interface{}, 0, len(x.Lets()))

			for _, l := range x.Lets() {
				switch l := l.(type) {
				case ast.DefFunction:
					delete(n2i, l.Name())
				case ast.LetVar:
					delete(n2i, l.Name())
				default:
					panic("unreachable")
				}

				ls = append(ls, replaceNames(funcList, n2i, l, x.DebugInfo()))
			}

			return ast.NewDefFunction(
				x.Name(),
				x.Signature(),
				ls,
				replaceNames(funcList, n2i, x.Body(), x.DebugInfo()),
				x.DebugInfo())
		}

		return nil
	}, x)
}

func copyNameToIndex(n2i map[string]int) map[string]int {
	new := make(map[string]int)

	for n, i := range n2i {
		new[n] = i
	}

	return new
}

func letStatementsToNames(ls []interface{}) []interface{} {
	ns := make([]interface{}, 0, len(ls))

	for _, l := range ls {
		switch l := l.(type) {
		case ast.DefFunction:
			ns = append(ns, l.Name())
		case ast.LetVar:
			ns = append(ns, l.Name())
		default:
			panic("unreachable")
		}
	}

	return ns
}
