package os

import "github.com/cloe-lang/cloe/src/lib/core"

// Module is a module in the language.
var Module = map[string]core.Value{
	"exit": exit,
}
