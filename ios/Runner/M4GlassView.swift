import Flutter
import UIKit

/// Native iOS glass surface used as the background of the Flutter bottom nav.
///
/// On iOS 26+ this is the real Liquid Glass material (`UIGlassEffect`); on
/// earlier iOS it falls back to a system material blur, which still reads as
/// glass. The Flutter side draws the icons and the selection morph on top, so
/// nothing about the app's look or icons changes — only the surface material.
///
/// The iOS 26 class is looked up dynamically (`NSClassFromString`) so this file
/// compiles on any Xcode/SDK version; the real glass simply activates at
/// runtime when the OS provides it.
final class M4GlassView: NSObject, FlutterPlatformView {
  private let container = UIView()

  init(frame: CGRect, viewIdentifier _: Int64, arguments args: Any?) {
    super.init()

    let params = args as? [String: Any]
    let radius = (params?["radius"] as? NSNumber)?.doubleValue ?? 32.5

    container.frame = frame
    container.backgroundColor = .clear
    container.clipsToBounds = true
    container.layer.cornerRadius = CGFloat(radius)
    container.layer.cornerCurve = .continuous

    let effectView = UIVisualEffectView(effect: M4GlassView.glassEffect())
    effectView.frame = container.bounds
    effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    effectView.clipsToBounds = true
    effectView.layer.cornerRadius = CGFloat(radius)
    effectView.layer.cornerCurve = .continuous
    container.addSubview(effectView)
  }

  func view() -> UIView { container }

  /// Real Liquid Glass when the running OS provides it, a thin system material
  /// blur otherwise.
  private static func glassEffect() -> UIVisualEffect {
    if #available(iOS 26.0, *),
       let cls = NSClassFromString("UIGlassEffect") as? NSObject.Type,
       let glass = cls.init() as? UIVisualEffect {
      return glass
    }
    return UIBlurEffect(style: .systemThinMaterial)
  }
}

final class M4GlassViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return M4GlassView(frame: frame, viewIdentifier: viewId, arguments: args)
  }

  func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}
