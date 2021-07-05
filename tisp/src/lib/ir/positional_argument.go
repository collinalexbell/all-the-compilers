package ir

import "github.com/cloe-lang/cloe/src/lib/core"

// PositionalArgument represents a positional argument passed to a function.
// It can be a list value and expanded into multiple arguments.
type PositionalArgument struct {
	value    interface{}
	expanded bool
}

// NewPositionalArgument creates a positional argument.
func NewPositionalArgument(v interface{}, expanded bool) PositionalArgument {
	return PositionalArgument{v, expanded}
}

func (p PositionalArgument) interpret(args []core.Value) core.PositionalArgument {
	return core.NewPositionalArgument(interpretExpression(args, p.value), p.expanded)
}
