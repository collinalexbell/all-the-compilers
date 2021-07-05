#ifndef RBX_BUG_HPP
#define RBX_BUG_HPP

#include <sys/types.h>

#ifndef NORETURN
#define NORETURN(x) __attribute__ ((noreturn)) x
#endif

namespace rubinius {
  NORETURN(void bug(void));
  NORETURN(void bug(const char* message));
  NORETURN(void bug(const char* message, const char* arg));
  void warn(const char* message);
  void print_backtrace(size_t max=100);
}

#endif
