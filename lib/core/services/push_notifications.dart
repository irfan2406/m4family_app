import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart' show Response;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Phone pop-up notifications through Firebase Cloud Messaging (project
/// `m4core`), per the backend's contract:
///
/// * after sign-in (and on launch with a saved session) the phone's token is
///   sent with `POST /api/devices`, and again whenever FCM rotates it;
/// * at logout / account deletion it is removed with `DELETE /api/devices`
///   and then deleted locally, so the next person on this phone gets a fresh
///   one;
/// * pop-ups arriving while the app is open are shown on channel
///   [channelId] (Firebase only draws them itself while the app is closed);
///   on iPhone the system banner shows them instead
///   (`setForegroundNotificationPresentationOptions`);
/// * a tapped pop-up is handed to [setTapHandler] — app open, in the
///   background, or launched from it.
///
/// The Riverpod / router side lives in `PushNotificationsScope`.
class PushNotifications {
  PushNotifications._();

  /// Android channel the backend sends to (also the manifest default).
  static const channelId = 'm4_default';
  static const _channelName = 'M4 Family';
  static const _channelDescription =
      'Support replies, birthday wishes and announcements';
  static const _icon = 'ic_stat_m4';

  /// iOS config: `ios/Runner/GoogleService-Info.plist` (bundled via the Xcode
  /// project), Runner.entitlements (aps-environment) and Background Modes ›
  /// Remote notifications in Info.plist; the APNs key lives in Firebase.
  /// Firebase must not start without the plist, so this is the off switch.
  static const _iosConfigured = true;

  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;
  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static bool get _supported {
    if (kIsWeb) return false;
    return _isAndroid || (_isIOS && _iosConfigured);
  }

  static String get _platform => _isIOS ? 'ios' : 'android';

  static final _local = FlutterLocalNotificationsPlugin();
  static Future<bool>? _ready;

  static void Function(Map<String, dynamic> data)? _onTap;
  static void Function(Map<String, dynamic> data)? _onForeground;
  static void Function()? _onTokenRefresh;
  static Map<String, dynamic>? _pendingTap;

  /// Starts Firebase once. Safe to call repeatedly; never throws — a failure
  /// only means no pop-ups, the rest of the app is unaffected.
  static Future<bool> start() => _ready ??= _start();

  static Future<bool> _start() async {
    if (!_supported) return false;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;

      // The backend sends DATA-ONLY messages (no `notification` block), so
      // Android does not draw them while the app is backgrounded or killed —
      // this handler does, in its own isolate. Registered before the first
      // message can arrive.
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Local notifications are Android-only: they draw the pop-up while the
      // app is open. iPhone never needs them, and leaving them out keeps
      // Firebase the only owner of iOS notification taps.
      if (_isAndroid) {
        await _local.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings(_icon),
          ),
          onDidReceiveNotificationResponse: (r) => _tapped(_decode(r.payload)),
        );
        await _local
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(
              const AndroidNotificationChannel(
                channelId,
                _channelName,
                description: _channelDescription,
                importance: Importance.high,
              ),
            );
      }
      // iPhone shows its own banner while the app is open.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _tapped(m.data));
      messaging.onTokenRefresh.listen((_) => _onTokenRefresh?.call());

      // Launched by tapping a pop-up: Firebase's own (app was closed) or one
      // of ours (shown while open, tapped after the app was closed).
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _tapped(initial.data);
      } else if (_isAndroid) {
        final launch = await _local.getNotificationAppLaunchDetails();
        if (launch?.didNotificationLaunchApp ?? false) {
          _tapped(_decode(launch!.notificationResponse?.payload));
        }
      }

      if (kDebugMode) {
        // On iPhone the token only exists once Apple has issued its APNs
        // token, so it may not be ready yet — that must not count as failure.
        try {
          final token = await messaging.getToken();
          debugPrint('[push] Firebase ready, FCM token: $token');
        } catch (e) {
          debugPrint('[push] Firebase ready, no FCM token yet: $e');
        }
      }
      return true;
    } catch (e) {
      debugPrint('[push] Firebase unavailable: $e');
      return false;
    }
  }

  /// Where a tapped pop-up goes. A tap that arrives before a handler is set
  /// (the app launched from it) is kept and delivered on registration.
  static void setTapHandler(void Function(Map<String, dynamic> data)? onTap) {
    _onTap = onTap;
    final pending = _pendingTap;
    if (onTap != null && pending != null) {
      _pendingTap = null;
      onTap(pending);
    }
  }

  /// Called for every pop-up that arrives while the app is open.
  static void setForegroundHandler(
    void Function(Map<String, dynamic> data)? onMessage,
  ) => _onForeground = onMessage;

  /// Called when FCM rotates this phone's token.
  static void setTokenRefreshHandler(void Function()? onRefresh) =>
      _onTokenRefresh = onRefresh;

  /// Simulates a tapped pop-up (tests).
  @visibleForTesting
  static void debugTap(Map<String, dynamic> data) => _tapped(data);

  static void _tapped(Map<String, dynamic> data) {
    final handler = _onTap;
    if (handler == null) {
      _pendingTap = data;
    } else {
      handler(data);
    }
  }

  static Map<String, dynamic> _decode(String? payload) {
    if (payload == null || payload.isEmpty) return {};
    try {
      final v = jsonDecode(payload);
      return v is Map ? Map<String, dynamic>.from(v) : {};
    } catch (_) {
      return {};
    }
  }

  static Future<void> _showForeground(RemoteMessage m) async {
    _onForeground?.call(m.data);
    if (!_isAndroid) return;
    final title = m.notification?.title ?? m.data['title']?.toString();
    final body = m.notification?.body ?? m.data['body']?.toString();
    if ((title ?? '').isEmpty && (body ?? '').isEmpty) return;
    try {
      await _local.show(
        // Android ids are 32-bit.
        id:
            (m.messageId ?? '${DateTime.now().microsecondsSinceEpoch}')
                .hashCode &
            0x7fffffff,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: _icon,
            styleInformation: BigTextStyleInformation(body ?? ''),
          ),
        ),
        payload: jsonEncode(m.data),
      );
    } catch (e) {
      debugPrint('[push] could not show pop-up: $e');
    }
  }

  // Register / unregister run one at a time, so a quick logout → login on
  // the same phone can never interleave and delete the new user's token.
  static Future<void> _queue = Future.value();
  static Future<T> _serial<T>(Future<T> Function() task) {
    final run = _queue.then((_) => task());
    _queue = run.then((_) {}, onError: (_) {});
    return run;
  }

  /// True once this phone was removed (logout / account deletion) and not
  /// registered again — a second removal then has nothing to do.
  static bool _removed = false;

  /// Asks for permission (Android 13+ / iOS) and sends this phone's token to
  /// the server. Returns false when it could not be sent.
  static Future<bool> register(ApiClient api) => _serial(() async {
    if (!await start()) return false;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      if (_isIOS) {
        // FCM can only issue a token after Apple hands the phone its APNs
        // token, which arrives shortly after launch. Wait up to 10 s; if it
        // is still missing, getToken throws and the scope retries on resume.
        for (var i = 0; i < 20 && await messaging.getAPNSToken() == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return false;
      final info = await PackageInfo.fromPlatform();
      await api.registerDevice(
        token: token,
        platform: _platform,
        appVersion: '${info.version}+${info.buildNumber}',
      );
      _removed = false;
      debugPrint('[push] phone registered');
      return true;
    } catch (e) {
      debugPrint('[push] register failed: $e');
      return false;
    }
  });

  /// Account deletion: removes this phone first (the session dies with the
  /// account), and registers it again if the deletion did not go through.
  static Future<Response> deleteAccount(
    ApiClient api,
    Future<Response> Function() delete,
  ) async {
    await unregister(api);
    try {
      final res = await delete();
      final body = res.data;
      final failed =
          (res.statusCode ?? 0) >= 300 ||
          (body is Map && body['status'] == false);
      if (failed) unawaited(register(api));
      return res;
    } catch (_) {
      unawaited(register(api));
      rethrow;
    }
  }

  /// Removes this phone from the server, then deletes its token. Call before
  /// the session is cleared; [authToken] signs the call when the stored token
  /// is being cleared at the same time. Never throws.
  static Future<void> unregister(ApiClient api, {String? authToken}) =>
      _serial(() async {
        if (_removed || !await start()) return;
        final messaging = FirebaseMessaging.instance;
        try {
          final token = await messaging.getToken();
          if (token != null && token.isNotEmpty) {
            await api.unregisterDevice(token, authToken: authToken);
          }
        } catch (e) {
          // Logged-out or already-gone sessions answer 401 — the token is
          // deleted below either way, so the server forgets it on next send.
          debugPrint('[push] unregister failed: $e');
        }
        try {
          await messaging.deleteToken();
        } catch (e) {
          debugPrint('[push] deleteToken failed: $e');
        }
        _removed = true;
        debugPrint('[push] phone removed');
      });
}

/// Draws the pop-up for a DATA-ONLY message that arrives while the app is in the
/// background or fully closed. FCM runs this in a separate isolate, so it must
/// re-initialise Firebase and the local-notifications plugin and (re)create the
/// channel itself — nothing from the main isolate is available here.
///
/// A top-level function annotated `@pragma('vm:entry-point')` is required by
/// `FirebaseMessaging.onBackgroundMessage`. A message that carries a
/// `notification` block is drawn by the system automatically, so we skip it to
/// avoid a duplicate pop-up; only data-only messages need us.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  if (message.notification != null) return; // system already shows these

  final title = message.data['title']?.toString();
  final body = message.data['body']?.toString();
  if ((title ?? '').isEmpty && (body ?? '').isEmpty) return;

  try {
    await Firebase.initializeApp();
    final local = FlutterLocalNotificationsPlugin();
    await local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(PushNotifications._icon),
      ),
    );
    await local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            PushNotifications.channelId,
            PushNotifications._channelName,
            description: PushNotifications._channelDescription,
            importance: Importance.high,
          ),
        );
    await local.show(
      id:
          (message.messageId ?? '${DateTime.now().microsecondsSinceEpoch}')
              .hashCode &
          0x7fffffff,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          PushNotifications.channelId,
          PushNotifications._channelName,
          channelDescription: PushNotifications._channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: PushNotifications._icon,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  } catch (_) {
    // Best effort — a failed background draw must never crash the isolate.
  }
}
