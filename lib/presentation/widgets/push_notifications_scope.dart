import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m4_mobile/core/services/push_notifications.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/notification_provider.dart';

/// Connects phone pop-ups ([PushNotifications]) to the signed-in session.
///
/// * Signing in — or opening the app with a saved session — sends this
///   phone's token to the server; so does every FCM token change. A failed
///   send (offline start-up) is retried when the app comes back to the
///   foreground. Removal happens in `AuthNotifier.logout` and before account
///   deletion.
/// * A pop-up arriving while the app is open refreshes the Notifications list.
/// * A tapped pop-up opens that portal's Notifications page, or the ticket
///   chat for a support reply (`type: TICKET_REPLY` + `ticketId`). When the
///   tap launched the app, it waits for the splash to hand over to `/home`.
class PushNotificationsScope extends ConsumerStatefulWidget {
  const PushNotificationsScope({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<PushNotificationsScope> createState() =>
      _PushNotificationsScopeState();
}

class _PushNotificationsScopeState extends ConsumerState<PushNotificationsScope>
    with WidgetsBindingObserver {
  bool _registered = false;
  bool _registering = false;
  Map<String, dynamic>? _pendingTap;

  bool get _signedIn =>
      ref.read(authProvider).status == AuthStatus.authenticated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.router.routerDelegate.addListener(_openPendingTap);

    ref.listenManual<AuthState>(authProvider, (prev, next) {
      final signedIn = next.status == AuthStatus.authenticated;
      if (!signedIn) {
        _registered = false;
      } else if (prev?.status != AuthStatus.authenticated) {
        _register();
      }
      _openPendingTap();
    }, fireImmediately: true);

    PushNotifications.setForegroundHandler((_) {
      if (_signedIn) {
        ref.read(notificationProvider.notifier).fetchNotifications();
      }
    });
    PushNotifications.setTokenRefreshHandler(() {
      if (_signedIn) _register(force: true);
    });
    PushNotifications.setTapHandler((data) {
      _pendingTap = data;
      _openPendingTap();
    });
  }

  @override
  void dispose() {
    PushNotifications.setTapHandler(null);
    PushNotifications.setForegroundHandler(null);
    PushNotifications.setTokenRefreshHandler(null);
    widget.router.routerDelegate.removeListener(_openPendingTap);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _signedIn && !_registered) {
      _register();
    }
  }

  Future<void> _register({bool force = false}) async {
    if (_registering || (_registered && !force)) return;
    _registering = true;
    try {
      final ok = await PushNotifications.register(ref.read(apiClientProvider));
      // Signed out while the request was in flight: logout removes the phone.
      if (mounted && _signedIn) _registered = ok;
    } finally {
      _registering = false;
    }
  }

  void _openPendingTap() {
    final data = _pendingTap;
    if (data == null || !mounted) return;
    final auth = ref.read(authProvider);
    final location =
        widget.router.routerDelegate.currentConfiguration.uri.path;
    // Still on the splash: the session check and its jump to /home would
    // replace anything opened now.
    if (!auth.bootstrapped || location.isEmpty || location == '/onboarding') {
      return;
    }
    _pendingTap = null;
    if (auth.status != AuthStatus.authenticated) return;

    final role = (auth.user?['role'] ?? auth.role ?? '')
        .toString()
        .toLowerCase();
    final portal = role == 'investor'
        ? '/investor'
        : role == 'cp'
        ? '/cp'
        : '';
    final ticketId = data['ticketId']?.toString() ?? '';
    final target = data['type'] == 'TICKET_REPLY' && ticketId.isNotEmpty
        ? '$portal/support/tickets/$ticketId'
        : '$portal/notifications';

    ref.read(notificationProvider.notifier).fetchNotifications();
    // Not from inside the router's own change notification.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.router.push(target);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
