import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/core/providers/portal_provider.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const _storage = FlutterSecureStorage();
  final Ref _ref;

  ThemeNotifier(this._ref, ThemeMode state) : super(state) {
    _restoreSavedTheme();
  }

  /// Restores the saved light/dark preference OFF the startup critical path.
  ///
  /// This used to be awaited in `main()` before `runApp()`, but the first
  /// FlutterSecureStorage read initialises the Android Keystore (100ms+ cold),
  /// so the window sat black until it finished and the animated splash showed
  /// up late. We start from the default (dark — the same colour as the splash)
  /// and flip only if the stored value differs, which resolves while the splash
  /// is still playing, so nothing visibly changes.
  Future<void> _restoreSavedTheme() async {
    try {
      final themeStr = await _storage.read(key: 'app_theme');
      if (themeStr == null || !mounted) return;
      // Only an explicit saved 'dark' switches away from the light default.
      final saved = themeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;
      if (state != saved) state = saved;
    } catch (_) {
      // Storage unavailable — keep the default rather than fail the launch.
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;

    final themeStr = mode == ThemeMode.light ? 'light' : 'dark';
    await _storage.write(key: 'app_theme', value: themeStr);

    // Sync with backend if possible
    try {
      final authState = _ref.read(authProvider);
      if (authState.status != AuthStatus.authenticated) return;

      final portal = _ref.read(portalProvider);
      final portalKey = _getPortalKey(portal);

      await _ref.read(apiClientProvider).updatePreferences({
        portalKey: themeStr,
      });
    } catch (e) {
      debugPrint("Theme sync failed: $e");
    }
  }

  String _getPortalKey(PortalType portal) {
    switch (portal) {
      case PortalType.guest:
        return 'guest_theme';
      case PortalType.investor:
        return 'investor_theme';
      case PortalType.cp:
        return 'cp_theme';
      case PortalType.user:
        return 'user_theme';
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  // The app launches in LIGHT mode (green showcase + cream info screens); a
  // saved preference still wins, restored asynchronously in _restoreSavedTheme.
  return ThemeNotifier(ref, ThemeMode.light);
});
