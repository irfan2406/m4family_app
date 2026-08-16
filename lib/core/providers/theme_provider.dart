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
  /// The first FlutterSecureStorage read cold-initialises the Android Keystore
  /// (100ms+), so instead of awaiting it in main() before runApp() we start
  /// from the default (light) and flip async — resolving during the splash.
  Future<void> _restoreSavedTheme() async {
    try {
      final themeStr = await _storage.read(key: 'app_theme');
      if (themeStr == null || !mounted) return;
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
      case PortalType.guest: return 'guest_theme';
      case PortalType.investor: return 'investor_theme';
      case PortalType.cp: return 'cp_theme';
      case PortalType.user: return 'user_theme';
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  // Default to the LIGHT (cream) theme — matches the Figma "M4 Web Screen"
  // home design. The moon toggle still switches to the deep-green dark theme.
  return ThemeNotifier(ref, ThemeMode.light);
});
