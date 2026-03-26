import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const _storage = FlutterSecureStorage();

  ThemeNotifier(super.state);

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await _storage.write(key: 'app_theme', value: mode == ThemeMode.light ? 'light' : 'dark');
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier(ThemeMode.dark);
});
