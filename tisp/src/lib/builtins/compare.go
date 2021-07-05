package builtins

import "github.com/cloe-lang/cloe/src/lib/core"

func createCompareFunction(checkOrder func(core.NumberType) bool) core.Value {
	return core.NewLazyFunction(
		core.NewSignature(nil, "args", nil, ""),
		func(ts ...core.Value) core.Value {
			l := ts[0]

			if v := core.ReturnIfEmptyList(l, core.True); v != nil {
				return v
			}

			prev := core.PApp(core.First, l)

			if b, err := core.EvalBoolean(core.PApp(core.IsOrdered, prev)); err != nil {
				return err
			} else if !b {
				return core.NotOrderedError(prev)
			}

			for {
				l = core.PApp(core.Rest, l)

				if v := core.ReturnIfEmptyList(l, core.True); v != nil {
					return v
				}

				current := core.PApp(core.First, l)

				if n, err := core.EvalNumber(core.PApp(core.Compare, prev, current)); err != nil {
					return err
				} else if !checkOrder(n) {
					return core.False
				}

				prev = current
			}
		})
}

// Less checks if arguments are aligned in ascending order or not.
var Less = createCompareFunction(func(n core.NumberType) bool { return n == -1 })

// LessEq checks if arguments are aligned in ascending order or not.
var LessEq = createCompareFunction(func(n core.NumberType) bool { return n == -1 || n == 0 })

// Greater checks if arguments are aligned in ascending order or not.
var Greater = createCompareFunction(func(n core.NumberType) bool { return n == 1 })

// GreaterEq checks if arguments are aligned in ascending order or not.
var GreaterEq = createCompareFunction(func(n core.NumberType) bool { return n == 1 || n == 0 })
