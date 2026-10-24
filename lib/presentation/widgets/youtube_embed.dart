import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m4_mobile/core/utils/external_link.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// The 11-character video id in a YouTube link as admins paste it —
/// `youtu.be/ID`, `youtube.com/watch?v=ID`, `/embed/ID`, `/shorts/ID`,
/// `/live/ID`, on www/m/music hosts, with or without a scheme. Null when the
/// link is not a YouTube video.
String? youTubeVideoId(String? raw) {
  final uri = externalUri(raw);
  if (uri == null) return null;
  final host = uri.host.toLowerCase().replaceFirst(
    RegExp(r'^(www\.|m\.|music\.)'),
    '',
  );
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  String? id;
  if (host == 'youtu.be') {
    id = segments.isNotEmpty ? segments.first : null;
  } else if (host == 'youtube.com' || host == 'youtube-nocookie.com') {
    if (segments.length > 1 &&
        const {'embed', 'shorts', 'live', 'v'}.contains(segments.first)) {
      id = segments[1];
    } else {
      id = uri.queryParameters['v'];
    }
  }
  if (id == null || !RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id)) return null;
  return id;
}

/// Plays [url] inside the app when it is a YouTube video — a project's
/// walkthrough, a YouTube 360° tour — on a dark player page, instead of
/// leaving for the YouTube app. Returns false for any other link, which the
/// caller then opens exactly as before.
bool openYouTubeInApp(BuildContext context, String? url) {
  final videoId = youTubeVideoId(url);
  if (videoId == null) return false;
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => YouTubePlayerPage(videoId: videoId),
    ),
  );
  return true;
}

/// A full page for one YouTube video: black, the 16:9 player in the middle
/// and a close button. Opened by [openYouTubeInApp].
class YouTubePlayerPage extends StatelessWidget {
  const YouTubePlayerPage({super.key, required this.videoId});

  final String videoId;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: YouTubeEmbed(videoId: videoId),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Downloads a video's still ahead of time (from the list), so the player
/// can show it the instant the post opens.
void precacheYouTubeStill(BuildContext context, String? url) {
  final videoId = youTubeVideoId(url);
  if (videoId == null) return;
  precacheImage(
    CachedNetworkImageProvider(youTubeThumbnailUrl(videoId)),
    context,
    onError: (_, __) {},
  );
}

/// The page the player is served from. YouTube refuses to play an embed that
/// names no origin (its "Error 153"), so the player is hosted on the brand's
/// own site rather than an anonymous local page.
const _youTubeOrigin = 'https://m4group.in';

/// The player page. The embedded player is written straight into the page,
/// so YouTube starts loading it — and, with autoplay, playing — the moment
/// the page opens. (Creating it through YouTube's IFrame API instead waited
/// on two scripts downloaded one after the other before the player even
/// began to load.) The API is still attached, alongside, only to report
/// "ready" / "playing" (which lift the still) and to nudge playback.
String youTubePlayerPage(String id, {required bool autoplay}) {
  final ap = autoplay ? 1 : 0;
  final src =
      'https://www.youtube.com/embed/$id?enablejsapi=1&playsinline=1&rel=0'
      '&modestbranding=1&autoplay=$ap'
      '&origin=${Uri.encodeComponent(_youTubeOrigin)}';
  return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<link rel="preconnect" href="https://www.youtube.com">
<link rel="preconnect" href="https://i.ytimg.com">
<link rel="preconnect" href="https://www.google.com">
<style>
  html, body { margin: 0; padding: 0; width: 100%; height: 100%; background: #000; overflow: hidden; }
  iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0; }
</style>
</head>
<body>
<iframe id="player" src="$src"
  allow="autoplay; encrypted-media; picture-in-picture; fullscreen"
  allowfullscreen></iframe>
<script>
  function tell(m) { try { M4Player.postMessage(m); } catch (e) {} }
  function onYouTubeIframeAPIReady() {
    new YT.Player('player', {
      events: {
        onReady: function (e) {
          if ($ap) { e.target.playVideo(); }
          tell('ready');
          // Already playing by the time the API connected.
          if (e.target.getPlayerState && e.target.getPlayerState() === 1) {
            tell('playing');
          }
        },
        onStateChange: function (e) { if (e.data === 1) tell('playing'); },
        onError: function () { tell('error'); }
      }
    });
  }
</script>
<script src="https://www.youtube.com/iframe_api" async></script>
</body>
</html>
''';
}

/// Warms the in-app player once per app session, as soon as a list shows a
/// YouTube post: starts the browser engine (its first start is the biggest
/// part of a first video's delay) and fetches YouTube's player for that video
/// — without playing it — so opening the post then plays almost at once.
/// The warm-up page is let go as soon as a real player opens.
void warmUpYouTubePlayer(String? url) {
  final videoId = youTubeVideoId(url);
  if (videoId == null || _warmedUp) return;
  _warmedUp = true;
  // After the current frame, never inside a build.
  scheduleMicrotask(() {
    try {
      _warmController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadHtmlString(
          youTubePlayerPage(videoId, autoplay: false),
          baseUrl: _youTubeOrigin,
        );
    } catch (_) {
      // No web view on this platform (tests): nothing to warm.
    }
  });
}

bool _warmedUp = false;

/// Holds the warm-up page until a real player opens (see [YouTubeEmbed]).
/// Never read: it only keeps the page alive while it loads.
// ignore: unused_element
WebViewController? _warmController;

/// YouTube's own still for a video — a stand-in when an item carries no
/// uploaded picture of its own.
String youTubeThumbnailUrl(String videoId) =>
    'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

/// A YouTube video played inside the app, in YouTube's own embedded player —
/// the same player the website shows. It fills its parent; wrap it in a 16:9
/// box.
///
/// It appears at once: the video's own still (pre-downloaded by the list
/// card, see [precacheYouTubeStill]) shows with a spinner from the first
/// frame while YouTube loads and buffers behind it, and the video then starts
/// by itself, as in the YouTube app — no black box, no second tap.
///
/// The video plays in place. Anything that would leave the player — "Watch on
/// YouTube", the channel name, the YouTube logo — opens in the YouTube app (or
/// the browser when it is not installed) instead of loading inside this box.
/// The player's fullscreen button shows the video full screen in landscape.
class YouTubeEmbed extends StatefulWidget {
  const YouTubeEmbed({super.key, required this.videoId, this.autoplay = true});

  final String videoId;

  /// Start playing as soon as the player is ready.
  final bool autoplay;

  @override
  State<YouTubeEmbed> createState() => _YouTubeEmbedState();
}

class _YouTubeEmbedState extends State<YouTubeEmbed> {
  static const _origin = _youTubeOrigin;

  late final WebViewController _controller;

  /// The fullscreen page while the video is full screen.
  Route<void>? _fullscreenRoute;

  /// The still stays over the player until the video is actually playing
  /// (or, when it is not set to start by itself, until the player is ready),
  /// so buffering never shows as a black box.
  bool _playerReady = false;

  void _liftStill() {
    if (!_playerReady && mounted) setState(() => _playerReady = true);
  }

  @override
  void initState() {
    super.initState();
    // The engine and YouTube's files are warm by now; drop the hidden page.
    _warmController = null;
    // iOS: play inside the box, as on the web, instead of jumping straight
    // into the system player — and start without waiting for a second tap.
    final PlatformWebViewControllerCreationParams params =
        WebViewPlatform.instance is WebKitWebViewPlatform
        ? WebKitWebViewControllerCreationParams(
            allowsInlineMediaPlayback: true,
            mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
          )
        : const PlatformWebViewControllerCreationParams();
    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'M4Player',
        onMessageReceived: (message) {
          switch (message.message) {
            case 'playing':
            case 'error':
              _liftStill();
            case 'ready':
              if (!widget.autoplay) {
                _liftStill();
              } else {
                // Autoplay can be refused (e.g. data saver): then show the
                // player's own play button after a moment.
                Future.delayed(const Duration(seconds: 4), _liftStill);
              }
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(onNavigationRequest: _onNavigationRequest),
      )
      ..loadHtmlString(_playerPage(widget.videoId), baseUrl: _origin);

    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      // Android only shows the player's fullscreen view when the app hosts it.
      platform.setCustomWidgetCallbacks(
        onShowCustomWidget: _enterFullscreen,
        onHideCustomWidget: _exitFullscreen,
      );
      // Let the video start by itself, as in the YouTube app.
      platform.setMediaPlaybackRequiresUserGesture(false);
    }

    // Never leave the still covering the player if YouTube stays silent.
    Future.delayed(const Duration(seconds: 12), _liftStill);
  }

  @override
  void dispose() {
    if (_fullscreenRoute != null) _restoreSystemUi();
    super.dispose();
  }

  String _playerPage(String id) => youTubePlayerPage(id, autoplay: widget.autoplay);

  /// The player itself runs in a frame inside the page and loads freely. A
  /// link that would replace the page — "Watch on YouTube", the channel, the
  /// logo — is handed to the YouTube app instead.
  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final url = request.url;
    if (!request.isMainFrame ||
        url.startsWith(_origin) ||
        url.startsWith('about:') ||
        url.startsWith('data:')) {
      return NavigationDecision.navigate;
    }
    final uri = Uri.tryParse(url);
    if (uri != null) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return NavigationDecision.prevent;
  }

  void _enterFullscreen(Widget playerView, void Function() onHidden) {
    if (_fullscreenRoute != null) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    final route = PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, __, ___) => PopScope(
        // Back while full screen: tell the player it is no longer full
        // screen; it then calls _exitFullscreen, which closes this page.
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) onHidden();
        },
        child: ColoredBox(color: Colors.black, child: playerView),
      ),
    );
    _fullscreenRoute = route;
    Navigator.of(context, rootNavigator: true).push(route);
  }

  void _exitFullscreen() {
    final route = _fullscreenRoute;
    if (route == null) return;
    _fullscreenRoute = null;
    _restoreSystemUi();
    if (route.isActive) {
      Navigator.of(context, rootNavigator: true).removeRoute(route);
    }
  }

  Future<void> _restoreSystemUi() async {
    // The app's own settings: edge to edge (main.dart), any orientation.
    // Going straight from immersive back to edge-to-edge leaves Android's
    // status bar hidden (no clock or battery), so show both bars first.
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const []);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _controller),
          // The video's own still, shown instantly while YouTube loads.
          IgnorePointer(
            ignoring: _playerReady,
            child: AnimatedOpacity(
              opacity: _playerReady ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: youTubeThumbnailUrl(widget.videoId),
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (_, __) =>
                        const ColoredBox(color: Colors.black),
                    errorWidget: (_, __, ___) =>
                        const ColoredBox(color: Colors.black),
                  ),
                  const ColoredBox(color: Color(0x33000000)),
                  const Center(
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
