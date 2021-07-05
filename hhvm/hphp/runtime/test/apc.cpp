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
#include <gtest/gtest.h>

#include <memory>
#include <cstring>

#include <folly/Format.h>

#include "hphp/runtime/base/tv-comparisons.h"
#include "hphp/runtime/base/concurrent-shared-store.h"

namespace HPHP {

//////////////////////////////////////////////////////////////////////

namespace {

using Store = ConcurrentTableSharedStore;

/*
 * Just an empty table.
 */
std::unique_ptr<Store> new_store() {
  return std::make_unique<Store>();
}

const StaticString s_key("key");
const StaticString s_key2("key2");
const StaticString s_foo("foo");
const StaticString s_value1("value1");
const StaticString s_value2("value2");

}

//////////////////////////////////////////////////////////////////////

TEST(APC, Basic) {
  auto store = new_store();

  EXPECT_EQ(store->add(s_key, Variant(s_value1), 1500, 0), true);
  EXPECT_EQ(store->exists(s_key), true);
  Variant got;
  EXPECT_EQ(store->get(s_key, got), true);
  EXPECT_TRUE(tvSame(*got.asTypedValue(),
    make_tv<KindOfPersistentString>(s_value1.get())));
  EXPECT_EQ(store->eraseKey(s_key), true);
  EXPECT_EQ(store->get(s_key, got), false);
}

TEST(APC, SetOverwrite) {
  auto store = new_store();

  store->set(s_key, Variant(s_value1), 1500, 0);
  Variant got;
  EXPECT_EQ(store->get(s_key, got), true);
  EXPECT_TRUE(tvSame(*got.asTypedValue(),
              make_tv<KindOfPersistentString>(s_value1.get())));
  store->set(s_key, Variant(s_value2), 1500, 0);
  EXPECT_EQ(store->get(s_key, got), true);
  EXPECT_TRUE(tvSame(*got.asTypedValue(),
              make_tv<KindOfPersistentString>(s_value2.get())));
}

TEST(APC, Clear) {
  auto store = new_store();

  EXPECT_EQ(store->add(s_key, Variant(s_value1), 1500, 0), true);
  EXPECT_EQ(store->add(s_key2, Variant(s_value2), 1500, 0), true);
  EXPECT_EQ(store->exists(s_key), true);
  EXPECT_EQ(store->exists(s_key2), true);
  store->clear();
  EXPECT_EQ(store->exists(s_key), false);
  EXPECT_EQ(store->exists(s_key2), false);
}

TEST(APC, IncCas) {
  auto store = new_store();
  bool found = false;

  store->set(s_key, Variant(1), 1500, 0);
  EXPECT_EQ(store->inc(s_key, 1, found), 2);
  EXPECT_TRUE(found);
  EXPECT_EQ(store->inc(s_key, 1, found), 3);
  EXPECT_TRUE(found);
  EXPECT_EQ(store->inc(s_key, 1, found), 4);
  EXPECT_TRUE(found);
  EXPECT_EQ(store->inc(s_key, 1, found), 5);
  EXPECT_TRUE(found);

  store->set(s_key, Variant(1.0), 1500, 0);
  EXPECT_EQ(store->inc(s_key, 1, found), 2);
  EXPECT_TRUE(found);
  EXPECT_EQ(store->inc(s_key, 1, found), 3);
  EXPECT_TRUE(found);
  EXPECT_EQ(store->inc(s_key, 1, found), 4);
  EXPECT_TRUE(found);
  EXPECT_EQ(store->inc(s_key, 1, found), 5);
  EXPECT_TRUE(found);

  store->set(s_key, Variant(1), 1500, 0);
  EXPECT_TRUE(store->cas(s_key, 1, 2));
  EXPECT_TRUE(store->cas(s_key, 2, 3));
  EXPECT_TRUE(store->cas(s_key, 3, 4));
  EXPECT_TRUE(store->cas(s_key, 4, 5));
  EXPECT_FALSE(store->cas(s_key, 4, 5));

  store->set(s_key, Variant(1.0), 1500, 0);
  EXPECT_TRUE(store->cas(s_key, 1, 2));
  EXPECT_TRUE(store->cas(s_key, 2, 3));
  EXPECT_TRUE(store->cas(s_key, 3, 4));
  EXPECT_TRUE(store->cas(s_key, 4, 5));
  EXPECT_FALSE(store->cas(s_key, 4, 5));

  // make sure it doesn't work on some non-doubles/ints

  store->set(s_key, Variant(s_value2), 1500, 0);
  EXPECT_EQ(store->inc(s_key, 1, found), 0);
  EXPECT_FALSE(found);
  EXPECT_FALSE(store->cas(s_key, 1, 2));
  store->eraseKey(s_key);
  EXPECT_EQ(store->inc(s_key, 1, found), 0);
  EXPECT_FALSE(found);
  EXPECT_FALSE(store->cas(s_key, 1, 2));
}

TEST(APC, SampleEntries) {
  auto store = new_store();
  // Empty store gives an empty sample.
  auto entries = store->sampleEntriesInfo(10);
  EXPECT_EQ(entries.size(), 0);
  // Single-element store results in repetition.
  store->set(s_foo, s_value1, 1500, 0);
  for (uint32_t count = 0; count <= 10; ++count) {
    entries = store->sampleEntriesInfo(count);
    EXPECT_EQ(entries.size(), count);
    for (const auto& entry : entries) {
      EXPECT_STREQ(entry.key.c_str(), "foo");
    }
  }
  // More entries.
  store->set(s_key, s_value1, 1500, 0);
  store->set(s_key2, s_value2, 1500, 0);
  for (uint32_t count = 0; count <= 10; ++count) {
    entries = store->sampleEntriesInfo(count);
    EXPECT_EQ(entries.size(), count);
    for (const auto& entry : entries) {
      EXPECT_TRUE(entry.key == std::string("foo") ||
                  entry.key == std::string("key") ||
                  entry.key == std::string("key2"));
    }
  }
}

//////////////////////////////////////////////////////////////////////

}
