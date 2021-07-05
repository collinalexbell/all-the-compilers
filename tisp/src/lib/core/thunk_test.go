package core

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

var impureFunction = NewLazyFunction(
	NewSignature([]string{"x"}, "", nil, ""),
	func(vs ...Value) Value {
		return newEffect(vs[0])
	})

func TestThunkEvalWithNonFunction(t *testing.T) {
	assert.Equal(t, "TypeError", EvalPure(PApp(Nil)).(*ErrorType).Name())
}

func TestThunkEvalWithImpureFunctionCall(t *testing.T) {
	assert.Equal(t, "ImpureFunctionError", EvalPure(PApp(impureFunction, Nil)).(*ErrorType).Name())
}

func TestThunkEvalByCallingError(t *testing.T) {
	e := EvalPure(PApp(DummyError)).(*ErrorType)
	t.Log(e)
	assert.Equal(t, 1, len(e.callTrace))
}

func TestThunkEvalByCallingErrorTwice(t *testing.T) {
	e := EvalPure(PApp(PApp(DummyError))).(*ErrorType)
	t.Log(e)
	assert.Equal(t, 2, len(e.callTrace))
}

func TestThunkEvalImpure(t *testing.T) {
	s := NewString("foo")
	assert.Equal(t, s, EvalImpure(PApp(impureFunction, s)))
}

func TestThunkEvalImpureWithNonEffect(t *testing.T) {
	for _, v := range []Value{Nil, PApp(identity, Nil)} {
		v := EvalImpure(v)
		err, ok := v.(*ErrorType)
		t.Logf("%#v\n", v)
		assert.True(t, ok)
		assert.Equal(t, "TypeError", err.Name())
	}
}

func TestThunkEvalImpureWithError(t *testing.T) {
	v := EvalImpure(DummyError)
	err, ok := v.(*ErrorType)
	t.Logf("%#v\n", v)
	assert.True(t, ok)
	assert.Equal(t, "DummyError", err.Name())
}

func BenchmarkThunkEval(b *testing.B) {
	for i := 0; i < b.N; i++ {
		EvalPure(PApp(identity, NewNumber(42)))
	}
}

func BenchmarkAppWithInfo(b *testing.B) {
	for i := 0; i < b.N; i++ {
		AppWithInfo(identity, NewPositionalArguments(), nil)
	}
}

func BenchmarkPApp(b *testing.B) {
	for i := 0; i < b.N; i++ {
		PApp(identity, Nil)
	}
}

func BenchmarkMultiplePApp(b *testing.B) {
	for i := 0; i < b.N; i++ {
		f := identity
		l := EmptyList

		PApp(If,
			PApp(Equal, l, EmptyList),
			EmptyList,
			PApp(Prepend,
				PApp(f, PApp(First, l)),
				PApp(f, f, PApp(Rest, l))))
	}
}
