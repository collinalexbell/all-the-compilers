package gensym

import (
	"sync"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestGenSym(t *testing.T) {
	assert.Equal(t, "$0", GenSym())
	assert.Equal(t, "$1", GenSym())
	assert.Equal(t, "$2", GenSym())
}

func TestGenSymAtomicity(t *testing.T) {
	const n = 1024

	c := make(chan string, n)
	wg := sync.WaitGroup{}

	for i := 0; i < n; i++ {
		wg.Add(1)
		go func() {
			c <- GenSym()
			wg.Done()
		}()
	}

	wg.Wait()
	close(c)

	m := make(map[string]bool)

	for s := range c {
		m[s] = true
	}

	assert.Equal(t, n, len(m))
}
