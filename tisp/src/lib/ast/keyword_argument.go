package ast

import "fmt"

// KeywordArgument represents a keyword argument passed to a function.
type KeywordArgument struct {
	name  string
	value interface{}
}

// NewKeywordArgument creates a keyword argument from a bound name and its value.
func NewKeywordArgument(name string, value interface{}) KeywordArgument {
	return KeywordArgument{name, value}
}

// Name returns a bound name of a keyword argument.
func (k KeywordArgument) Name() string {
	return k.name
}

// Value returns a value of a keyword argument.
func (k KeywordArgument) Value() interface{} {
	return k.value
}

func (k KeywordArgument) String() string {
	if k.name == "" {
		return fmt.Sprintf("..%v", k.value)
	}

	return fmt.Sprintf("%v %v", k.name, k.value)
}
