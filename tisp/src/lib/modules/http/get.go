package http

import (
	"errors"
	"io/ioutil"
	"net/http"

	"github.com/cloe-lang/cloe/src/lib/core"
)

var get = core.NewLazyFunction(
	core.NewSignature(
		[]string{"url"}, "",
		[]core.OptionalParameter{core.NewOptionalParameter("error", core.True)}, "",
	),
	func(vs ...core.Value) core.Value {
		s, e := core.EvalString(vs[0])

		if e != nil {
			return e
		}

		r, err := http.Get(string(s))

		return handleMethodResult(r, err, vs[1])
	})

func handleMethodResult(r *http.Response, err error, errorOption core.Value) core.Value {
	if err != nil {
		return httpError(err)
	}

	bs, err := ioutil.ReadAll(r.Body)

	if err != nil {
		return httpError(err)
	}

	b, e := core.EvalBoolean(errorOption)

	if e != nil {
		return e
	}

	if b && r.StatusCode/100 != 2 {
		return httpError(errors.New("status code is not 2XX"))
	}

	if err = r.Body.Close(); err != nil {
		return httpError(err)
	}

	return core.NewDictionary([]core.KeyValue{
		{Key: core.NewString("status"), Value: core.NewNumber(float64(r.StatusCode))},
		{Key: core.NewString("body"), Value: core.NewString(string(bs))},
	})
}
