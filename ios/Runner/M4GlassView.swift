import Flutter
import QuartzCore
import UIKit

/// The material and the selection for M4's glass bars, drawn by UIKit.
///
/// Flutter owns layout, glyphs, labels and every touch; this platform view
/// owns only what Flutter cannot draw — Apple's real Liquid Glass. On iOS 26+
/// that is an actual `UIGlassEffect` capsule for the track and a second glass
/// element for the selection bead, the latter inside a `UIGlassContainerEffect`
/// so the bead and the trail it leaves behind merge into one shape and pinch
/// apart as it travels. Below iOS 26 the same geometry and motion run on a
/// system material blur, which still reads as glass.
///
/// The glass is Apple's, untinted and otherwise untouched: no wash over it, no
/// tint colours of ours. Everything this view adds is geometry and motion.
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
///   • `dragBegin`    → `{ x }`      finger down: take hold of the bead
///   • `dragTo`       → `{ x }`      finger moved: the bead follows, stretching
///   • `dragEnd`      → `{ index }`  finger up: settle on that slot
///   • `hasLiquidGlass` → Bool, so Dart can tell whether the real material is live
final class M4GlassView: NSObject, FlutterPlatformView {
  // MARK: Geometry handed down from Flutter, in logical points

  private var radius: CGFloat = 32.5
  /// Bead size. Either dimension at 0 means "fill the slot, less the inset".
  private var beadWidth: CGFloat = 0
  private var beadHeight: CGFloat = 0
  /// Smallest gap the bead keeps from its slot's edges.
  private var beadInset: CGFloat = 3
  private var slotCount: Int = 5
  private var selected: Int = -1
  /// Which surface the bar floats over. Only the pre-26 painted fallback
  /// still varies with it; the real glass is the same on both.
  private var onCream: Bool = false

  /// Glyphs, in slot order, rasterised by Flutter from the same Lucide font
  /// the Android bar uses. When this is non-empty the view is a real UIKit
  /// bar: it draws its own glyphs, owns its own touches and gets Apple's
  /// interactive glass. Empty, it is a decorative surface with Flutter
  /// content and Flutter gestures on top (the segmented controls).
  private var icons: [UIImage] = []
  private var iconViews: [UIImageView] = []
  private var iconSize: CGFloat = 24
  private var activeColor: UIColor = .white
  private var inactiveColor: UIColor = UIColor.white.withAlphaComponent(0.72)
  private let haptics = UISelectionFeedbackGenerator()

  /// True when this view draws the bar itself and handles its own touches.
  private var ownsTouches: Bool { !icons.isEmpty }

  /// The slot under the finger while one is down, else nil. Drives the glyph
  /// tints so a glyph lights as the bead reaches it, not on release.
  private var heldSlot: Int?
  /// Where the finger went down, for telling a tap from a drag.
  private var touchDownX: CGFloat = 0

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

  /// Which appearance the glass renders in: matched to the surface behind it.
  ///
  /// This is what decides whether the bar reads as a lens or as paint. Glass
  /// only looks transparent when its material is close in tone to whatever is
  /// behind it — WhatsApp's bar looks almost colourless because the chat list
  /// under it is near-white, not because the glass is white. Put that same
  /// light material over M4's deep green and the contrast turns it into a
  /// pale slab you cannot see through.
  ///
  /// So: dark glass on the green showcase screens, light glass on the cream
  /// ones. Driven by the surface rather than the phone, because these are
  /// system materials that otherwise follow Dark Mode — and dark glass under
  /// deep-green glyphs on a cream screen is unreadable.
  private var surfaceStyle: UIUserInterfaceStyle { onCream ? .light : .dark }

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
    onCream = (params?["onCream"] as? NSNumber)?.boolValue ?? false
    iconSize = M4GlassView.number(params?["iconSize"]) ?? iconSize
    activeColor = M4GlassView.color(params?["activeColor"]) ?? activeColor
    inactiveColor = M4GlassView.color(params?["inactiveColor"]) ?? inactiveColor
    icons = M4GlassView.images(params?["icons"])

    root.frame = frame
    root.backgroundColor = .clear
    // A bar that draws its own glyphs takes its own touches, which is what
    // lets Apple's interactive glass respond to them. A decorative surface
    // leaves every touch to the Flutter content above it.
    root.isUserInteractionEnabled = ownsTouches
    if ownsTouches {
      // minimumPressDuration 0 reports touch-down, movement and lift, which
      // is press, drag and release without a long-press delay.
      let press = UILongPressGestureRecognizer(
        target: self,
        action: #selector(handlePress(_:))
      )
      press.minimumPressDuration = 0
      press.allowableMovement = .greatestFiniteMagnitude
      root.addGestureRecognizer(press)
    }
    root.onLayout = { [weak self] in self?.layoutSurface() }
    root.overrideUserInterfaceStyle = surfaceStyle

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
      let surface = UIVisualEffectView(effect: UIGlassEffect())
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

    // Glyphs last, so they sit above the merged glass the way the labels in
    // Apple's own tab bar do.
    for image in icons {
      let view = UIImageView(image: image.withRenderingMode(.alwaysTemplate))
      view.contentMode = .scaleAspectFit
      view.isUserInteractionEnabled = false
      beadHost?.addSubview(view)
      iconViews.append(view)
    }
    refreshIcons(animated: false)
  }

  /// Tints every glyph for the current selection. `heldSlot` wins while a
  /// finger is down, so a glyph lights as the bead reaches it.
  private func refreshIcons(animated: Bool) {
    let active = heldSlot ?? selected
    let apply = {
      for (i, view) in self.iconViews.enumerated() {
        view.tintColor = (i == active) ? self.activeColor : self.inactiveColor
      }
    }
    guard animated else { return apply() }
    UIView.transition(
      with: root,
      duration: 0.22,
      options: [.transitionCrossDissolve, .allowUserInteraction],
      animations: apply
    )
  }

  /// A selection bead: a stock glass element on iOS 26+, a lit translucent
  /// capsule below it. Also used for the trail a hand-off leaves behind.
  private func makeBead() -> UIView {
    if #available(iOS 26.0, *) {
      // `isInteractive` is deliberately off, and this was measured rather
      // than assumed: with it on, the bead turns into an opaque grey slab the
      // instant a finger lands and stays one for the whole drag — the moment
      // it most needs to read as glass. Apple's interactive glass is built to
      // brighten and solidify under a press, which suits a button and ruins a
      // travelling lens.
      let view = UIVisualEffectView(effect: UIGlassEffect())
      view.cornerConfiguration = .capsule()
      return view
    }
    let view = UIView()
    view.backgroundColor = UIColor.white
      .withAlphaComponent(onCream ? 0.58 : 0.20)
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
      let r = min(radius, bounds.height / 2)
      track?.layer.cornerRadius = r
      beadContainer?.layer.cornerRadius = r
      bead?.layer.cornerRadius = beadSize().height / 2
    }

    let slot = bounds.width / CGFloat(max(1, slotCount))
    for (i, view) in iconViews.enumerated() {
      view.bounds = CGRect(x: 0, y: 0, width: iconSize, height: iconSize)
      view.center = CGPoint(
        x: (CGFloat(i) + 0.5) * slot,
        y: bounds.midY
      )
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
    refreshIcons(animated: true)

    guard let lens = bead else { return }

    guard hasSelection else {
      // Nothing selected any more: the bead shrinks away where it stood.
      morphToken += 1
      morphing = false
      let shrunk = lens.frame
      UIView.animate(withDuration: 0.22) {
        lens.alpha = 0
        lens.frame = shrunk.insetBy(
          dx: shrunk.width * 0.3,
          dy: shrunk.height * 0.3
        )
      }
      return
    }

    let to = beadFrame(for: selected)
    lens.alpha = 1

    // No journey to make: a first selection, an un-animated push, or a tap on
    // the slot that is already current.
    guard wasSelected, animated, from != to else {
      morphToken += 1
      morphing = false
      lens.frame = to
      if !wasSelected {
        lens.frame = to.insetBy(dx: to.width * 0.3, dy: to.height * 0.3)
        UIView.animate(
          withDuration: 0.42,
          delay: 0,
          usingSpringWithDamping: 0.70,
          initialSpringVelocity: 0.4,
          options: [.beginFromCurrentState, .allowUserInteraction],
          animations: { lens.frame = to }
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
        trail.frame = from.insetBy(dx: from.width * 0.35, dy: from.height * 0.35)
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
      animations: { lens.frame = self.sunk(self.beadFrame(for: self.selected)) }
    )
  }

  /// The pressed size of a bead.
  ///
  /// Every "scale" in this view is done by frame, never by transform. A
  /// `CGAffineTransform` on a `UIVisualEffectView` makes iOS flatten it to a
  /// snapshot and drop the live material, so the bead would turn into a grey
  /// slab the moment a finger touched it — and stay one for the rest of the
  /// gesture.
  private func sunk(_ frame: CGRect) -> CGRect {
    frame.insetBy(dx: frame.width * 0.035, dy: frame.height * 0.035)
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
      animations: { lens.frame = frame }
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
        animations: { lens.frame = self.beadFrame(for: self.selected) }
      )
      return
    }

    selected = index

    guard hasSelection else {
      morphing = false
      UIView.animate(withDuration: 0.22) { lens.alpha = 0 }
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
      animations: { lens.frame = self.beadFrame(for: index) },
      completion: { [weak self] _ in
        guard let self, self.morphToken == token else { return }
        self.morphing = false
      }
    )
  }

  // MARK: - Touch

  private func slotAt(_ x: CGFloat) -> Int {
    let slot = root.bounds.width / CGFloat(max(1, slotCount))
    guard slot > 0 else { return 0 }
    return min(max(Int(x / slot), 0), slotCount - 1)
  }

  /// Press, drag and release, in one recognizer.
  ///
  /// The commit happens here rather than waiting for Flutter to echo the new
  /// index back: a round trip through the channel would put a frame or two
  /// between the finger lifting and the bead moving, which is exactly the lag
  /// a native bar is supposed to not have. Flutter is told afterwards.
  @objc private func handlePress(_ gesture: UILongPressGestureRecognizer) {
    let x = gesture.location(in: root).x

    switch gesture.state {
    case .began:
      touchDownX = x
      haptics.prepare()
      dragBegin(x: x)

    case .changed:
      guard dragging else { return }
      // A fingertip jitters a point or two on an ordinary tap, and taking the
      // bead over for that would cost the tap its morph.
      if !dragMoved && abs(x - touchDownX) < 2 { return }
      dragTo(x: x)
      let slot = slotAt(x)
      if slot != heldSlot {
        heldSlot = slot
        haptics.selectionChanged()
        refreshIcons(animated: true)
      }

    case .ended:
      let slot = slotAt(x)
      let wasDrag = dragMoved
      let previous = selected
      heldSlot = nil
      // Settles a drag on its slot; a tap it only un-sinks.
      dragEnd(index: slot)
      if !wasDrag && slot != previous {
        // The tap's own hand-off, with the full stretch and trail.
        select(index: slot, count: slotCount, animated: true)
      }
      if slot != previous {
        if !wasDrag { haptics.selectionChanged() }
        channel.invokeMethod("onSelected", arguments: slot)
      }
      refreshIcons(animated: true)

    case .cancelled, .failed:
      heldSlot = nil
      dragEnd(index: selected)
      refreshIcons(animated: true)

    default:
      break
    }
  }

  // MARK: - Style

  private func restyle(onCream: Bool) {
    guard onCream != self.onCream else { return }
    self.onCream = onCream
    root.overrideUserInterfaceStyle = surfaceStyle

    // Nothing to restyle on iOS 26: the glass is Apple's and carries no tint
    // of ours. Only the pre-26 painted fallback follows the surface.
    if #unavailable(iOS 26.0) {
      bead?.backgroundColor = UIColor.white
        .withAlphaComponent(onCream ? 0.58 : 0.20)
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
    case "setColors":
      // The glyph tints follow the surface, so they arrive after creation as
      // well as with it: the bar crosses between the green and cream screens
      // without being rebuilt.
      if let c = M4GlassView.color(args?["activeColor"]) { activeColor = c }
      if let c = M4GlassView.color(args?["inactiveColor"]) { inactiveColor = c }
      refreshIcons(animated: true)
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

  /// Dart sends colours as 0xAARRGGBB, the way `Color.value` packs them.
  private static func color(_ value: Any?) -> UIColor? {
    guard let n = value as? NSNumber else { return nil }
    let v = UInt32(truncatingIfNeeded: n.int64Value)
    return UIColor(
      red: CGFloat((v >> 16) & 0xFF) / 255,
      green: CGFloat((v >> 8) & 0xFF) / 255,
      blue: CGFloat(v & 0xFF) / 255,
      alpha: CGFloat((v >> 24) & 0xFF) / 255
    )
  }

  /// Glyph PNGs, drawn by Flutter at the screen's scale.
  private static func images(_ value: Any?) -> [UIImage] {
    guard let list = value as? [Any] else { return [] }
    return list.compactMap { item in
      let data: Data?
      if let typed = item as? FlutterStandardTypedData {
        data = typed.data
      } else {
        data = item as? Data
      }
      guard let data else { return nil }
      return UIImage(data: data, scale: UIScreen.main.scale)
    }
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
