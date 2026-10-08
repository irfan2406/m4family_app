import Flutter
import QuartzCore
import UIKit

/// The material and the selection for M4's glass bars, drawn by UIKit.
///
/// Flutter owns layout, glyphs, labels and every touch; this platform view owns
/// only what Flutter cannot draw — Apple's real Liquid Glass. On iOS 26+ that
/// means an actual `UIGlassEffect` capsule for the track and a second glass
/// element for the selection bead, the latter inside a `UIGlassContainerEffect`
/// so the bead and the trail it leaves behind merge into one shape and pinch
/// apart as it travels. Below iOS 26 the same geometry and motion run on a
/// system material blur, which still reads as glass.
///
/// The track and the bead are deliberately in SEPARATE containers. Glass
/// elements inside one container merge into a single shape, so a bead sharing
/// the track's container would be swallowed by it and vanish.
///
/// One view serves every glass bar — the bottom nav's round bead and the
/// segmented control's slot-filling chip — because all of it is geometry:
/// `beadWidth`/`beadHeight` of 0 mean "fill the slot".
///
/// Flutter drives it over a per-view method channel (`m4/glass/<id>`):
///   • `setSelection` → `{ index, count, animated }`
///   • `setStyle`     → `{ onCream }`
///   • `dragBegin`    → `{ x }`      finger down: grab the bead at x
///   • `dragTo`       → `{ x }`      finger moved: the bead follows, stretching
///   • `dragEnd`      → `{ index }`  finger up: settle on that slot
///   • `hasLiquidGlass` → Bool, so Dart can tell whether the real material is live
final class M4GlassView: NSObject, FlutterPlatformView {
  // MARK: Geometry and style handed down from Flutter, in logical points

  private var radius: CGFloat = 32.5
  /// Bead size. Either dimension at 0 means "fill the slot/track, less inset".
  private var beadWidth: CGFloat = 0
  private var beadHeight: CGFloat = 0
  /// Smallest gap the bead keeps from its slot's edges.
  private var beadInset: CGFloat = 3
  private var slotCount: Int = 5
  private var selected: Int = -1

  /// White-tint alphas, per surface. Every styling decision lives in Dart.
  private var barTintDark: CGFloat = 0.11
  private var barTintCream: CGFloat = 0.14
  private var beadTintDark: CGFloat = 0.24
  private var beadTintCream: CGFloat = 0.30
  private var onCream: Bool = false

  // MARK: Views

  private let root = M4NavSurface()
  private let channel: FlutterMethodChannel

  /// The track material, filling the whole view.
  private var track: UIVisualEffectView?
  /// The view added to `root` that carries the bead — the glass container on
  /// iOS 26, a plain view below it. Laid out with the track.
  private var beadContainer: UIView?
  /// Where bead subviews are actually added (a visual effect view's
  /// `contentView` is managed by UIKit and must not be positioned by hand).
  private var beadHost: UIView?
  /// The selection bead itself.
  private var bead: UIView?

  // MARK: Motion state

  /// True while a hand-off or a settle is in flight, so a layout pass does not
  /// snap the bead to its destination mid-animation.
  private var morphing = false
  /// Identifies the current hand-off, so a stale one cannot clear `morphing`
  /// out from under the hand-off that replaced it.
  private var morphToken = 0
  /// True while a finger is holding the bead.
  private var dragging = false
  /// True once that finger has actually moved it. Until then the gesture is
  /// still a tap, and a tap must keep its liquid morph.
  private var dragMoved = false
  private var dragLastX: CGFloat = 0
  private var dragLastTime: CFTimeInterval = 0
  /// Smoothed finger speed in points per second, which is what the bead's
  /// elongation is driven by.
  private var dragVelocity: CGFloat = 0

  private var hasLiquidGlass: Bool {
    if #available(iOS 26.0, *) { return true }
    return false
  }

  private var hasSelection: Bool { selected >= 0 && selected < slotCount }

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    channel = FlutterMethodChannel(
      name: "m4/glass/\(viewId)",
      binaryMessenger: messenger
    )
    super.init()

    let params = args as? [String: Any]
    radius = M4GlassView.number(params?["radius"]) ?? radius
    beadWidth = M4GlassView.number(params?["beadWidth"]) ?? beadWidth
    beadHeight = M4GlassView.number(params?["beadHeight"]) ?? beadHeight
    beadInset = M4GlassView.number(params?["beadInset"]) ?? beadInset
    slotCount = max(1, Int(M4GlassView.number(params?["count"]) ?? 5))
    selected = Int(M4GlassView.number(params?["index"]) ?? -1)
    barTintDark = M4GlassView.number(params?["barTintDark"]) ?? barTintDark
    barTintCream = M4GlassView.number(params?["barTintCream"]) ?? barTintCream
    beadTintDark = M4GlassView.number(params?["beadTintDark"]) ?? beadTintDark
    beadTintCream = M4GlassView.number(params?["beadTintCream"]) ?? beadTintCream
    onCream = (params?["onCream"] as? NSNumber)?.boolValue ?? false

    root.frame = frame
    root.backgroundColor = .clear
    // Every touch belongs to the Flutter glyphs above this view.
    root.isUserInteractionEnabled = false
    root.onLayout = { [weak self] in self?.layoutSurface() }

    build()
    layoutSurface()

    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  func view() -> UIView { root }

  // MARK: - Building

  private func build() {
    if #available(iOS 26.0, *) {
      // The track: real Liquid Glass, clear enough that the screen behind it
      // refracts through the edges instead of being frosted flat.
      let surface = UIVisualEffectView(effect: trackEffect())
      surface.cornerConfiguration = .capsule(maximumRadius: radius)
      root.addSubview(surface)
      track = surface

      // The bead's own glass container. Its merging is what turns the
      // hand-off from a sliding shape into a bead of liquid letting go.
      let container = UIGlassContainerEffect()
      // Elements merge once they are this close, so the bridge holds for most
      // of a one-slot journey.
      container.spacing = 34
      let host = UIVisualEffectView(effect: container)
      // Clipped to the track, so the bead and its own glass shadow never spill
      // outside the capsule at either end.
      host.cornerConfiguration = .capsule(maximumRadius: radius)
      host.clipsToBounds = true
      root.addSubview(host)
      beadContainer = host
      beadHost = host.contentView
    } else {
      let surface = UIVisualEffectView(
        effect: UIBlurEffect(style: .systemThinMaterial)
      )
      surface.layer.cornerCurve = .continuous
      surface.clipsToBounds = true
      root.addSubview(surface)
      track = surface

      let host = UIView()
      host.layer.cornerCurve = .continuous
      host.clipsToBounds = true
      root.addSubview(host)
      beadContainer = host
      beadHost = host
    }

    let lens = makeBead()
    beadHost?.addSubview(lens)
    lens.alpha = hasSelection ? 1 : 0
    bead = lens
  }

  @available(iOS 26.0, *)
  private func trackEffect() -> UIGlassEffect {
    let effect = UIGlassEffect(style: .clear)
    effect.tintColor = UIColor.white
      .withAlphaComponent(onCream ? barTintCream : barTintDark)
    return effect
  }

  /// A selection bead: a clear glass element on iOS 26+, a lit translucent
  /// capsule below it. Also used for the trail a hand-off leaves behind.
  private func makeBead() -> UIView {
    let alpha = onCream ? beadTintCream : beadTintDark
    if #available(iOS 26.0, *) {
      let effect = UIGlassEffect(style: .clear)
      effect.tintColor = UIColor.white.withAlphaComponent(alpha)
      let view = UIVisualEffectView(effect: effect)
      view.cornerConfiguration = .capsule()
      return view
    }
    let view = UIView()
    view.backgroundColor = UIColor.white.withAlphaComponent(alpha * 2.4)
    view.layer.borderWidth = 1
    view.layer.borderColor = UIColor.white
      .withAlphaComponent(onCream ? 0.80 : 0.38).cgColor
    view.layer.cornerCurve = .continuous
    return view
  }

  // MARK: - Layout

  private func layoutSurface() {
    let bounds = root.bounds
    guard bounds.width > 0, bounds.height > 0 else { return }

    track?.frame = bounds
    beadContainer?.frame = bounds
    if #unavailable(iOS 26.0) {
      track?.layer.cornerRadius = min(radius, bounds.height / 2)
      beadContainer?.layer.cornerRadius = min(radius, bounds.height / 2)
      bead?.layer.cornerRadius = beadSize().height / 2
    }

    // A layout pass mid-flight would yank the bead out from under the spring —
    // or out from under the finger — so leave it alone until it is free.
    if !morphing && !dragging {
      bead?.frame = beadFrame(for: selected)
    }
  }

  /// The bead at rest. A dimension passed as 0 fills the slot (or the track)
  /// less the inset, which is what turns the same view into the segmented
  /// control's slot-filling chip.
  private func beadSize() -> CGSize {
    let bounds = root.bounds
    let slot = bounds.width / CGFloat(max(1, slotCount))
    let maxW = max(0, slot - 2 * beadInset)
    let maxH = max(0, bounds.height - 2 * beadInset)
    return CGSize(
      width: beadWidth > 0 ? min(beadWidth, maxW) : maxW,
      height: beadHeight > 0 ? min(beadHeight, maxH) : maxH
    )
  }

  /// Where the bead sits at rest on `index`. Matches the Flutter row above:
  /// each slot takes an equal share of the track, content centred.
  private func beadFrame(for index: Int) -> CGRect {
    let slot = root.bounds.width / CGFloat(max(1, slotCount))
    return beadFrame(atCentre: (CGFloat(max(0, index)) + 0.5) * slot)
  }

  /// The bead at rest size, centred on `x` and kept inside the track.
  private func beadFrame(atCentre x: CGFloat) -> CGRect {
    let size = beadSize()
    return clamped(
      CGRect(
        x: x - size.width / 2,
        y: (root.bounds.height - size.height) / 2,
        width: size.width,
        height: size.height
      )
    )
  }

  /// Keeps the bead inside the track, so a finger dragged past either end
  /// pins it instead of pushing it out of the glass.
  private func clamped(_ frame: CGRect) -> CGRect {
    var f = frame
    let lower = beadInset
    let upper = max(lower, root.bounds.width - beadInset - f.width)
    f.origin.x = min(max(f.origin.x, lower), upper)
    return f
  }

  // MARK: - Selection

  private func select(index: Int, count: Int, animated: Bool) {
    // A finger owns the bead, or a drag that just committed is already
    // springing to this very slot: let that finish rather than snapping on top.
    if dragging { return }
    if index == selected && morphing { return }

    let wasSelected = hasSelection
    let from = bead?.frame ?? beadFrame(for: selected)

    slotCount = max(1, count)
    selected = index

    guard let lens = bead else { return }

    guard hasSelection else {
      // Nothing selected any more: the bead shrinks away where it stood.
      morphToken += 1
      morphing = false
      UIView.animate(withDuration: 0.22) {
        lens.alpha = 0
        lens.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
      }
      return
    }

    let to = beadFrame(for: selected)
    lens.transform = .identity
    lens.alpha = 1

    // No journey to make: a first selection, an un-animated push, or a tap on
    // the slot that is already current.
    guard wasSelected, animated, from != to else {
      morphToken += 1
      morphing = false
      lens.frame = to
      if !wasSelected {
        lens.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        UIView.animate(
          withDuration: 0.42,
          delay: 0,
          usingSpringWithDamping: 0.70,
          initialSpringVelocity: 0.4,
          options: [.beginFromCurrentState, .allowUserInteraction],
          animations: { lens.transform = .identity }
        )
      }
      return
    }

    morph(lens, from: from, to: to)
  }

  /// The hand-off: the bead reaches toward the new slot and thins the way a
  /// bead of mercury elongates, lets go of a trail that pinches off behind it,
  /// then settles on a spring.
  private func morph(_ lens: UIView, from: CGRect, to: CGRect) {
    morphing = true
    morphToken += 1
    let token = morphToken

    let rightward = to.midX >= from.midX
    // Long jumps would otherwise smear the bead across the whole track.
    let reach = min(from.union(to).width, to.width * 2.7)
    let squash = to.height * 0.88
    let stretched = clamped(
      CGRect(
        x: rightward ? from.minX : from.maxX - reach,
        y: to.midY - squash / 2,
        width: reach,
        height: squash
      )
    )

    // The trail stays behind at the old slot. While it and the bead are within
    // the container's spacing the two render as one merged shape, so the bead
    // appears to tear away from it rather than jump.
    let trail = makeBead()
    trail.frame = from
    if #unavailable(iOS 26.0) {
      trail.layer.cornerRadius = from.height / 2
    }
    beadHost?.insertSubview(trail, belowSubview: lens)

    UIView.animate(
      withDuration: 0.28,
      delay: 0,
      usingSpringWithDamping: 0.92,
      initialSpringVelocity: 0.2,
      options: [.beginFromCurrentState, .allowUserInteraction],
      animations: {
        lens.frame = stretched
        trail.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        trail.alpha = 0
      },
      completion: { _ in trail.removeFromSuperview() }
    )

    // Overlaps the stretch on purpose: UIKit blends the two springs, and that
    // blend is what keeps the shape liquid instead of stretch-then-slide.
    UIView.animate(
      withDuration: 0.48,
      delay: 0.14,
      usingSpringWithDamping: 0.76,
      initialSpringVelocity: 0.6,
      options: [.beginFromCurrentState, .allowUserInteraction],
      animations: { lens.frame = to },
      completion: { [weak self] _ in
        guard let self, self.morphToken == token else { return }
        self.morphing = false
      }
    )
  }

  // MARK: - Drag

  /// Finger down. Only the press sink: the bead stays where it is.
  ///
  /// It deliberately does NOT come to the finger here. Moving it on touch-down
  /// turns every tap into a plain slide across the track and throws away the
  /// morph — the stretch, the trail, the pinch — which is the whole effect.
  /// The bead is taken over on the first real movement instead.
  private func dragBegin(x: CGFloat) {
    guard let lens = bead, hasSelection else { return }
    dragging = true
    dragMoved = false
    dragLastX = x
    dragLastTime = CACurrentMediaTime()
    dragVelocity = 0

    UIView.animate(
      withDuration: 0.22,
      delay: 0,
      usingSpringWithDamping: 0.80,
      initialSpringVelocity: 0,
      options: [.beginFromCurrentState, .allowUserInteraction],
      animations: { lens.transform = CGAffineTransform(scaleX: 0.95, y: 0.95) }
    )
  }

  /// Finger moved. The bead chases it, elongating toward the direction of
  /// travel and thinning as it goes, then rounding out the moment it stops.
  private func dragTo(x: CGFloat) {
    guard dragging, let lens = bead else { return }

    if !dragMoved {
      // First real movement: the finger takes the bead over from whatever
      // animation had it, and outranks any hand-off still in flight.
      dragMoved = true
      morphToken += 1
      morphing = false
    }

    // The elongation is driven by SPEED, never by the delta between two
    // events. A real finger reports every 8ms or so and moves a point or two
    // at a time, so a delta-based reach collapses to nothing on a device even
    // though it looks right under coarse synthetic input — the bead slides
    // without deforming, which reads as the drag doing nothing at all.
    let now = CACurrentMediaTime()
    let dt = min(max(now - dragLastTime, 1.0 / 240.0), 1.0 / 15.0)
    let instant = (x - dragLastX) / CGFloat(dt)
    // Smoothed, so the shape does not jitter with per-frame noise, and so it
    // rounds out over a few frames once the finger stops.
    dragVelocity = dragVelocity * 0.65 + instant * 0.35
    dragLastX = x
    dragLastTime = now

    let size = beadSize()
    let cap = size.width * 1.15
    // A brisk drag — around 1200 pt/s — reaches full stretch.
    let reach = min(abs(dragVelocity) / 1200 * cap, cap)
    let width = size.width + reach
    // Thins as it elongates, the way a liquid bead does.
    let height = size.height * (1 - 0.10 * (cap > 0 ? reach / cap : 0))
    // Anchored a little behind the finger, so the trailing end lags.
    let anchor = x - (dragVelocity >= 0 ? reach * 0.22 : -reach * 0.22)
    let frame = clamped(
      CGRect(
        x: anchor - width / 2,
        y: (root.bounds.height - height) / 2,
        width: width,
        height: height
      )
    )

    // Short and linear. This lag is what reads as liquid rather than a shape
    // glued to the fingertip.
    UIView.animate(
      withDuration: 0.09,
      delay: 0,
      options: [.curveLinear, .beginFromCurrentState, .allowUserInteraction],
      animations: {
        lens.frame = frame
        lens.transform = .identity
      }
    )
  }

  /// Finger up. A drag settles onto the slot it was released over; a tap
  /// releases the sink and leaves the selection push that follows to run the
  /// full morph.
  private func dragEnd(index: Int) {
    guard let lens = bead else { return }
    let wasDrag = dragMoved
    dragging = false
    dragMoved = false

    guard wasDrag else {
      // Claiming `index` here would make the `setSelection` that follows think
      // it had nothing to do, and the morph would never run.
      UIView.animate(
        withDuration: 0.26,
        delay: 0,
        usingSpringWithDamping: 0.80,
        initialSpringVelocity: 0,
        options: [.beginFromCurrentState, .allowUserInteraction],
        animations: { lens.transform = .identity }
      )
      return
    }

    selected = index

    guard hasSelection else {
      morphing = false
      UIView.animate(withDuration: 0.22) {
        lens.alpha = 0
        lens.transform = .identity
      }
      return
    }

    morphToken += 1
    let token = morphToken
    morphing = true
    UIView.animate(
      withDuration: 0.44,
      delay: 0,
      usingSpringWithDamping: 0.74,
      initialSpringVelocity: 0.7,
      options: [.beginFromCurrentState, .allowUserInteraction],
      animations: {
        lens.transform = .identity
        lens.frame = self.beadFrame(for: index)
      },
      completion: { [weak self] _ in
        guard let self, self.morphToken == token else { return }
        self.morphing = false
      }
    )
  }

  // MARK: - Style

  private func restyle(onCream: Bool) {
    guard onCream != self.onCream else { return }
    self.onCream = onCream

    if #available(iOS 26.0, *) {
      track?.effect = trackEffect()
      if let lens = bead as? UIVisualEffectView {
        let effect = UIGlassEffect(style: .clear)
        effect.tintColor = UIColor.white
          .withAlphaComponent(onCream ? beadTintCream : beadTintDark)
        lens.effect = effect
      }
    } else {
      let alpha = onCream ? beadTintCream : beadTintDark
      bead?.backgroundColor = UIColor.white.withAlphaComponent(alpha * 2.4)
      bead?.layer.borderColor = UIColor.white
        .withAlphaComponent(onCream ? 0.80 : 0.38).cgColor
    }
  }

  // MARK: - Channel

  private func handle(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    let args = call.arguments as? [String: Any]
    switch call.method {
    case "setSelection":
      select(
        index: Int(M4GlassView.number(args?["index"]) ?? -1),
        count: Int(M4GlassView.number(args?["count"]) ?? CGFloat(slotCount)),
        animated: (args?["animated"] as? NSNumber)?.boolValue ?? true
      )
      result(nil)
    case "setStyle":
      restyle(onCream: (args?["onCream"] as? NSNumber)?.boolValue ?? false)
      result(nil)
    case "dragBegin":
      dragBegin(x: M4GlassView.number(args?["x"]) ?? 0)
      result(nil)
    case "dragTo":
      dragTo(x: M4GlassView.number(args?["x"]) ?? 0)
      result(nil)
    case "dragEnd":
      dragEnd(index: Int(M4GlassView.number(args?["index"]) ?? -1))
      result(nil)
    case "hasLiquidGlass":
      result(hasLiquidGlass)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func number(_ value: Any?) -> CGFloat? {
    guard let n = value as? NSNumber else { return nil }
    return CGFloat(n.doubleValue)
  }
}

/// A plain view that reports its layout passes, so the bar can place the glass
/// from whatever size Flutter hands the platform view.
private final class M4NavSurface: UIView {
  var onLayout: (() -> Void)?

  override func layoutSubviews() {
    super.layoutSubviews()
    onLayout?()
  }
}

// MARK: - Factory

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
    return M4GlassView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args,
      messenger: messenger
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}
