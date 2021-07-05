#ifndef RBX_BUILTIN_STAT_HPP
#define RBX_BUILTIN_STAT_HPP

#include "class/object.hpp"

#include <string.h>
#include <sys/stat.h>

namespace rubinius {

  class String;
  class Fixnum;
  class Integer;
  class Time;

  class Stat : public Object {
  public:
    const static object_type type = StatType;

    attr_accessor(path, String);

  private:
    struct stat st_;

  public:
    static void bootstrap(STATE);

    static void initialize(STATE, Stat* obj) {
      obj->path(nil<String>());
      memset(&obj->st_, 0, sizeof(struct stat));
    }

    // Rubinius.primitive :stat_allocate
    static Stat* allocate(STATE, Object* self);

    // Rubinius.primitive+ :stat_stat
    Fixnum* stat(STATE, String* path);

    // Rubinius.primitive+ :stat_fstat
    Fixnum* fstat(STATE, Integer* fd);

    // Rubinius.primitive+ :stat_lstat
    Fixnum* lstat(STATE, String* path);

    // Rubinius.primitive+ :stat_dev
    Integer* stat_dev(STATE);

    // Rubinius.primitive+ :stat_ino
    Integer* stat_ino(STATE);

    // Rubinius.primitive+ :stat_mode
    Integer* stat_mode(STATE);

    // Rubinius.primitive+ :stat_nlink
    Integer* stat_nlink(STATE);

    // Rubinius.primitive+ :stat_uid
    Integer* stat_uid(STATE);

    // Rubinius.primitive+ :stat_gid
    Integer* stat_gid(STATE);

    // Rubinius.primitive+ :stat_rdev
    Integer* stat_rdev(STATE);

    // Rubinius.primitive+ :stat_size
    Integer* stat_size(STATE);

    // Rubinius.primitive+ :stat_blksize
    Integer* stat_blksize(STATE);

    // Rubinius.primitive+ :stat_blocks
    Integer* stat_blocks(STATE);

    // Rubinius.primitive+ :stat_atime
    Time* stat_atime(STATE);

    // Rubinius.primitive+ :stat_mtime
    Time* stat_mtime(STATE);

    // Rubinius.primitive+ :stat_ctime
    Time* stat_ctime(STATE);

    // Rubinius.primitive+ :stat_birthtime
    Object* stat_birthtime(STATE);

    class Info : public TypeInfo {
    public:
      BASIC_TYPEINFO(TypeInfo)
    };
  };
};

#endif
