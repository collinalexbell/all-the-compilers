package http

import (
	"io/ioutil"
	"net/http"
	"testing"
	"time"

	"github.com/cloe-lang/cloe/src/lib/core"
	"github.com/cloe-lang/cloe/src/lib/systemt"
	"github.com/stretchr/testify/assert"
)

func TestGetRequests(t *testing.T) {
	go systemt.RunDaemons()

	v := core.PApp(getRequests, core.NewString(":8080"))

	go core.EvalPure(v)
	time.Sleep(100 * time.Millisecond)

	rc := make(chan string)
	go func() {
		r, err := http.Get("http://127.0.0.1:8080/foo/bar?baz=123")

		assert.Nil(t, err)

		bs, err := ioutil.ReadAll(r.Body)

		assert.Nil(t, err)

		rc <- string(bs)
	}()

	_, ok := core.EvalPure(v).(*core.ListType)

	assert.True(t, ok)

	r := core.PApp(core.First, v)

	testRequest(t, r)

	v = core.PApp(
		core.PApp(core.Index, r, core.NewString("respond")),
		core.NewString("Hello, world!"))

	assert.Equal(t, core.Nil, core.EvalImpure(v))
	assert.Equal(t, "Hello, world!", <-rc)
}

func testRequest(t *testing.T, v core.Value) {
	assert.Equal(t,
		core.NewString(""),
		core.EvalPure(core.PApp(core.Index, v, core.NewString("body"))))
	assert.Equal(t,
		core.NewString("GET"),
		core.EvalPure(core.PApp(core.Index, v, core.NewString("method"))))
	assert.Equal(t,
		core.NewString("/foo/bar?baz=123"),
		core.EvalPure(core.PApp(core.Index, v, core.NewString("url"))))
}

func TestGetRequestsWithCustomStatus(t *testing.T) {
	go systemt.RunDaemons()

	v := core.PApp(getRequests, core.NewString(":8888"))

	go core.EvalPure(v)
	time.Sleep(100 * time.Millisecond)

	status := make(chan int)
	go func() {
		r, err := http.Get("http://127.0.0.1:8888/foo/bar?baz=123")

		assert.Nil(t, err)

		status <- r.StatusCode
	}()

	v = core.App(
		core.PApp(core.Index, core.PApp(core.First, v), core.NewString("respond")),
		core.NewArguments(
			[]core.PositionalArgument{core.NewPositionalArgument(core.NewString(""), false)},
			[]core.KeywordArgument{
				core.NewKeywordArgument("status", core.NewNumber(404)),
			}))

	assert.Equal(t, core.Nil, core.EvalImpure(v))
	assert.Equal(t, 404, <-status)
}

func TestGetRequestsError(t *testing.T) {
	go systemt.RunDaemons()

	_, ok := core.EvalPure(core.PApp(getRequests, core.Nil)).(*core.ErrorType)
	assert.True(t, ok)
}
