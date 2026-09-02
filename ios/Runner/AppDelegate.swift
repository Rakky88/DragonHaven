import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let platformChannel = FlutterMethodChannel(
      name: "nl.dragonhaven.app/platform",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    platformChannel.setMethodCallHandler { call, result in
      guard call.method == "openUrl" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let rawUrl = arguments["url"] as? String,
        let url = URL(string: rawUrl),
        let scheme = url.scheme?.lowercased(),
        scheme == "https" || scheme == "http"
      else {
        result(FlutterError(
          code: "invalid_url",
          message: "Only safe web addresses can be opened.",
          details: nil
        ))
        return
      }
      UIApplication.shared.open(url, options: [:]) { opened in
        if opened {
          result(true)
        } else {
          result(FlutterError(
            code: "open_failed",
            message: "No app could open this address.",
            details: nil
          ))
        }
      }
    }
  }
}
