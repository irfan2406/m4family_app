import 'package:flutter/foundation.dart' show Factory, listEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;
import 'package:flutter/services.dart';
import 'package:m4_mobile/presentation/widgets/ios/icon_raster.dart';

/// The bottom bar as a real UIKit control.
///
/// Everything visible here is drawn by UIKit — the Liquid Glass capsule, the
/// selection bead, the glyphs — and every touch is handled there too. That is
/// the point: Apple's interactive glass only responds to touches the view
/// itself receives, so a bar with Flutter gestures on top can never have the
/// press response a system tab bar has. Handling the press natively also
/// means the bead moves on the frame the finger lifts, with no round trip
/// through the platform channel first.
///
/// Flutter's part is to supply the glyphs — rasterised from the same Lucide
/// font the Android bar uses, so the icons stay identical across platforms —
/// and to own the navigation the bar reports back.
///
/// Only iOS builds this. Android keeps its own bar, untouched.
class NativeTabBar extends StatefulWidget {
  const NativeTabBar({
    super.key,
    required this.icons,
    required this.currentIndex,
    required this.onTap,
    required this.height,
    required this.radius,
    required this.beadWidth,
    required this.beadHeight,
    required this.iconSize,
    required this.activeColor,
    required this.inactiveColor,
    this.beadInset = 3,
  });

  final List<IconData> icons;
  final int currentIndex;
  final ValueChanged<int> onTap;

  final double height;
  final double radius;
  final double beadWidth;
  final double beadHeight;
  final double beadInset;
  final double iconSize;

  /// Glyph colours for the selected and unselected slots. UIKit tints the
  /// rasters, which are drawn white for exactly that.
  final Color activeColor;
  final Color inactiveColor;

  @override
  State<NativeTabBar> createState() => _NativeTabBarState();
}

class _NativeTabBarState extends State<NativeTabBar> {
  MethodChannel? _glass;

  /// Glyph PNGs for UIKit. The platform view cannot be created until these
  /// exist, since they are creation parameters.
  List<Uint8List>? _rasters;
  double _rasterRatio = 0;

  bool _onCream = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final bool onCream = Theme.of(context).brightness == Brightness.light;
    if (onCream != _onCream) {
      _onCream = onCream;
      _glass?.invokeMethod<void>('setStyle', <String, dynamic>{
        'onCream': _onCream,
      });
    }

    final double ratio = MediaQuery.devicePixelRatioOf(context);
    if (ratio != _rasterRatio) {
      _rasterRatio = ratio;
      _rasterise(ratio);
    }
  }

  @override
  void didUpdateWidget(covariant NativeTabBar old) {
    super.didUpdateWidget(old);
    if (!listEquals(old.icons, widget.icons)) {
      _rasterise(_rasterRatio);
    }
    if (old.currentIndex != widget.currentIndex ||
        old.icons.length != widget.icons.length) {
      _pushSelection(animated: true);
    }
    if (old.activeColor != widget.activeColor ||
        old.inactiveColor != widget.inactiveColor) {
      _pushColors();
    }
  }

  Future<void> _rasterise(double ratio) async {
    final List<Uint8List> pngs = await IconRaster.all(
      widget.icons,
      size: widget.iconSize,
      devicePixelRatio: ratio,
    );
    if (!mounted) return;
    setState(() => _rasters = pngs);
  }

  void _onCreated(int id) {
    final MethodChannel channel = MethodChannel('m4/glass/$id');
    _glass = channel;
    channel.setMethodCallHandler((call) async {
      // The bar has already moved its own bead; this is the navigation.
      if (call.method == 'onSelected') {
        final int index = (call.arguments as num).toInt();
        if (index != widget.currentIndex) widget.onTap(index);
      }
      return null;
    });
    channel.invokeMethod<void>('setStyle', <String, dynamic>{
      'onCream': _onCream,
    });
    _pushColors();
    _pushSelection(animated: false);
  }

  /// UIKit holds the glyph tints, so they have to be pushed whenever the
  /// surface behind the bar changes — the colours are creation parameters,
  /// and the bar is not rebuilt when it crosses from a green screen to a
  /// cream one.
  void _pushColors() {
    _glass?.invokeMethod<void>('setColors', <String, dynamic>{
      'activeColor': widget.activeColor.toARGB32(),
      'inactiveColor': widget.inactiveColor.toARGB32(),
    });
  }

  void _pushSelection({required bool animated}) {
    _glass?.invokeMethod<void>('setSelection', <String, dynamic>{
      'index': widget.currentIndex,
      'count': widget.icons.length,
      'animated': animated,
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Uint8List>? rasters = _rasters;
    if (rasters == null) {
      // One or two frames while the glyphs rasterise. A flat capsule stands
      // in so the bar does not blink out.
      return SizedBox(
        height: widget.height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _onCream ? 0.44 : 0.10),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: UiKitView(
        viewType: 'm4/glass',
        creationParams: <String, dynamic>{
          'radius': widget.radius,
          'beadWidth': widget.beadWidth,
          'beadHeight': widget.beadHeight,
          'beadInset': widget.beadInset,
          'count': widget.icons.length,
          'index': widget.currentIndex,
          'onCream': _onCream,
          'iconSize': widget.iconSize,
          'activeColor': widget.activeColor.toARGB32(),
          'inactiveColor': widget.inactiveColor.toARGB32(),
          'icons': rasters,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onCreated,
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        // The bar takes every touch that lands on it, immediately. Without
        // this the shell's swipe-to-change-tab gesture competes for them and
        // UIKit never sees a press, so the interactive glass stays inert.
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
        },
      ),
    );
  }
}
