package desugar

import (
	"testing"

	"github.com/cloe-lang/cloe/src/lib/ast"
	"github.com/cloe-lang/cloe/src/lib/consts"
	"github.com/cloe-lang/cloe/src/lib/debug"
	"github.com/stretchr/testify/assert"
)

func TestDesugar(t *testing.T) {
	for _, ss := range [][]interface{}{
		{
			ast.NewLetVar(
				"foo",
				ast.NewPApp("+", []interface{}{"42", "foo"}, debug.NewGoInfo(0))),
		},
		{
			ast.NewLetVar(
				"foo",
				ast.NewAnonymousFunction(ast.NewSignature(nil, "", nil, ""), nil, "123")),
		},
		{
			ast.NewDefFunction(
				"foo",
				ast.NewSignature(nil, "", nil, ""),
				nil,
				ast.NewAnonymousFunction(ast.NewSignature(nil, "", nil, ""), nil, "123"),
				debug.NewGoInfo(0)),
		},
		{
			ast.NewDefFunction(
				"foo",
				ast.NewSignature(nil, "", nil, ""),
				[]interface{}{
					ast.NewLetVar(
						"x",
						ast.NewAnonymousFunction(ast.NewSignature(nil, "", nil, ""), nil, "123")),
				},
				"x",
				debug.NewGoInfo(0)),
		},
		{
			ast.NewDefFunction(
				"factorial",
				ast.NewSignature([]string{"n"}, "", nil, ""),
				nil,
				ast.NewMatch("n", []ast.MatchCase{
					ast.NewMatchCase("0", "1"),
					ast.NewMatchCase(
						"_",
						ast.NewPApp("*",
							[]interface{}{"n", ast.NewPApp(
								"factorial",
								[]interface{}{ast.NewPApp("-", []interface{}{"n", "1"}, debug.NewGoInfo(0))},
								debug.NewGoInfo(0))},
							debug.NewGoInfo(0))),
				}), debug.NewGoInfo(0)),
		},
		{
			ast.NewMutualRecursion([]ast.DefFunction{
				ast.NewDefFunction(
					"foo",
					ast.NewSignature(nil, "", nil, ""),
					nil,
					"bar",
					debug.NewGoInfo(0)),
				ast.NewDefFunction(
					"bar",
					ast.NewSignature(nil, "", nil, ""),
					nil,
					"foo",
					debug.NewGoInfo(0)),
			}, debug.NewGoInfo(0)),
		},
		{
			ast.NewLetVar(
				"v",
				ast.NewMatch("x", []ast.MatchCase{ast.NewMatchCase("y", "z")})),
		},
		{
			ast.NewLetMatch(
				ast.NewPApp(consts.Names.ListFunction, []interface{}{"123", "nil", "x"}, debug.NewGoInfo(0)),
				"y"),
		},
		{
			ast.NewLetMatch(
				ast.NewPApp(consts.Names.DictionaryFunction, []interface{}{"123", "x", "nil", "x"}, debug.NewGoInfo(0)),
				"y"),
		},
		{
			ast.NewDefFunction(
				"factorial",
				ast.NewSignature([]string{"n"}, "", nil, ""),
				[]interface{}{
					ast.NewLetMatch(
						ast.NewPApp(consts.Names.ListFunction, []interface{}{"123", "nil", "x"}, debug.NewGoInfo(0)),
						"y"),
					ast.NewLetMatch(
						ast.NewPApp(consts.Names.DictionaryFunction, []interface{}{"123", "x", "nil", "x"}, debug.NewGoInfo(0)),
						"y"),
				},
				ast.NewMatch("n", []ast.MatchCase{
					ast.NewMatchCase("0", "1"),
					ast.NewMatchCase(
						"_",
						ast.NewPApp("*",
							[]interface{}{"n", ast.NewPApp(
								"factorial",
								[]interface{}{ast.NewPApp("-", []interface{}{"n", "1"}, debug.NewGoInfo(0))},
								debug.NewGoInfo(0))},
							debug.NewGoInfo(0))),
				}), debug.NewGoInfo(0)),
		},
	} {
		t.Logf("%#v", ss)

		for _, s := range Desugar(ss) {
			ast.Convert(func(x interface{}) interface{} {
				switch x := x.(type) {
				case ast.AnonymousFunction:
					t.Fail()
				case ast.DefFunction:
					assert.Zero(t, len(newNames(x.Name()).findInDefFunction(x)))

					for _, l := range x.Lets() {
						_, ok := l.(ast.DefFunction)
						assert.False(t, ok)
					}
				case ast.Match:
					t.Fail()
				case ast.MutualRecursion:
					t.Fail()
				}

				return nil
			}, s)
		}
	}
}
