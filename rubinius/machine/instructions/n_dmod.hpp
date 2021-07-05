#include "instructions.hpp"

#include <cmath>

namespace rubinius {
  namespace instructions {
    inline void n_dmod(STATE, CF, R0, R1, R2) {
      double d = RFLT(r2);

      if(d == 0.0) {
        Exception::raise_zero_division_error(state, "divided by 0");
      }

      double n = RFLT(r1);
      double m = fmod(n, d);

      if((d < 0.0 && n > 0.0 && m != 0) ||
         (d > 0.0 && n < 0.0 && m != 0)) {
        m += d;
      }

      RFLT(r0) = m;
    }
  }
}
