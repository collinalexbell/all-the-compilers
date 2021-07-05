package re

import (
	"testing"

	"github.com/cloe-lang/cloe/src/lib/core"
	"github.com/stretchr/testify/assert"
)

func TestReplace(t *testing.T) {
	for _, c := range []struct {
		pattern, repl, src, dest string
	}{
		{"foo", "bar", "foo", "bar"},
		{"f(.*)a", "b${1}r", "fooa", "boor"},
	} {
		s, ok := core.EvalPure(core.PApp(
			replace,
			core.NewString(c.pattern),
			core.NewString(c.repl),
			core.NewString(c.src))).(core.StringType)

		assert.True(t, ok)
		assert.Equal(t, c.dest, string(s))
	}
}

func TestReplaceError(t *testing.T) {
	for _, v := range []core.Value{
		core.PApp(replace),
		core.PApp(replace, core.NewString("foo")),
		core.PApp(replace, core.NewString("foo"), core.Nil, core.NewString("bar")),
		core.PApp(replace, core.NewString("(foo"), core.NewString("foo"), core.NewString("foo")),
	} {
		_, ok := core.EvalPure(v).(*core.ErrorType)
		assert.True(t, ok)
	}
}
