import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// The single M4 map: one look everywhere it appears (contact, project detail,
/// guest project detail, CP project detail).
///
/// The embed is a Google Maps iframe inside a local HTML page — Google's
/// `?output=embed` page refuses to render as a top-level document, so it has to
/// sit in a real `<iframe>`. The greyscale filter is what makes the map read as
/// part of the M4 palette instead of a stock colour map.
class M4MapView extends StatefulWidget {
  const M4MapView({
    super.key,
    required this.query,
    required this.onOpen,
    this.height = 300,
  });

  /// Place text or address the map centres on.
  final String query;

  /// Runs when either "Open in Maps" or "OPEN MAP" is tapped.
  final VoidCallback onOpen;

  /// Card height. Defaults to the contact screen's 300.
  final double height;

  @override
  State<M4MapView> createState() => _M4MapViewState();
}

class _M4MapViewState extends State<M4MapView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadHtmlString(_html(widget.query));
  }

  static String _html(String query) {
    final src =
        'https://maps.google.com/maps?q=${Uri.encodeComponent(query)}'
        '&t=&z=13&ie=UTF8&iwloc=&output=embed';
    return '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body { margin: 0; padding: 0; overflow: hidden; }
            iframe {
              width: 100vw;
              height: 100vh;
              border: 0;
              filter: grayscale(1) contrast(1.1);
            }
          </style>
        </head>
        <body>
          <iframe
            src="$src"
            allowfullscreen
            loading="lazy"
            referrerpolicy="no-referrer-when-downgrade"
          ></iframe>
        </body>
        </html>
      ''';
  }

  @override
  Widget build(BuildContext context) {
    const Color ink = Color(0xFF163A2C);
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: ink.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ink.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _controller),
          // "Open in Maps" link, top-left.
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: widget.onOpen,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Open in Maps',
                      style: GoogleFonts.inter(
                        color: ink,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      LucideIcons.externalLink,
                      size: 12,
                      color: ink,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // "OPEN MAP" pill, bottom-centre.
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: widget.onOpen,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ink.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.mapPin, color: ink, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'OPEN MAP',
                        style: GoogleFonts.gelasio(
                          color: ink,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
