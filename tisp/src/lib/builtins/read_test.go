package builtins

import (
	"io/ioutil"
	"os"
	"testing"

	"github.com/cloe-lang/cloe/src/lib/core"
	"github.com/stretchr/testify/assert"
)

func TestReadWithStdin(t *testing.T) {
	assert.Equal(t, core.NewString(""), core.EvalPure(core.PApp(Read)))
}

func TestReadError(t *testing.T) {
	for _, th := range []core.Value{
		core.True,
		core.NewString("nonExistentFile"),
		core.DummyError,
		core.NewList(core.DummyError),
	} {
		_, ok := core.EvalPure(core.App(
			Read,
			core.NewArguments(nil, []core.KeywordArgument{core.NewKeywordArgument("file", th)}),
		)).(*core.ErrorType)

		assert.True(t, ok)
	}
}

func TestReadWithClosedStdin(t *testing.T) {
	f, err := ioutil.TempFile("", "")
	assert.Nil(t, err)
	err = f.Close()
	assert.Nil(t, err)
	defer os.Remove(f.Name())

	_, ok := core.EvalPure(core.PApp(createReadFunction(f))).(*core.ErrorType)
	assert.True(t, ok)
}
