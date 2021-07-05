/*
   +----------------------------------------------------------------------+
   | HipHop for PHP                                                       |
   +----------------------------------------------------------------------+
   | Copyright (c) 2010-present Facebook, Inc. (http://www.facebook.com)  |
   +----------------------------------------------------------------------+
   | This source file is subject to version 3.01 of the PHP license,      |
   | that is bundled with this package in the file LICENSE, and is        |
   | available through the world-wide-web at the following url:           |
   | http://www.php.net/license/3_01.txt                                  |
   | If you did not receive a copy of the PHP license and are unable to   |
   | obtain it through the world-wide-web, please send a note to          |
   | license@php.net so we can mail you a copy immediately.               |
   +----------------------------------------------------------------------+
*/

#pragma once

#include "hphp/runtime/base/data-walker.h"
#include "hphp/runtime/base/tv-val.h"
#include "hphp/runtime/base/typed-value.h"

namespace HPHP {

//////////////////////////////////////////////////////////////////////////////

/*
 * Global parameters for ConvertTvToUncounted and friends. Only one for now.
 * If `seen` is provided, we'll use it to de-dupe new uncounted arrays.
 */
struct MakeUncountedEnv {
  DataWalker::PointerMap* seen;
};

/*
 * Wrappers around uncounted_malloc, etc. that update APC stats.
 */
void* AllocUncounted(size_t bytes);
void FreeUncounted(void* ptr);
void FreeUncounted(void* ptr, size_t bytes);

/*
 * Converts TypedValue `tv` to an uncounted form, so that it can be shared
 * across requests. The result is either a primitive, a static value, or an
 * uncounted value. Does not dec-ref the input.
 *
 * For refcounted and uncounted inputs, this operation produces a net increase
 * of one "uncounted refcount". For refcounted inputs, it creates a new value
 * with uncounted refcount 1, and for uncounted, it does an uncountedIncRef().
 * (Primitives and statics are not refcounted in any way.)
 *
 * "hasApcTv" is a request to leave space for an APCTypedValue just before the
 * new uncounted array. We may not honor this request. For instance, if we can
 * reuse an existing persistent array, or use a static empty one, we'll do so.
 */
void ConvertTvToUncounted(tv_lval in, const MakeUncountedEnv& env);
ArrayData* MakeUncountedArray(ArrayData* in, const MakeUncountedEnv& env,
                              bool hasApcTv = false);
StringData* MakeUncountedString(StringData* in, const MakeUncountedEnv& env);

/*
 * The analogue of decRefAndRelease for an uncounted value. These helpers all
 * handle both static and uncounted values correctly. It's safe to call them
 * on any key or value of an uncounted array.
 */
void DecRefUncounted(TypedValue tv);
void DecRefUncountedArray(ArrayData* ad);
void DecRefUncountedString(StringData* sd);

//////////////////////////////////////////////////////////////////////////////

}
