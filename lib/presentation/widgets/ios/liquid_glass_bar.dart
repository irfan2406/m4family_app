import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;
import 'package:flutter/services.dart';

/// The shared mechanics behind every M4 Liquid Glass bar — the bottom nav and
/// the segmented filter controls.
///
/// The split of work matters here. UIKit owns the *material*: the glass track
/// and the selection bead that travels between slots. Apple's Liquid Glass is a
/// private shader no Flutter paint can reproduce — it refracts the screen
/// behind it, lights its own rim, and merges two glass shapes into one as they
/// pass. Flutter owns the *layout, the content and every touch*, so each bar
/// keeps its Figma footprint and its glyphs stay identical to Android's.
///
/// Nothing is painted behind the platform view once it is up. The glass is
/// translucent by design, so a Flutter frost underneath would show straight
/// through it and flatten the material into frosted plastic — the one mistake
/// that makes a glass bar look fake.
///
/// Touch follows iOS: press anywhere on the track and the bead comes to the
/// finger and sinks, so it is held from that moment; drag and it chases the
/// finger, elongating toward the direction of travel; lift and it settles on
/// the slot it was released over. Taps are just the degenerate case of that.
class LiquidGlassBar extends StatefulWidget {
  const LiquidGlassBar({
    super.key,
    required this.slotCount,
    required this.currentIndex,
    required this.onSelected,
    required this.slotBuilder,
    required this.height,
    required this.radius,
    required this.barTintDark,
    required this.barTintCream,
    required this.beadTintDark,
    required this.beadTintCream,
    this.beadWidth = 0,
    this.beadHeight = 0,
    this.beadInset = 3,
  });

  final int slotCount;

  /// Selected slot, or a negative value when nothing is selected.
  final int currentIndex;

  final ValueChanged<int> onSelected;

  /// Builds one slot's content. `isActive` follows the *finger* while one is
  /// down, so a glyph lights up as the bead reaches it rather than on release.
  final Widget Function(BuildContext context, int index, bool isActive)
  slotBuilder;

  final double height;
  final double radius;

  /// White-tint alphas for the glass, per surface. Every styling decision
  /// lives here rather than in Swift.
  final double barTintDark;
  final double barTintCream;
  final double beadTintDark;
  final double beadTintCream;

  /// Bead size. Either dimension left at 0 means "fill the slot, less
  /// [beadInset]" — which is what turns this into a segmented control.
  final double beadWidth;
  final double beadHeight;

  /// Smallest gap the bead keeps from its slot's edges.
  final double beadInset;

  @override
  State<LiquidGlassBar> createState() => _LiquidGlassBarState();
}

class _LiquidGlassBarState extends State<LiquidGlassBar> {
  MethodChannel? _glass;

  /// True once UIKit has the bar on screen. Until then a flat capsule stands
  /// in, so the bar never blinks out while the platform view is still being
  /// composited.
  bool _live = false;

  /// Which surface the bar is floating over. The cream info screens need a
  /// brighter glass than the deep-green showcase ones.
  bool _onCream = false;

  /// The slot under the finger, or null when no finger is down.
  int? _held;

  /// True from pointer-down until this gesture has either committed a slot or
  /// put the bead back. Without it, the tap recognizer's win and the drag
  /// recognizer's rejection — which arrive together — would both act.
  bool _gestureLive = false;

  /// Last position seen during a drag; the drag-end callback has none.
  double _lastX = 0;

  /// Where the finger went down, and whether it has moved far enough since to
  /// count as a drag. A fingertip jitters a point or two on an ordinary tap,
  /// and treating that as a drag would cost the tap its morph.
  double _downX = 0;
  bool _moved = false;
  static const double _dragThreshold = 2;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fires whenever the Theme above us changes, which is exactly when the
    // surface behind the bar does.
    final bool onCream = Theme.of(context).brightness == Brightness.light;
    if (onCream == _onCream) return;
    _onCream = onCream;
    _pushStyle();
  }

  void _onCreated(int id) {
    _glass = MethodChannel('m4/glass/$id');
    _pushStyle();
    // The platform view was created with the right selection already; this
    // only covers a change that landed between creation and now.
    _pushSelection(animated: false);
    if (mounted) setState(() => _live = true);
  }

  void _pushStyle() {
    _glass?.invokeMethod<void>('setStyle', <String, dynamic>{
      'onCream': _onCream,
    });
  }

  void _pushSelection({required bool animated}) {
    _glass?.invokeMethod<void>('setSelection', <String, dynamic>{
      'index': widget.currentIndex,
      'count': widget.slotCount,
      'animated': animated,
    });
  }

  @override
  void didUpdateWidget(covariant LiquidGlassBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex ||
        old.slotCount != widget.slotCount) {
      _pushSelection(animated: true);
    }
  }

  // MARK: Touch

  int _slotAt(double x, double width) {
    final double slot = width / widget.slotCount;
    return (x / slot).floor().clamp(0, widget.slotCount - 1);
  }

  /// Finger down: the bead sinks under the finger but stays put, because this
  /// may still turn out to be a tap.
  void _down(double x, double width) {
    _gestureLive = true;
    _moved = false;
    _downX = _lastX = x.clamp(0.0, width);
    _glass?.invokeMethod<void>('dragBegin', <String, dynamic>{'x': _lastX});
  }

  void _drag(double x, double width) {
    if (!_gestureLive) return;
    _lastX = x.clamp(0.0, width);
    if (!_moved && (_lastX - _downX).abs() < _dragThreshold) return;
    _moved = true;
    _glass?.invokeMethod<void>('dragTo', <String, dynamic>{'x': _lastX});
    final int slot = _slotAt(_lastX, width);
    if (slot != _held) {
      // One tick per slot crossed, the way an iOS picker ticks.
      HapticFeedback.selectionClick();
      setState(() => _held = slot);
    }
  }

  /// Finger up: commit the slot it was released over. A drag has the bead
  /// there already; a tap leaves it to travel, and the morph carries it.
  void _commit(double x, double width) {
    if (!_gestureLive) return;
    _gestureLive = false;
    final bool wasDrag = _moved;
    _moved = false;
    final int slot = _slotAt(
      (wasDrag ? _lastX : _downX).clamp(0.0, width),
      width,
    );
    if (_held != null) setState(() => _held = null);
    _glass?.invokeMethod<void>('dragEnd', <String, dynamic>{'index': slot});
    if (slot != widget.currentIndex) {
      // A drag has already ticked its way across the slots.
      if (!wasDrag) HapticFeedback.selectionClick();
      widget.onSelected(slot);
    }
  }

  /// The gesture was lost — to a scrollable above us, or to the pointer being
  /// cancelled. Put the bead back where the real selection is.
  void _revert() {
    if (!_gestureLive) return;
    _gestureLive = false;
    _moved = false;
    if (_held != null) setState(() => _held = null);
    _glass?.invokeMethod<void>('dragEnd', <String, dynamic>{
      'index': widget.currentIndex,
    });
  }

  @override
  Widget build(BuildContext context) {
    final int active = _held ?? widget.currentIndex;

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, box) {
          final double width = box.maxWidth;
          return RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: <Type, GestureRecognizerFactory>{
              _BarPanRecognizer:
                  GestureRecognizerFactoryWithHandlers<_BarPanRecognizer>(
                    () => _BarPanRecognizer(debugOwner: this),
                    (r) {
                      // Starting at touch-down rather than after the slop is
                      // what makes the bead follow from the first pixel. A tap
                      // is then just a drag of zero length, so one recognizer
                      // covers both and they can never disagree.
                      r.dragStartBehavior = DragStartBehavior.down;
                      r.onStart = (d) => _down(d.localPosition.dx, width);
                      r.onUpdate = (d) => _drag(d.localPosition.dx, width);
                      // DragEndDetails carries no position, so settle on the
                      // last one an update reported.
                      r.onEnd = (_) => _commit(_lastX, width);
                      r.onCancel = _revert;
                    },
                  ),
            },
            child: Stack(
              children: [
                // Stand-in for the frames before UIKit composites. Swapped out
                // rather than cross-faded: fading it would tint the glass on
                // the way out, which is the look being avoided.
                if (!_live)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: _onCream ? 0.44 : 0.10,
                      ),
                      borderRadius: BorderRadius.circular(widget.radius),
                    ),
                  ),
                // Apple's Liquid Glass: the track and the selection bead.
                Positioned.fill(
                  child: _NativeGlass(
                    radius: widget.radius,
                    beadWidth: widget.beadWidth,
                    beadHeight: widget.beadHeight,
                    beadInset: widget.beadInset,
                    count: widget.slotCount,
                    index: widget.currentIndex,
                    onCream: _onCream,
                    barTintDark: widget.barTintDark,
                    barTintCream: widget.barTintCream,
                    beadTintDark: widget.beadTintDark,
                    beadTintCream: widget.beadTintCream,
                    onCreated: _onCreated,
                  ),
                ),
                // Content, above the glass. Touches are handled by the one
                // detector around the whole bar, so no slot takes its own.
                Row(
                  children: [
                    for (var i = 0; i < widget.slotCount; i++)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: widget.currentIndex == i,
                          // The bar's own detector cannot be reached by an
                          // assistive tap, so each slot carries the action.
                          onTap: () => widget.onSelected(i),
                          child: Center(
                            child: widget.slotBuilder(context, i, active == i),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The native glass surface: real Liquid Glass on iOS 26+, a system material
/// blur with the same geometry and motion below it. Only ever built on iOS.
class _NativeGlass extends StatelessWidget {
  const _NativeGlass({
    required this.radius,
    required this.beadWidth,
    required this.beadHeight,
    required this.beadInset,
    required this.count,
    required this.index,
    required this.onCream,
    required this.barTintDark,
    required this.barTintCream,
    required this.beadTintDark,
    required this.beadTintCream,
    required this.onCreated,
  });

  final double radius;
  final double beadWidth;
  final double beadHeight;
  final double beadInset;
  final int count;
  final int index;
  final bool onCream;
  final double barTintDark;
  final double barTintCream;
  final double beadTintDark;
  final double beadTintCream;
  final ValueChanged<int> onCreated;

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: 'm4/glass',
      creationParams: <String, dynamic>{
        'radius': radius,
        'beadWidth': beadWidth,
        'beadHeight': beadHeight,
        'beadInset': beadInset,
        'count': count,
        'index': index,
        'onCream': onCream,
        'barTintDark': barTintDark,
        'barTintCream': barTintCream,
        'beadTintDark': beadTintDark,
        'beadTintCream': beadTintCream,
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: onCreated,
      // The glass is decorative; touches belong to the Flutter layer above it.
      hitTestBehavior: PlatformViewHitTestBehavior.transparent,
    );
  }
}

/// A pan recognizer that claims any touch landing on the bar.
///
/// Two reasons to take the pointer at once instead of letting the arena
/// decide. The shell wraps every page in a swipe-to-change-tab gesture
/// (`NavSwipe`), and a bar the finger is actually on must never lose to it.
/// And waiting for the arena means waiting out the 18px touch slop, which
/// leaves a dead zone at the start of every drag — the bead sitting still
/// under a finger that is already moving. On a short control like the
/// segmented filter that dead zone is most of the gesture, which reads as the
/// drag not working at all.
class _BarPanRecognizer extends PanGestureRecognizer {
  _BarPanRecognizer({super.debugOwner});

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}
