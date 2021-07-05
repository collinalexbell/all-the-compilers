package desugar

import (
	"github.com/cloe-lang/cloe/src/lib/desugar/match"
)

// Desugar desugars a module of statements in AST.
func Desugar(ss []interface{}) []interface{} {
	for _, f := range []func(interface{}) []interface{}{
		desugarLetMatch,
		desugarLetExpression,
		desugarEmptyCollection,
		desugarDictionaryExpansion,
		match.Desugar,
		desugarAnonymousFunctions,
		desugarMutualRecursionStatement,
		desugarSelfRecursiveStatement,
		flattenStatement,
		removeUnusedVariables,
		removeAliases,
	} {
		new := make([]interface{}, 0, 2*len(ss))

		for _, s := range ss {
			new = append(new, f(s)...)
		}

		ss = new
	}

	return ss
}
