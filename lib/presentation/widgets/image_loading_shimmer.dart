import 'package:flutter/material.dart';

/// Shown in a photo's place while it downloads: a soft band of light that
/// sweeps across, so an empty card reads as "a photo is on its way" rather
/// than a dead dark box. The backend serves full-size originals that can take
/// several seconds on a phone.
///
/// Fills the space it is given (like a plain coloured placeholder did), and
/// takes no space when the space is unbounded. Follows the surface it sits
/// on — a faint white sweep on the deep-green/navy screens, a faint green one
/// on cream — and stays still when the phone asks for reduced motion.
class ImageLoadingShimmer extends StatefulWidget {
  const ImageLoadingShimmer({super.key});

  @override
  State<ImageLoadingShimmer> createState() => _ImageLoadingShimmerState();
}

class _ImageLoadingShimmerState extends State<ImageLoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _sweep.stop();
    } else if (!_sweep.isAnimating) {
      _sweep.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : const Color(0xFF0C312B);
    final base = ink.withValues(alpha: dark ? 0.06 : 0.07);
    final glow = ink.withValues(alpha: dark ? 0.16 : 0.14);

    return LimitedBox(
      maxWidth: 0,
      maxHeight: 0,
      child: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _sweep,
          builder: (context, _) {
            // The band travels from off the left edge to off the right.
            final x = -2.0 + 4.0 * _sweep.value;
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(x - 1, -0.3),
                  end: Alignment(x + 1, 0.3),
                  colors: [base, glow, base],
                  stops: const [0.25, 0.5, 0.75],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
