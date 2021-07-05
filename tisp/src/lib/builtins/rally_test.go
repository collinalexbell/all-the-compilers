package builtins

import (
	"testing"

	"github.com/cloe-lang/cloe/src/lib/core"
	"github.com/cloe-lang/cloe/src/lib/systemt"
	"github.com/stretchr/testify/assert"
)

func TestRally(t *testing.T) {
	go systemt.RunDaemons()

	ts := []core.Value{core.True, core.False, core.Nil}

	l1 := core.NewList(ts...)
	l2 := core.App(Rally, core.NewArguments(
		[]core.PositionalArgument{core.NewPositionalArgument(l1, true)},
		nil))

	for i := 0; i < len(ts); i++ {
		e := core.PApp(core.First, l2)
		t.Logf("%#v", core.EvalPure(e))
		assert.True(t, bool(*core.EvalPure(core.PApp(core.Include, l1, e)).(*core.BooleanType)))

		l1 = core.PApp(core.Delete, l1, core.PApp(index, l1, e))
		l2 = core.PApp(core.Rest, l2)
	}

	assert.True(t, bool(*core.EvalPure(core.PApp(core.Equal, core.EmptyList, l1)).(*core.BooleanType)))
	assert.True(t, bool(*core.EvalPure(core.PApp(core.Equal, core.EmptyList, l2)).(*core.BooleanType)))
}

func TestRallyError(t *testing.T) {
	go systemt.RunDaemons()

	ts := []core.Value{
		core.True,
		core.False,
		core.Nil,
		core.DummyError,
	}

	l := core.App(Rally, core.NewArguments(
		[]core.PositionalArgument{core.NewPositionalArgument(core.NewList(ts...), true)},
		nil))

	for i := 0; ; i++ {
		assert.True(t, i < len(ts))

		if _, ok := core.EvalPure(l).(*core.ErrorType); ok {
			break
		}

		l = core.PApp(core.Rest, l)
	}
}

func TestRallyInvalidArgument(t *testing.T) {
	go systemt.RunDaemons()

	_, e := core.EvalList(core.App(Rally, core.NewArguments(
		[]core.PositionalArgument{core.NewPositionalArgument(core.DummyError, true)},
		nil)))

	assert.NotNil(t, e)
}

var index = core.NewLazyFunction(
	core.NewSignature([]string{"list", "elem"}, "", nil, ""),
	func(ts ...core.Value) core.Value {
		l, e := ts[0], ts[1]

		for i := 1; ; i++ {
			if v := core.ReturnIfEmptyList(l, core.DummyError); v != nil {
				return v
			}

			v := core.EvalPure(core.PApp(core.Equal, core.PApp(core.First, l), e))
			if b, ok := v.(*core.BooleanType); !ok {
				return core.NotBooleanError(v)
			} else if *b {
				return core.NewNumber(float64(i))
			}

			l = core.PApp(core.Rest, l)
		}
	})

func TestRallyWithInvalidExpandedList(t *testing.T) {
	l := core.App(
		Rally,
		core.NewArguments(
			[]core.PositionalArgument{
				core.NewPositionalArgument(core.Nil, false),
				core.NewPositionalArgument(core.DummyError, true),
			},
			nil))

	if _, ok := core.EvalPure(l).(*core.ErrorType); !ok {
		v := core.EvalPure(core.PApp(core.Rest, l))
		_, ok := v.(*core.ErrorType)
		assert.True(t, ok)
	}
}
