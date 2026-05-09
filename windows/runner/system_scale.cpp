#include "system_scale.h"

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <shellscalingapi.h>

#include <memory>

namespace waydir {

namespace {

constexpr char kMethodChannel[] = "waydir/system_scale";
constexpr char kEventChannel[] = "waydir/system_scale/events";

using MethodChannel = flutter::MethodChannel<flutter::EncodableValue>;
using EventChannel = flutter::EventChannel<flutter::EncodableValue>;
using EventSink = flutter::EventSink<flutter::EncodableValue>;

double ClampScale(double v) {
  if (!(v > 0)) return 1.0;
  if (v < 0.5) return 0.5;
  if (v > 4.0) return 4.0;
  return v;
}

}  // namespace

SystemScale& SystemScale::Instance() {
  static SystemScale s;
  return s;
}

double SystemScale::Compute() const {
  UINT dpi = 96;
  if (hwnd_) {
    dpi = GetDpiForWindow(hwnd_);
  } else {
    HDC hdc = GetDC(nullptr);
    if (hdc) {
      dpi = GetDeviceCaps(hdc, LOGPIXELSX);
      ReleaseDC(nullptr, hdc);
    }
  }
  if (dpi == 0) dpi = 96;
  // Flutter on Windows already accounts for monitor DPI in devicePixelRatio,
  // so emit 1.0 here unless we want an additional global multiplier.
  // We expose the monitor scale relative to baseline so Dart side can decide
  // (e.g. for window sizing). textScaler stays 1.0 for monitor DPI.
  return ClampScale(dpi / 96.0);
}

void SystemScale::Emit() {
  auto* sink = static_cast<EventSink*>(event_sink_);
  if (!sink) return;
  sink->Success(flutter::EncodableValue(Compute()));
}

void SystemScale::OnDpiChanged() {
  Emit();
}

void SystemScale::Register(flutter::FlutterViewController* controller,
                           HWND hwnd) {
  hwnd_ = hwnd;
  auto messenger = controller->engine()->messenger();

  auto method = new MethodChannel(
      messenger, kMethodChannel,
      &flutter::StandardMethodCodec::GetInstance());
  method_channel_ = method;
  method->SetMethodCallHandler(
      [this](const auto& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "getScale") {
          result->Success(flutter::EncodableValue(Compute()));
        } else {
          result->NotImplemented();
        }
      });

  auto events = new EventChannel(
      messenger, kEventChannel,
      &flutter::StandardMethodCodec::GetInstance());
  event_channel_ = events;
  auto handler = std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
      [this](const flutter::EncodableValue*,
             std::unique_ptr<EventSink>&& sink)
          -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
        event_sink_ = sink.release();
        Emit();
        return nullptr;
      },
      [this](const flutter::EncodableValue*)
          -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
        delete static_cast<EventSink*>(event_sink_);
        event_sink_ = nullptr;
        return nullptr;
      });
  events->SetStreamHandler(std::move(handler));
}

}  // namespace waydir
