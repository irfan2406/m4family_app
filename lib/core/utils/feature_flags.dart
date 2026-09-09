import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m4_mobile/firebase_options.dart';

/// Firebase Firestore toggle for Customer / CP / Investor login entry points.
///
/// Firebase Console → Firestore Database → document:
///   Collection: `settings`
///   Document ID: `MOO1nPAW0OFq0SSZxzJb`
///   Field: `show_login_option` (boolean)
///
/// - `true`  → show portal logins
/// - `false` → hide portal logins (use for App Review)
///
/// Firestore rules must allow public read of this document, e.g.:
///   match /settings/MOO1nPAW0OFq0SSZxzJb { allow read: if true; }
const String kFirebaseSettingsCollection = 'settings';
const String kFirebaseSettingsDocId = 'MOO1nPAW0OFq0SSZxzJb';
const String kShowLoginOptionField = 'show_login_option';

/// Default while offline / before the first successful fetch.
const bool kShowLoginOptionDefault = false;

bool _parseShowLoginOption(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    return v == 'true' || v == '1' || v == 'yes';
  }
  return kShowLoginOptionDefault;
}

dynamic _firestoreFieldValue(Map<String, dynamic>? field) {
  if (field == null) return null;
  if (field.containsKey('booleanValue')) return field['booleanValue'] == true;
  if (field.containsKey('stringValue')) return field['stringValue'];
  if (field.containsKey('integerValue')) {
    return int.tryParse('${field['integerValue']}');
  }
  if (field.containsKey('doubleValue')) return field['doubleValue'];
  return null;
}

class ShowLoginOptionNotifier extends StateNotifier<bool> {
  ShowLoginOptionNotifier() : super(kShowLoginOptionDefault) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      final url =
          'https://firestore.googleapis.com/v1/projects/${options.projectId}'
          '/databases/(default)/documents/'
          '$kFirebaseSettingsCollection/$kFirebaseSettingsDocId';

      final res = await Dio().get<Map<String, dynamic>>(
        url,
        queryParameters: {'key': options.apiKey},
        options: Options(
          receiveTimeout: const Duration(seconds: 12),
          sendTimeout: const Duration(seconds: 12),
          validateStatus: (code) => code != null && code < 500,
        ),
      );

      if (res.statusCode != 200) {
        state = kShowLoginOptionDefault;
        return;
      }

      final fields = res.data?['fields'];
      if (fields is! Map || !fields.containsKey(kShowLoginOptionField)) {
        state = kShowLoginOptionDefault;
        return;
      }
      final field = fields[kShowLoginOptionField];
      if (field is! Map) {
        state = kShowLoginOptionDefault;
        return;
      }
      state = _parseShowLoginOption(
        _firestoreFieldValue(Map<String, dynamic>.from(field)),
      );
    } catch (_) {
      // Keep last known / default.
    }
  }
}

final showLoginOptionProvider =
    StateNotifierProvider<ShowLoginOptionNotifier, bool>(
      (ref) => ShowLoginOptionNotifier(),
    );

bool watchShowLoginOption(WidgetRef ref) => ref.watch(showLoginOptionProvider);
