<?hh
/*
 *  Copyright (c) 2004-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the MIT license found in the
 *  LICENSE file in the hphp/hsl/ subdirectory of this source tree.
 *
 */

namespace HH\Lib\_Private\_OS;

use namespace HH\Lib\OS;


trait ErrnoExceptionWithSingleErrnoTrait {
  require extends OS\ErrnoException;

  final public function __construct(string $message) {
    parent::__construct(static::_getValidErrno(), $message);
  }

  abstract public static function _getValidErrno(): OS\Errno;
}
