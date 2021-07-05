package core

import (
	"math/rand"
	"testing"

	"github.com/stretchr/testify/assert"
)

var kvss = [][][2]Value{
	{{True, False}},
	{{Nil, NewNumber(42)}},
	{{False, NewNumber(42)}, {True, NewNumber(13)}},
	{
		{False, NewNumber(42)},
		{True, False},
		{NewNumber(2), NewString("Mr. Value")},
	},
	{
		{NewString("go"), NewList(EmptyList, Nil, NewNumber(123))},
		{False, NewNumber(42)},
		{True, False},
		{NewNumber(2), NewString("Mr. Value")},
	},
}

func TestDictionaryAssign(t *testing.T) {
	for _, c := range []struct {
		dictionary Value
		key        Value
		value      Value
		answer     Value
	}{
		{
			EmptyDictionary,
			NewString("foo"),
			Nil,
			NewDictionary([]KeyValue{{NewString("foo"), Nil}}),
		},
		{
			NewDictionary([]KeyValue{{NewString("foo"), Nil}}),
			NewString("bar"),
			Nil,
			NewDictionary([]KeyValue{{NewString("foo"), Nil}, {NewString("bar"), Nil}}),
		},
		{
			NewDictionary([]KeyValue{{NewString("foo"), Nil}}),
			NewString("foo"),
			True,
			NewDictionary([]KeyValue{{NewString("foo"), True}}),
		},
	} {
		assert.True(t, testEqual(c.answer, PApp(Assign, c.dictionary, c.key, c.value)))
	}
}

func TestDictionaryAssignKeys(t *testing.T) {
	for _, k := range []Value{
		True, False, Nil, NewNumber(42), NewString("cloe"),
	} {
		d, ok := EvalPure(PApp(Assign, EmptyDictionary, k, Nil)).(*DictionaryType)
		assert.True(t, ok)
		assert.Equal(t, 1, d.Size())
	}
}

func TestDictionaryAssignMultileKeys(t *testing.T) {
	d := Value(EmptyDictionary)

	for i, k := range []Value{
		True, False, Nil, NewNumber(42), NewString("cloe"),
	} {
		d = EvalPure(PApp(Assign, d, k, Nil))
		t.Log(EvalPure(PApp(ToString, d)))
		assert.Equal(t, i+1, d.(*DictionaryType).Size())
	}
}

func TestDictionaryAssignFail(t *testing.T) {
	l := NewList(DummyError)
	v := EvalPure(PApp(Assign, PApp(Assign, EmptyDictionary, l, Nil), l, Nil))
	_, ok := v.(*ErrorType)
	t.Logf("%#v", v)
	assert.True(t, ok)
}

func TestDictionaryIndex(t *testing.T) {
	for _, kvs := range kvss {
		d := Value(EmptyDictionary)

		for i, kv := range kvs {
			t.Logf("Assigning a %vth key...\n", i)
			d = PApp(Assign, d, kv[0], kv[1])
		}

		assert.Equal(t, len(kvs), dictionarySize(d))
		t.Log(EvalPure(PApp(ToString, d)))

		for i, kv := range kvs {
			t.Logf("Getting a %vth value...\n", i)

			k, v := kv[0], kv[1]

			t.Log(EvalPure(PApp(ToString, k)))

			if e, ok := EvalPure(PApp(Index, d, k)).(*ErrorType); ok {
				t.Log(e.Lines())
			}

			assert.True(t, testEqual(PApp(Index, d, k), v))
		}
	}
}

func TestDictionaryIndexFail(t *testing.T) {
	for _, v := range []Value{
		PApp(EmptyDictionary, Nil),
		PApp(PApp(Assign, EmptyDictionary, NewList(DummyError), Nil), NewList(Nil)),
		PApp(
			PApp(Assign, EmptyDictionary, NewList(Nil, DummyError), Nil),
			NewList(Nil, DummyError)),
	} {
		v := EvalPure(v)
		t.Logf("%#v", v)
		_, ok := v.(*ErrorType)
		assert.True(t, ok)
	}
}

func TestDictionaryDelete(t *testing.T) {
	k := NewNumber(42)
	v := EvalPure(PApp(Delete, PApp(Assign, EmptyDictionary, k, Nil), k))
	d, ok := v.(*DictionaryType)
	t.Logf("%#v", v)
	assert.True(t, ok)
	assert.Zero(t, d.Size())
}

func TestDictionaryDeleteFail(t *testing.T) {
	v := EvalPure(PApp(
		Delete,
		PApp(Assign, EmptyDictionary, NewList(DummyError), Nil),
		NewList(NewNumber(42))))
	_, ok := v.(*ErrorType)
	t.Logf("%#v", v)
	assert.True(t, ok)
}

func TestDictionaryToList(t *testing.T) {
	for i, kvs := range kvss {
		t.Log("TestDictionaryToList START", i)
		d := Value(EmptyDictionary)

		for i, kv := range kvs {
			t.Logf("Assigning a %vth key...\n", i)
			d = PApp(Assign, d, kv[0], kv[1])
		}

		assert.Equal(t, len(kvs), dictionarySize(d))

		l := PApp(ToList, d)

		for i := 0; i < len(kvs); i, l = i+1, PApp(Rest, l) {
			kv := PApp(First, l)
			k := PApp(First, kv)
			lv := PApp(First, PApp(Rest, kv))
			dv := PApp(Index, d, k)

			t.Log("Key:", EvalPure(k))
			t.Log("LIST Value:", EvalPure(lv))
			t.Log("DICT Value:", EvalPure(dv))

			assert.True(t, testEqual(lv, dv))
		}

		assert.True(t, EvalPure(l).(*ListType).Empty())
	}
}

func TestDictionaryWithDuplicateKeys(t *testing.T) {
	ks := []Value{
		True, False, Nil, NewNumber(0), NewNumber(1), NewNumber(42),
		NewNumber(2049), NewString("runner"), NewString("lisp"),
	}

	d := Value(EmptyDictionary)

	for _, i := range []int{0, 1, 2, 2, 7, 3, 0, 4, 6, 1, 1, 4, 5, 6, 0, 2, 8, 8} {
		d = PApp(Assign, d, ks[i], ks[i])
	}

	assert.Equal(t, len(ks), dictionarySize(d))

	for _, k := range ks {
		assert.True(t, testEqual(PApp(Index, d, k), k))
	}
}

func dictionarySize(d Value) int {
	return int(EvalPure(d).(*DictionaryType).Size())
}

func TestDictionaryEqual(t *testing.T) {
	kvs := [][2]Value{
		{True, Nil},
		{False, NewList(NewNumber(123))},
		{Nil, NewList(NewNumber(123), NewNumber(456))},
		{NewNumber(42), NewString("foo")},
	}

	ds := []Value{EmptyDictionary, EmptyDictionary}

	for i := range ds {
		for _, j := range rand.Perm(len(kvs)) {
			ds[i] = PApp(Assign, ds[i], kvs[j][0], kvs[j][1])
		}
	}

	assert.Equal(t, 4, dictionarySize(ds[0]))
	assert.True(t, testEqual(ds[0], ds[1]))
}

func TestDictionaryLess(t *testing.T) {
	kvs := [][2]Value{
		{True, Nil},
		{False, NewList(NewNumber(123))},
	}

	ds := []Value{EmptyDictionary, EmptyDictionary}

	for i := range ds {
		for _, j := range rand.Perm(len(kvs)) {
			ds[i] = PApp(Assign, ds[i], kvs[j][0], kvs[j][1])
		}
	}

	ds[1] = PApp(Assign, ds[1], Nil, Nil)

	assert.Equal(t, 2, dictionarySize(ds[0]))
	assert.Equal(t, 3, dictionarySize(ds[1]))
	assert.True(t, testLess(ds[0], ds[1]))
}

func TestDictionaryToString(t *testing.T) {
	for _, c := range []struct {
		expected string
		value    Value
	}{
		{"{}", EmptyDictionary},
		{"{true nil}", PApp(Assign, EmptyDictionary, True, Nil)},
		{"{true nil false nil}", PApp(Assign, PApp(Assign, EmptyDictionary, True, Nil), False, Nil)},
		{`{"foo" "bar"}`, NewDictionary([]KeyValue{{NewString("foo"), NewString("bar")}})},
	} {
		assert.Equal(t, StringType(c.expected), EvalPure(PApp(ToString, c.value)))
	}
}

func TestDictionaryStringFail(t *testing.T) {
	for _, v := range []Value{
		NewDictionary([]KeyValue{{Nil, DummyError}}),
		NewDictionary([]KeyValue{{Nil, NewList(DummyError)}}),
		NewDictionary([]KeyValue{{NewList(DummyError), Nil}}),
	} {
		v := EvalPure(PApp(ToString, v))
		t.Logf("%#v", v)
		_, ok := v.(*ErrorType)
		assert.True(t, ok)
	}
}

func TestDictionarySize(t *testing.T) {
	for _, test := range []struct {
		dictionary Value
		size       NumberType
	}{
		{EmptyDictionary, 0},
		{PApp(Assign, EmptyDictionary, True, Nil), 1},
		{PApp(Assign, PApp(Assign, EmptyDictionary, True, Nil), False, Nil), 2},
	} {
		assert.Equal(t, test.size, *EvalPure(PApp(Size, test.dictionary)).(*NumberType))
	}
}

func TestDictionaryInclude(t *testing.T) {
	for _, c := range []struct {
		dictionary Value
		key        Value
		answer     BooleanType
	}{
		{EmptyDictionary, Nil, false},
		{PApp(Assign, EmptyDictionary, False, Nil), False, true},
		{PApp(Assign, PApp(Assign, EmptyDictionary, NewNumber(42), Nil), False, Nil), NewNumber(42), true},
		{PApp(Assign, PApp(Assign, EmptyDictionary, NewNumber(42), Nil), False, Nil), NewNumber(2049), false},
	} {
		assert.Equal(t, c.answer, *EvalPure(PApp(Include, c.dictionary, c.key)).(*BooleanType))
	}
}

func TestDictionaryMerge(t *testing.T) {
	d1 := Value(EmptyDictionary)
	d2kvs := make([][2]Value, 0)

	for _, kvs := range kvss {
		d := Value(EmptyDictionary)

		for _, kv := range kvs {
			d = PApp(Assign, d, kv[0], kv[1])
		}

		d1 = PApp(Merge, d1, d)
		d2kvs = append(d2kvs, kvs...)
	}

	d2 := Value(EmptyDictionary)

	for _, kv := range d2kvs {
		d2 = PApp(Assign, d2, kv[0], kv[1])
	}

	assert.True(t, testEqual(d1, d2))
}

func TestDictionaryError(t *testing.T) {
	for _, v := range []Value{
		PApp(
			NewDictionary([]KeyValue{{DummyError, Nil}}),
			Nil),
		PApp(
			NewDictionary([]KeyValue{{Nil, Nil}}),
			DummyError),
		PApp(
			Assign,
			NewDictionary([]KeyValue{{DummyError, Nil}}),
			Nil),
		PApp(
			Assign,
			NewDictionary([]KeyValue{{Nil, Nil}}),
			DummyError),
		PApp(
			Merge,
			EmptyDictionary,
			NewDictionary([]KeyValue{{DummyError, Nil}})),
		PApp(
			Merge,
			NewDictionary([]KeyValue{{NewList(DummyError), Nil}}),
			NewDictionary([]KeyValue{{NewList(DummyError), Nil}})),
		PApp(
			Include,
			NewDictionary([]KeyValue{{DummyError, Nil}}),
			Nil),
		PApp(
			Include,
			NewDictionary([]KeyValue{{NewList(Nil), Nil}}),
			NewList(DummyError)),
		PApp(
			ToString,
			NewDictionary([]KeyValue{{DummyError, Nil}})),
		PApp(
			ToString,
			NewDictionary([]KeyValue{{Nil, DummyError}})),
		PApp(
			ToString,
			NewDictionary([]KeyValue{{NewList(DummyError), DummyError}})),
		PApp(
			Delete,
			NewDictionary([]KeyValue{{DummyError, Nil}}),
			Nil),
		PApp(
			ToList,
			NewDictionary([]KeyValue{{NewList(DummyError), Nil}})),
	} {
		v := EvalPure(v)
		t.Log(v)
		_, ok := v.(*ErrorType)
		assert.True(t, ok)
	}
}
