package core

// KeywordArgument represents a keyword argument passed to a function.
type KeywordArgument struct {
	name  string // Empty strings means values are expanded.
	value Value
}

// NewKeywordArgument creates a KeywordArgument from a bound name and its value.
func NewKeywordArgument(s string, v Value) KeywordArgument {
	return KeywordArgument{s, v}
}
