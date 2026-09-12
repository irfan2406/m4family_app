import 'package:flutter/material.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

/// A no-op `webview_flutter` platform, so screens that embed a map can be
/// pumped in a widget test.
///
/// `M4MapView` builds a `WebViewController` in `initState`, and the plugin
/// asserts `WebViewPlatform.instance != null` — with no platform binding under
/// `flutter test` that assertion fires while the page is still mounting, and
/// every later expectation fails on a half-built tree. This substitutes a
/// controller that accepts calls and does nothing, and a widget that paints an
/// empty box where the map would be.
///
/// Call [installFakeWebViewPlatform] once in `setUpAll`.
void installFakeWebViewPlatform() {
  WebViewPlatform.instance = FakeWebViewPlatform();
}

class FakeWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) => _FakeWebViewController(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) => _FakeWebViewWidget(params);
}

/// Swallows the handful of calls `M4MapView` makes. The base class throws
/// `UnimplementedError` from every method, so each one used has to be answered.
class _FakeWebViewController extends PlatformWebViewController {
  _FakeWebViewController(super.params) : super.implementation();

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {}

  @override
  Future<void> loadRequest(LoadRequestParams params) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}
}

class _FakeWebViewWidget extends PlatformWebViewWidget {
  _FakeWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
