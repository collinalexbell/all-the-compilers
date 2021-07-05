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

#include "hphp/runtime/base/bespoke-runtime.h"
#include "hphp/runtime/base/array-data-defs.h"

#include "hphp/runtime/base/bespoke/struct-dict.h"

#include <algorithm>

namespace HPHP {

TRACE_SET_MOD(bespoke);

//////////////////////////////////////////////////////////////////////////////

using bespoke::StructDict;

namespace {
using StrToRSMap = folly::F14FastMap<const StringData*, RuntimeStruct*>;

StrToRSMap s_runtimeStrMap;
folly::SharedMutex s_mapLock;
}

RuntimeStruct::RuntimeStruct(
    const StringData* stableIdentifier,
    const FieldIndexVector& fields,
    size_t fieldsLength)
  : m_profile(nullptr)
  , m_stableIdentifier(stableIdentifier)
  , m_fields(fieldsLength, nullptr)
  , m_assignedLayout(nullptr)
{
  assertx(stableIdentifier->isStatic());

  for (auto const [idx, key] : fields) {
    setKey(idx, key.get());
  }
}

RuntimeStruct::RuntimeStruct(
    const StringData* stableIdentifier, FieldKeys&& fields)
  : m_profile(nullptr)
  , m_stableIdentifier(stableIdentifier)
  , m_fields(fields.size(), nullptr)
  , m_assignedLayout(nullptr)
{
  assertx(stableIdentifier->isStatic());

  for (auto idx = 0; idx < fields.size(); idx++) {
    auto const key = fields[idx];
    if (key) setKey(idx, key);
  }
}

RuntimeStruct* RuntimeStruct::registerRuntimeStruct(
    const String& stableIdentifier, const FieldIndexVector& fields) {
  assertx(stableIdentifier.get()->isStatic());

  if (!allowBespokeArrayLikes()) return nullptr;

  if (Trace::moduleEnabled(Trace::bespoke, 2)) {
    FTRACE(2, "Register runtime struct {}\n", stableIdentifier);
    for (auto const [idx, str] : fields) {
      FTRACE(2, "  {} -> {}\n", idx, str);
    }
  }

  {
    folly::SharedMutex::ReadHolder lock{s_mapLock};
    auto it = s_runtimeStrMap.find(stableIdentifier.get());
    if (it != s_runtimeStrMap.end()) {
      auto const runtimeStruct = it->second;
      lock.unlock();
      // Validate that the fields provided in the query match the registered
      // fields to avoid catastrophic index mismatches.
      runtimeStruct->validateFieldsMatch(fields);
      return runtimeStruct;
    }
  }

  if (Trace::moduleEnabled(Trace::bespoke, 2)) {
    FTRACE(2, "Register new runtime struct {}\n", stableIdentifier);
    for (auto const [idx, str] : fields) {
      FTRACE(2, "  {} -> {}\n", idx, str);
    }
  }

  // Validate that no keys are subject to intish cast.
  for (auto const [_, str] : fields) {
    int64_t i;
    if (str.get()->isStrictlyInteger(i)) return nullptr;
  }

  // The fields are not contiguous, so find out how many we need to allocate.
  auto fieldsLength = 0;
  for (auto const [idx, _] : fields) {
    if (idx >= fieldsLength) fieldsLength = idx + 1;
  }

  folly::SharedMutex::WriteHolder lock{s_mapLock};
  auto const pair = s_runtimeStrMap.emplace(stableIdentifier.get(), nullptr);
  if (!pair.second) return pair.first->second;

  auto const mem = allocate(fieldsLength);
  auto const rs = new (mem) RuntimeStruct(
      stableIdentifier.get(), fields, fieldsLength);
  pair.first->second = rs;
  return rs;
}

void RuntimeStruct::validateFieldsMatch(const FieldIndexVector& fields) const {
  SCOPE_ASSERT_DETAIL("RuntimeStruct::validateFieldsMatch") {
    std::string ret =
      folly::sformat("Field mismatch for struct {}\n", m_stableIdentifier);
    ret += "Existing schema:\n";
    for (size_t i = 0; i < m_fields.size(); i++) {
      auto const key = getKey(i);
      if (key) ret += folly::sformat("  {}: {}\n", i, key);
    }
    ret += "New schema:\n";
    auto newSchema = FieldIndexVector(fields);
    std::sort(newSchema.begin(), newSchema.end());
    for (auto const [idx, str] : newSchema) {
      ret += folly::sformat("  {}: {}\n", idx, str);
    }
    return ret;
  };

  auto numFields = 0;
  for (auto const key : m_fields) {
    if (key) numFields++;
  }
  always_assert(numFields == fields.size());
  for (auto const [idx, str] : fields) {
    always_assert(getKey(idx)->same(str.get()));
  }
}

RuntimeStruct* RuntimeStruct::allocate(size_t fieldsLength) {
  static_assert(alignof(RuntimeStruct) % alignof(Slot) == 0);

  // TODO(kshaunak): We should use vm_malloc here, but it looks bad on perf.
  auto const bytes = sizeof(RuntimeStruct) + fieldsLength * sizeof(Slot);
  auto const rs = reinterpret_cast<RuntimeStruct*>(malloc(bytes));

  for (auto i = 0; i < fieldsLength; i++) {
    reinterpret_cast<Slot*>(rs + 1)[i] = kInvalidSlot;
  }
  return rs;
}

LowStringPtr RuntimeStruct::getKey(size_t idx) const {
  assertx(idx < m_fields.size());
  return m_fields[idx];
}

Slot RuntimeStruct::getSlot(size_t idx) const {
  assertx(idx < m_fields.size());
  return reinterpret_cast<const Slot*>(this + 1)[idx];
}

void RuntimeStruct::setKey(size_t idx, StringData* key) {
  always_assert(key->isStatic());
  assertx(getKey(idx) == nullptr);
  assertx(getSlot(idx) == kInvalidSlot);
  m_fields[idx] = key;
}

void RuntimeStruct::setSlot(size_t idx, Slot slot) {
  assertx(getKey(idx) != nullptr);
  assertx(getSlot(idx) == kInvalidSlot);
  reinterpret_cast<Slot*>(this + 1)[idx] = slot;
}

RuntimeStruct* RuntimeStruct::deserialize(
    const StringData* stableIdentifier, FieldKeys&& fields) {
  assertx(allowBespokeArrayLikes());
  auto const mem = allocate(fields.size());
  auto const rs = new (mem) RuntimeStruct(stableIdentifier, std::move(fields));
  s_runtimeStrMap.emplace(stableIdentifier, rs);
  return rs;
}

RuntimeStruct* RuntimeStruct::findById(const StringData* stableIdentifier) {
  assertx(allowBespokeArrayLikes());
  assertx(stableIdentifier->isStatic());

  folly::SharedMutex::ReadHolder lock{s_mapLock};
  auto const runtimeStruct = s_runtimeStrMap[stableIdentifier];
  assertx(runtimeStruct);
  return runtimeStruct;
}

void RuntimeStruct::eachRuntimeStruct(std::function<void(RuntimeStruct*)> fn) {
  assertx(allowBespokeArrayLikes());

  folly::SharedMutex::ReadHolder lock{s_mapLock};
  for (auto& it : s_runtimeStrMap) fn(it.second);
}

void RuntimeStruct::applyLayout(const bespoke::StructLayout* layout) {
  for (size_t i = 0; i < m_fields.size(); i++) {
    auto const key = getKey(i);
    if (key) setSlot(i, layout->keySlot(key));
  }
  m_assignedLayout.store(layout, std::memory_order_release);
}

const StringData* RuntimeStruct::toString() const {
  return m_stableIdentifier;
}

const StringData* RuntimeStruct::getStableIdentifier() const {
  return m_stableIdentifier;
}

size_t RuntimeStruct::stableHash() const {
  return m_stableIdentifier->hashStatic();
}

//////////////////////////////////////////////////////////////////////////////

StructDictInit::StructDictInit(RuntimeStruct* structHandle, size_t n) {
  m_struct = structHandle;
  if (allowBespokeArrayLikes() && structHandle) {
    auto const layout =
      structHandle->m_assignedLayout.load(std::memory_order_acquire);

    if (layout) {
      // We have been assigned a layout; use it for the initializer.
      m_arr = StructDict::MakeEmpty(layout);
      assertx(n <= std::numeric_limits<uint32_t>::max());
      m_escalateCapacity = static_cast<uint32_t>(n);
      m_vanilla = false;
      return;
    }
  }

  m_arr = MixedArray::MakeReserveDict(n);
  m_vanilla = true;
}

StructDictInit::~StructDictInit() {
  if (!m_arr) return;

  assertx(m_arr->hasExactlyOneRef());
  m_arr->release();
}

void StructDictInit::set(size_t idx, StringData* key, TypedValue value) {
  value = tvToInit(value);

  if (m_vanilla) {
    assertx(m_arr->isVanilla());
    // We have a vanilla MixedArray that must be properly sized. Set the
    // field in place.
    auto const DEBUG_ONLY res =
      MixedArray::SetStrInPlace(m_arr, key, value);
    assertx(res == m_arr);
    return;
  }

  // We are currently wrapping a StructDict.
  assertx(m_struct->getKey(idx)->same(key));
  auto const sad = StructDict::As(m_arr);
  auto const slot = m_struct->getSlot(idx);
  if (slot == kInvalidSlot) {
    // We are adding a key with no corresponding slot. This must escalate to
    // vanilla, so escalate with the requested capacity and clear the m_struct
    // field.
    FTRACE(2, "StructDictInit set at key {}, escalate\n", key);
    m_arr = sad->escalateWithCapacity(m_escalateCapacity, "StructDictInit");
    StructDict::Release(sad);
    assertx(m_arr->isVanillaDict());
    m_struct = nullptr;
    m_vanilla = true;

    auto const DEBUG_ONLY res =
      MixedArray::SetStrInPlace(m_arr, key, value);
    assertx(res == m_arr);
  } else {
    // We are adding a key with a known slot. This can be done in place.
    FTRACE(2, "StructDictInit set at key {}, slot {}\n", key, slot);
    if (debug) {
      // Validate that the slot translation is correct.
      auto const DEBUG_ONLY layout =
        m_struct->m_assignedLayout.load(std::memory_order_acquire);
      assertx(layout->field(slot).key->same(key));
    }
    tvIncRefGen(value);
    StructDict::SetStrInSlotInPlace(sad, slot, value);
  }
}

void StructDictInit::set(size_t idx, const String& key, TypedValue value) {
  set(idx, key.get(), value);
}

void StructDictInit::set(size_t idx, const String& key, const Variant& value) {
  set(idx, key, *value.asTypedValue());
}

void StructDictInit::set(int64_t key, TypedValue value) {
  value = tvToInit(value);

  if (m_vanilla) {
    assertx(m_arr->isVanilla());
    // We have a vanilla MixedArray that must be properly sized. Set the
    // field in place.
    auto const DEBUG_ONLY res =
      MixedArray::SetIntInPlace(m_arr, key, value);
    assertx(res == m_arr);
    return;
  }

  FTRACE(2, "StructDictInit set at integer key {}, escalate\n", key);
  auto const sad = StructDict::As(m_arr);
  m_arr = sad->escalateWithCapacity(m_escalateCapacity, "StructDictInit");
  StructDict::Release(sad);
  assertx(m_arr->isVanillaDict());
  m_struct = nullptr;
  m_vanilla = true;

  auto const DEBUG_ONLY res = MixedArray::SetIntInPlace(m_arr, key, value);
  assertx(res == m_arr);
}

void StructDictInit::set(int64_t key, const Variant& value) {
  set(key, *value.asTypedValue());
}

void StructDictInit::setIntishCast(size_t idx, const String& key,
                                   const Variant& value) {
  if (m_struct) {
    // No keys registered with a RuntimeStruct will ever intish cast.
    DEBUG_ONLY int64_t n;
    assertx(!key.get()->isStrictlyInteger(n));
    set(idx, key.get(), *value.asTypedValue());
    return;
  }

  int64_t n;
  if (ArrayData::IntishCastKey(key.get(), n)) {
    set(n, value);
  } else {
    set(idx, key.get(), *value.asTypedValue());
  }
}

Variant StructDictInit::toVariant() {
  assertx(m_arr->hasExactlyOneRef());
  assertx(m_arr->isDictType());
  if (m_vanilla && m_struct) {
    m_arr = bespoke::maybeMakeLoggingArray(m_arr, m_struct);
  }
  auto const ptr = m_arr;
  m_arr = nullptr;
  return Variant(ptr, KindOfDict, Variant::ArrayInitCtor{});
}

Array StructDictInit::toArray() {
  assertx(m_arr->hasExactlyOneRef());
  assertx(m_arr->isDictType());
  if (m_vanilla && m_struct) {
    m_arr = bespoke::maybeMakeLoggingArray(m_arr, m_struct);
  }
  auto const ptr = m_arr;
  m_arr = nullptr;
  return Array(ptr, Array::ArrayInitCtor::Tag);
}

}
