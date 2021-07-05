#include "instructions.hpp"

#include "class/bignum.hpp"

namespace rubinius {
  namespace instructions {
    inline void n_esize(STATE, CF, R0, R1) {
      RVAL(r0) = as<Bignum>(RVAL(r1))->size(state);
    }
  }
}
