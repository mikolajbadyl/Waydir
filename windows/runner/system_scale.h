#ifndef RUNNER_SYSTEM_SCALE_H_
#define RUNNER_SYSTEM_SCALE_H_

#include <flutter/flutter_view_controller.h>
#include <windows.h>

namespace waydir {

class SystemScale {
 public:
  static SystemScale& Instance();

  // Bind to engine messengers and remember the host HWND.
  void Register(flutter::FlutterViewController* controller, HWND hwnd);

  // Call from WM_DPICHANGED.
  void OnDpiChanged();

 private:
  SystemScale() = default;
  void Emit();
  double Compute() const;

  HWND hwnd_ = nullptr;
  void* method_channel_ = nullptr;   // owned, opaque
  void* event_channel_ = nullptr;    // owned, opaque
  void* event_sink_ = nullptr;       // owned, opaque
};

}  // namespace waydir

#endif  // RUNNER_SYSTEM_SCALE_H_
