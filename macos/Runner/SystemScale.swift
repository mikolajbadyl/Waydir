import Cocoa
import FlutterMacOS

final class SystemScale: NSObject, FlutterStreamHandler {
  static let shared = SystemScale()

  private weak var window: NSWindow?
  private var sink: FlutterEventSink?
  private var observer: NSObjectProtocol?

  func register(controller: FlutterViewController, window: NSWindow) {
    self.window = window
    let messenger = controller.engine.binaryMessenger
    let method = FlutterMethodChannel(
      name: "waydir/system_scale", binaryMessenger: messenger)
    method.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "getScale":
        result(self?.compute() ?? 1.0)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    let events = FlutterEventChannel(
      name: "waydir/system_scale/events", binaryMessenger: messenger)
    events.setStreamHandler(self)

    observer = NotificationCenter.default.addObserver(
      forName: NSWindow.didChangeBackingPropertiesNotification,
      object: window, queue: .main
    ) { [weak self] _ in
      self?.emit()
    }
  }

  private func compute() -> Double {
    let backing = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 1.0
    // Flutter on macOS uses backingScaleFactor for devicePixelRatio.
    // Emit relative scale to baseline (1.0 = standard, 2.0 = Retina).
    let v = max(0.5, min(4.0, Double(backing)))
    return v
  }

  private func emit() {
    sink?(compute())
  }

  func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    emit()
    return nil
  }

  func onCancel(withArguments _: Any?) -> FlutterError? {
    sink = nil
    return nil
  }
}
