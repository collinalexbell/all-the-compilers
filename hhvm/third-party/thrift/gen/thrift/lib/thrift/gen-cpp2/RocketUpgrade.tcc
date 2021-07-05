/**
 * Autogenerated by Thrift for /home/fbthrift/thrift/lib/thrift/RocketUpgrade.thrift
 *
 * DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING
 *  @generated
 */
#pragma once

#include "thrift/lib/thrift/gen-cpp2/RocketUpgrade.h"

#include <thrift/lib/cpp2/gen/service_tcc.h>

namespace apache { namespace thrift {
typedef apache::thrift::ThriftPresult<false> RocketUpgrade_upgradeToRocket_pargs;
typedef apache::thrift::ThriftPresult<true> RocketUpgrade_upgradeToRocket_presult;
template <typename ProtocolIn_, typename ProtocolOut_>
void RocketUpgradeAsyncProcessor::setUpAndProcess_upgradeToRocket(apache::thrift::ResponseChannelRequest::UniquePtr req, apache::thrift::SerializedCompressedRequest&& serializedRequest, apache::thrift::Cpp2RequestContext* ctx, folly::EventBase* eb, apache::thrift::concurrency::ThreadManager* tm) {
  if (!setUpRequestProcessing(req, ctx, eb, tm, apache::thrift::RpcKind::SINGLE_REQUEST_SINGLE_RESPONSE, iface_)) {
    return;
  }
  auto scope = iface_->getRequestExecutionScope(ctx, apache::thrift::concurrency::NORMAL);
  ctx->setRequestExecutionScope(std::move(scope));
  processInThread(std::move(req), std::move(serializedRequest), ctx, eb, tm, apache::thrift::RpcKind::SINGLE_REQUEST_SINGLE_RESPONSE, &RocketUpgradeAsyncProcessor::process_upgradeToRocket<ProtocolIn_, ProtocolOut_>, this);
}

template <typename ProtocolIn_, typename ProtocolOut_>
void RocketUpgradeAsyncProcessor::process_upgradeToRocket(apache::thrift::ResponseChannelRequest::UniquePtr req, apache::thrift::SerializedCompressedRequest&& serializedRequest, apache::thrift::Cpp2RequestContext* ctx, folly::EventBase* eb, apache::thrift::concurrency::ThreadManager* tm) {
  // make sure getRequestContext is null
  // so async calls don't accidentally use it
  iface_->setRequestContext(nullptr);
  RocketUpgrade_upgradeToRocket_pargs args;
  std::unique_ptr<apache::thrift::ContextStack> ctxStack(this->getContextStack(this->getServiceName(), "RocketUpgrade.upgradeToRocket", ctx));
  try {
    deserializeRequest<ProtocolIn_>(args, ctx->getMethodName(), std::move(serializedRequest).uncompress(), ctxStack.get());
  }
  catch (const std::exception& ex) {
    apache::thrift::detail::ap::process_handle_exn_deserialization<ProtocolOut_>(
        ex, std::move(req), ctx, eb, "upgradeToRocket");
    return;
  }
  if (!req->getShouldStartProcessing()) {
    apache::thrift::HandlerCallbackBase::releaseRequest(std::move(req), eb);
    return;
  }
  auto callback = std::make_unique<apache::thrift::HandlerCallback<void>>(std::move(req), std::move(ctxStack), return_upgradeToRocket<ProtocolIn_,ProtocolOut_>, throw_wrapped_upgradeToRocket<ProtocolIn_, ProtocolOut_>, ctx->getProtoSeqId(), eb, tm, ctx);
  iface_->async_tm_upgradeToRocket(std::move(callback));
}

template <class ProtocolIn_, class ProtocolOut_>
folly::IOBufQueue RocketUpgradeAsyncProcessor::return_upgradeToRocket(int32_t protoSeqId, apache::thrift::ContextStack* ctx) {
  ProtocolOut_ prot;
  RocketUpgrade_upgradeToRocket_presult result;
  return serializeResponse("upgradeToRocket", &prot, protoSeqId, ctx, result);
}

template <class ProtocolIn_, class ProtocolOut_>
void RocketUpgradeAsyncProcessor::throw_wrapped_upgradeToRocket(apache::thrift::ResponseChannelRequest::UniquePtr req,int32_t protoSeqId,apache::thrift::ContextStack* ctx,folly::exception_wrapper ew,apache::thrift::Cpp2RequestContext* reqCtx) {
  if (!ew) {
    return;
  }
  {
    (void)protoSeqId;
    apache::thrift::detail::ap::process_throw_wrapped_handler_error<ProtocolOut_>(
        ew, std::move(req), reqCtx, ctx, "upgradeToRocket");
    return;
  }
}


}} // apache::thrift