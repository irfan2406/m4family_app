import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shown in place of a money figure while privacy mode is on. Screens keep
/// their own currency label around it ("AED ••••••", "₹ ••••••").
const String kHiddenAmount = '••••••';

/// Investor "Privacy mode" (Settings → Mask sensitive values). While on, the
/// investor's own money figures (portfolio, payments, installments, tax) are
/// shown as [kHiddenAmount].
///
/// Stored on this device per account, so it applies the moment it is saved and
/// keeps working even when the preferences endpoint cannot be read back; the
/// Settings screen also saves it to the server's `privacyMode` preference and
/// adopts the server's value when it can read one. Off for guests.
final privacyModeProvider = StateNotifierProvider<PrivacyModeNotifier, bool>((
  ref,
) {
  final userId = ref.watch(
    authProvider.select((s) => (s.user?['_id'] ?? s.user?['id'])?.toString()),
  );
  return PrivacyModeNotifier(userId);
});

class PrivacyModeNotifier extends StateNotifier<bool> {
  PrivacyModeNotifier(this._userId) : super(false) {
    _load();
  }

  final String? _userId;

  String get _key => 'privacy_mode_$_userId';

  Future<void> _load() async {
    if (_userId == null) return;
    try {
      final saved = (await SharedPreferences.getInstance()).getBool(_key);
      if (saved != null && mounted) state = saved;
    } catch (_) {
      // Unreadable storage: stay off rather than fail the screen.
    }
  }

  Future<void> set(bool value) async {
    state = value;
    if (_userId == null) return;
    try {
      await (await SharedPreferences.getInstance()).setBool(_key, value);
    } catch (_) {
      // Still applied for this session; it just won't survive a restart.
    }
  }
}
