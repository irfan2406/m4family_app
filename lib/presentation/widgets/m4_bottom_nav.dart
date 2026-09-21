import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m4_mobile/core/platform/m4_platform.dart';
import 'package:m4_mobile/presentation/widgets/ios/liquid_glass.dart';
import 'package:m4_mobile/presentation/widgets/nav_style.dart';

/// THE M4 bottom navigation bar.
///
/// Every portal — guest, customer, CP, investor — renders this one widget, so
/// the bar is byte-for-byte identical everywhere. Portals only supply their own
/// icons, selected index and tap handler; nothing about the look is passed in,
/// because nothing about the look is allowed to differ.
///
/// Every measurement comes from the Figma spec (see [M4Nav]):
/// 329 × 65, radius 32.5, #FFFFFF at 10% over a 30px backdrop blur.
class M4BottomNav extends StatelessWidget {
  const M4BottomNav({
    super.key,
    required this.icons,
    required this.currentIndex,
    required this.onTap,
  });

  /// One glyph per tab, in tab order.
  final List<IconData> icons;

  /// Selected tab, or a negative value when no tab is selected.
  final int currentIndex;

  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    // iOS draws the Liquid Glass tab bar. Everything below is the Android bar,
    // unchanged.
    if (M4Platform.isIOS) {
      return _LiquidTabBar(
        icons: icons,
        currentIndex: currentIndex,
        onTap: onTap,
      );
    }

    // Figma shows a distinctly lighter frosted pill on both surfaces: a whiter
    // frost on the cream screens (clearly lighter than #D4CFBC), a subtler
    // light frost over the green showcase screens.
    final bool onCream = Theme.of(context).brightness == Brightness.light;
    final Color glass = onCream
        ? Colors.white.withValues(alpha: 0.60)
        : Colors.white.withValues(alpha: 0.14);
    final Color hairline = onCream
        ? Colors.white.withValues(alpha: 0.70)
        : Colors.white.withValues(alpha: 0.22);

    return SafeArea(
      top: false,
      // Clear the gesture bar / home indicator, then float the spec gap above
      // it, so the bar never touches the bottom edge on any device.
      child: Padding(
        // Falls back to a smaller gutter only on phones too narrow for the
        // spec width; on a standard frame the ConstrainedBox wins at 329.
        padding: const EdgeInsets.fromLTRB(16, 0, 16, M4Nav.bottomInset),
        child: Center(
          // heightFactor 1 keeps this sized to the bar. Without it, Center
          // expands to every pixel the parent offers and floats the bar into
          // the middle of the screen.
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: M4Nav.width),
            child: DecoratedBox(
              // The lift lives outside the clip, or the corners would shear it.
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(M4Nav.radius),
                boxShadow: M4Nav.shadow(true),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(M4Nav.radius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: M4Nav.blur,
                    sigmaY: M4Nav.blur,
                  ),
                  child: Container(
                    height: M4Nav.height,
                    decoration: BoxDecoration(
                      color: glass,
                      borderRadius: BorderRadius.circular(M4Nav.radius),
                      border: Border.all(color: hairline, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        icons.length,
                        // Each tab takes an equal share of the bar. The discs
                        // keep their size while they fit — the same even
                        // spacing spaceEvenly gave — and scale down only on a
                        // screen too narrow to hold five of them, instead of
                        // the last one running off the right edge.
                        (i) => Expanded(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: _M4NavTab(
                                icon: icons[i],
                                isActive: currentIndex == i,
                                onTap: () => onTap(i),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One tab: the glyph, and a soft translucent disc behind it when selected.
class _M4NavTab extends StatefulWidget {
  const _M4NavTab({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_M4NavTab> createState() => _M4NavTabState();
}

class _M4NavTabState extends State<_M4NavTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: 0.95,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Follow the surface behind the bar: green showcase screens report a dark
    // brightness, cream info screens a light one.
    final bool onCream = Theme.of(context).brightness == Brightness.light;

    // Figma active tab: a SOLID filled disc. On cream it's brand green with a
    // cream glyph; on the green showcase screens it's a cream/white disc with a
    // green glyph. Inactive glyphs are muted in the surface's foreground tone.
    final Color discColor = widget.isActive
        ? (onCream ? M4Nav.discGreen : M4Nav.glyphOnDisc)
        : Colors.transparent;
    final Color glyphColor = widget.isActive
        ? (onCream ? M4Nav.glyphOnDisc : M4Nav.discGreen)
        : (onCream
              ? M4Nav.glyphOnCream.withValues(alpha: M4Nav.inactiveOpacity)
              : M4Nav.glyphOnGreen.withValues(alpha: M4Nav.inactiveOpacity));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: M4Nav.animation,
          curve: M4Nav.curve,
          width: M4Nav.activeDisc,
          height: M4Nav.activeDisc,
          decoration: BoxDecoration(color: discColor, shape: BoxShape.circle),
          child: Center(
            child: Icon(widget.icon, size: M4Nav.iconSize, color: glyphColor),
          ),
        ),
      ),
    );
  }
}

/// iOS: the M4 bar as a Liquid Glass tab bar.
///
/// Same footprint as the Android bar — every size comes from [M4Nav] — so the
/// bottom padding each screen reserves for the bar still clears it. What
/// changes is the material and the motion: the pill is Liquid Glass, the
/// selection is a clear glass droplet that glides from tab to tab on a
/// spring, a tab sinks under the finger, and changing tab gives the iOS
/// selection haptic.
class _LiquidTabBar extends StatelessWidget {
  const _LiquidTabBar({
    required this.icons,
    required this.currentIndex,
    required this.onTap,
  });

  final List<IconData> icons;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    // Same surface rule as the Android bar: green showcase screens report a
    // dark brightness, cream info screens a light one.
    final bool onCream = Theme.of(context).brightness == Brightness.light;
    final bool hasSelection = currentIndex >= 0 && currentIndex < icons.length;

    return SafeArea(
      top: false,
      // Clears the home indicator, then floats the spec gap above it.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, M4Nav.bottomInset),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: M4Nav.width),
            child: LiquidGlass(
              borderRadius: BorderRadius.circular(M4Nav.radius),
              child: SizedBox(
                height: M4Nav.height,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final double tab = box.maxWidth / icons.length;
                    // The Android disc size, shrunk only when a five-tab bar
                    // on a narrow phone has less room than that per tab.
                    final double disc = math.min(M4Nav.activeDisc, tab - 6);
                    return Stack(
                      children: [
                        if (hasSelection)
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutBack,
                            left: currentIndex * tab + (tab - disc) / 2,
                            top: (M4Nav.height - disc) / 2,
                            width: disc,
                            height: disc,
                            child: _Droplet(onCream: onCream),
                          ),
                        Row(
                          children: [
                            for (var i = 0; i < icons.length; i++)
                              Expanded(
                                child: _LiquidTab(
                                  icon: icons[i],
                                  isActive: currentIndex == i,
                                  onCream: onCream,
                                  onTap: () {
                                    if (i != currentIndex) {
                                      HapticFeedback.selectionClick();
                                    }
                                    onTap(i);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The selected tab's droplet: a bead of the same Liquid Glass as the bar,
/// not a solid disc. It is clear, so the bar shows through it, bright along
/// its rim and lit from the top-left. On the cream screens the glass is
/// frosted brighter so the bead still reads against the cream bar.
class _Droplet extends StatelessWidget {
  const _Droplet({required this.onCream});

  final bool onCream;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _DropletPainter(onCream: onCream));
}

class _DropletPainter extends CustomPainter {
  const _DropletPainter({required this.onCream});

  final bool onCream;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final Offset centre = bounds.center;
    final double r = size.shortestSide / 2;
    Color white(double alpha) => Colors.white.withValues(alpha: alpha);

    // A soft lift, in brand green rather than black.
    canvas.drawCircle(
      centre.translate(0, 4),
      r - 2,
      Paint()
        ..color = M4Nav.discGreen.withValues(alpha: onCream ? 0.16 : 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // The glass body: clear, gathering light towards the top-left.
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.5),
          radius: 1.05,
          colors: onCream
              ? [white(0.72), white(0.30)]
              : [white(0.24), white(0.06)],
        ).createShader(bounds),
    );

    // Light pooling in the lower rim, as it does in a real bead of glass.
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.3, 0.85),
          radius: 0.6,
          colors: [white(onCream ? 0.40 : 0.16), white(0)],
        ).createShader(bounds),
    );

    // A soft sheen over the upper half.
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [white(onCream ? 0.55 : 0.20), white(0)],
        ).createShader(bounds),
    );

    // The light caught just inside the upper-left rim.
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: r - 2.4),
      math.pi * 1.05,
      math.pi * 0.5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [white(onCream ? 0.95 : 0.70), white(0)],
        ).createShader(bounds),
    );

    // The rim: bright where the light strikes, catching again low right.
    canvas.drawCircle(
      centre,
      r - 0.6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            white(0.95),
            white(onCream ? 0.30 : 0.10),
            white(onCream ? 0.80 : 0.50),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(bounds),
    );

    // On cream, a hairline of M4 ink keeps the clear bead's edge.
    if (onCream) {
      canvas.drawCircle(
        centre,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..color = M4Nav.discGreen.withValues(alpha: 0.16),
      );
    }
  }

  @override
  bool shouldRepaint(_DropletPainter old) => old.onCream != onCream;
}

/// One iOS tab: the glyph, sinking under the finger and easing to its new
/// colour when the droplet arrives.
class _LiquidTab extends StatefulWidget {
  const _LiquidTab({
    required this.icon,
    required this.isActive,
    required this.onCream,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final bool onCream;
  final VoidCallback onTap;

  @override
  State<_LiquidTab> createState() => _LiquidTabState();
}

class _LiquidTabState extends State<_LiquidTab> {
  bool _pressed = false;

  void _press(bool down) {
    if (_pressed != down) setState(() => _pressed = down);
  }

  @override
  Widget build(BuildContext context) {
    // Over the clear glass bead the selected glyph takes the ink of the
    // surface: white on the green screens, M4 green on the cream ones.
    // Unselected glyphs keep the Android bar's colours.
    final Color glyph = widget.isActive
        ? (widget.onCream ? M4Nav.discGreen : M4Nav.glyphOnGreen)
        : (widget.onCream ? M4Nav.glyphOnCream : M4Nav.glyphOnGreen).withValues(
            alpha: M4Nav.inactiveOpacity,
          );

    return Semantics(
      button: true,
      selected: widget.isActive,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.86 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: Center(
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: glyph),
              duration: M4Nav.animation,
              curve: M4Nav.curve,
              builder: (context, color, _) =>
                  Icon(widget.icon, size: M4Nav.iconSize, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
