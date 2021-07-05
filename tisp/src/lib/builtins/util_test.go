package builtins

import (
	"testing"

	"github.com/cloe-lang/cloe/src/lib/core"
	"github.com/stretchr/testify/assert"
)

func TestCheckEmptyListError(t *testing.T) {
	v := core.ReturnIfEmptyList(core.DummyError, core.Nil)
	t.Log(v)
	_, ok := v.(*core.ErrorType)
	assert.True(t, ok)
}
