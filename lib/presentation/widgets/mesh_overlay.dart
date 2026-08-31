import 'package:flutter/material.dart';

/// Faint geometric mesh, drawn top-right, matching the M4 web/Figma texture on
/// the green showcase surfaces. Purely decorative: it ignores pointers and adds
/// no layout, so it can sit behind any content.
class MeshOverlay extends StatelessWidget {
  const MeshOverlay({super.key, this.opacity = 0.07});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _MeshPainter(Colors.white.withValues(alpha: opacity)),
        ),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  const _MeshPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;
    // Figma reads the nodes, not the threads: the dots sit at nearly double
    // the line's alpha so each junction lands as a solid little circle.
    final dot = Paint()
      ..color = color.withValues(alpha: (color.a * 1.8).clamp(0.0, 1.0));

    // A triangular network anchored to the top-right corner, fading toward the
    // centre — the same signature as the Figma frames. Half-size cells at
    // double the count, so the patch covers the same corner but reads as a
    // finer weave rather than a bold lattice.
    const step = 23.0;
    const cols = 10;
    const rows = 10;
    final ox = size.width - cols * step + 8;
    for (int r = 0; r <= rows; r++) {
      for (int c = 0; c <= cols; c++) {
        final x = ox + c * step + (r.isOdd ? step / 2 : 0);
        final y = r * step + 6;
        if (x > size.width) continue;
        canvas.drawCircle(Offset(x, y), 2.0, dot);
        if (c < cols) {
          canvas.drawLine(Offset(x, y), Offset(x + step, y), line);
        }
        if (r < rows) {
          canvas.drawLine(Offset(x, y), Offset(x + step / 2, y + step), line);
          canvas.drawLine(Offset(x, y), Offset(x - step / 2, y + step), line);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_MeshPainter old) => old.color != color;
}
