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

    // Native iOS glass surface for the bottom nav (viewType "m4/glass").
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "M4GlassView") {
      registrar.register(
        M4GlassViewFactory(messenger: registrar.messenger()),
        withId: "m4/glass"
      )
    }
  }
}
