// TEMPORARY live form test — runs the real app on the phone against the real
// server with the phone's saved session. Delete after the form audit.
// Run: flutter test integration_test/forms_live_test.dart -d <id> --no-uninstall
//        --dart-define=PORTAL=investor|customer|cp|guest
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:m4_mobile/main.dart' as app;
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/providers/communities_provider.dart';
import 'package:m4_mobile/presentation/providers/project_provider.dart';
import 'package:m4_mobile/presentation/screens/investor/investor_relations_screen.dart';
import 'package:m4_mobile/presentation/screens/projects/project_detail_screen.dart';
import 'package:m4_mobile/presentation/screens/support/schedule_visit_screen.dart';

const portal = String.fromEnvironment('PORTAL', defaultValue: 'investor');
const kName = 'M APP TEST please ignore';
const kFirst = 'MAPPTEST';
const kLast = 'Ignore';
const kEmail = 'test@example.com';
const kPhone = '9000000001';
const kMsg = 'Automated app test please ignore';

final calls = <String>[];
late WidgetTester T;
late ProviderContainer C;

void log(String s) => debugPrint('[FORMTEST] $s');

Future<void> settle([int ms = 1500]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await T.pump(const Duration(milliseconds: 100));
  }
}

Set<String> visibleTexts() {
  final out = <String>{};
  for (final e in find.byType(Text).evaluate()) {
    final w = e.widget as Text;
    final s = w.data ?? w.textSpan?.toPlainText() ?? '';
    if (s.trim().isNotEmpty) out.add(s.trim());
  }
  for (final e in find.byType(RichText).evaluate()) {
    final s = (e.widget as RichText).text.toPlainText();
    if (s.trim().isNotEmpty) out.add(s.trim());
  }
  return out;
}

Finder field(String hint) => find.byWidgetPredicate(
  (w) =>
      w is TextField &&
      ((w.decoration?.hintText ?? '') == hint ||
          (w.decoration?.labelText ?? '') == hint),
);

Finder get vScrolls => find.byWidgetPredicate(
  (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
);

/// Scrolls the given (or innermost/top-most) vertical scrollable until [f]
/// is built and visible.
Future<bool> reveal(Finder f, {bool modal = false}) async {
  if (f.evaluate().isNotEmpty) {
    try {
      await T.ensureVisible(f.first);
      await settle(400);
      return true;
    } catch (_) {}
  }
  final scrollables = vScrolls.evaluate().toList();
  if (scrollables.isEmpty) return f.evaluate().isNotEmpty;
  final order = modal ? scrollables.reversed : scrollables;
  for (final s in order) {
    final st = (s as StatefulElement).state as ScrollableState;
    final pos = st.position;
    pos.jumpTo(pos.minScrollExtent);
    await settle(300);
    for (var i = 0; i < 80; i++) {
      if (f.evaluate().isNotEmpty) {
        try {
          await T.ensureVisible(f.first);
        } catch (_) {}
        await settle(400);
        return true;
      }
      if (pos.pixels >= pos.maxScrollExtent) break;
      pos.jumpTo((pos.pixels + 300).clamp(pos.minScrollExtent, pos.maxScrollExtent));
      await settle(200);
    }
  }
  return f.evaluate().isNotEmpty;
}

Future<void> fill(String hint, String value, {bool modal = false}) async {
  final f = field(hint);
  if (!await reveal(f, modal: modal)) {
    log('  field "$hint" NOT FOUND; on screen: ${visibleTexts().take(25).join(" / ")}');
    return;
  }
  await T.enterText(f.first, value);
  await settle(300);
}

Future<bool> tapText(String text, {bool modal = false, bool last = false}) async {
  final f = find.text(text);
  if (!await reveal(f, modal: modal)) {
    log('  "$text" NOT FOUND; scrollables=${vScrolls.evaluate().length}; on screen: ${visibleTexts().take(25).join(" / ")}');
    return false;
  }
  await T.tap(last ? f.last : f.first, warnIfMissed: false);
  await settle(1200);
  return true;
}

Future<void> pickDate({bool modal = false}) async {
  for (final label in ['Select date & time', 'SELECT DATE & TIME']) {
    if (find.text(label).evaluate().isNotEmpty ||
        await reveal(find.text(label), modal: modal)) {
      await T.tap(find.text(label).first, warnIfMissed: false);
      await settle(1500);
      if (find.text('CONFIRM').evaluate().isNotEmpty) {
        await T.tap(find.text('CONFIRM').last);
        await settle(800);
        return;
      }
    }
  }
  log('  date & time picker NOT FOUND');
}

/// Taps [button], waits 8 s, and reports the write API calls with the
/// server's answers plus every new text that appeared.
Future<void> submit(String form, String button, {bool modal = false}) async {
  final f = find.text(button);
  if (!await reveal(f, modal: modal)) {
    log('RESULT $form: submit button "$button" NOT FOUND');
    return;
  }
  final before = visibleTexts();
  calls.clear();
  await T.tap(f.last, warnIfMissed: false);
  final seen = <String>{};
  var snacks = 0, dialogs = 0;
  for (var i = 0; i < 80; i++) {
    await T.pump(const Duration(milliseconds: 100));
    seen.addAll(visibleTexts().difference(before));
    snacks = snacks > 0 ? snacks : find.byType(SnackBar).evaluate().length;
    dialogs = dialogs > 0 ? dialogs : find.byType(Dialog).evaluate().length + find.byType(AlertDialog).evaluate().length;
  }
  log("  snackbar seen: ${snacks > 0}, dialog seen: ${dialogs > 0}, page after: ${router.routerDelegate.currentConfiguration.uri}");
  log('RESULT $form');
  log('  api: ${calls.isEmpty ? "(no request sent)" : calls.join(" || ")}');
  log('  popup/new texts: ${seen.isEmpty ? "(nothing appeared)" : seen.take(12).join(" | ")}');
}

late GoRouter router;

Future<void> go(String path, {Object? extra}) async {
  router.go(path, extra: extra);
  await settle(5000);
}

Future<void> pushPage(Widget page) async {
  Navigator.of(T.element(find.byType(Scaffold).last)).push(
    MaterialPageRoute(builder: (_) => page),
  );
  await settle(6000);
}

Future<void> backHome() async {
  try {
    router.go('/home');
  } catch (_) {}
  await settle(3000);
}

Future<void> step(String name, Future<void> Function() body) async {
  log('--- $name');
  try {
    await body();
  } catch (e) {
    log('RESULT $name: TEST ERROR ${e.toString().split('\n').first}');
  }
  await backHome();
}

Future<Map<String, dynamic>> firstProject() async {
  final list = await C.read(projectsProvider.future);
  final p = list.cast<Map>().firstWhere(
    (p) => (p['_id']?.toString().length ?? 0) == 24,
  );
  log('  using project ${p['title']} (${p['_id']})');
  return Map<String, dynamic>.from(p);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('live forms ($portal)', (t) async {
    // SAFETY GUARD: this test submits REAL forms to the LIVE server and creates
    // real CRM enquiries ("M APP TEST please ignore"). It must NEVER run by
    // accident (a plain `flutter test`, a CI sweep, an automated review). Run it
    // deliberately only with: --dart-define=ALLOW_LIVE_FORMS=true, and only
    // after telling the backend team.
    if (!const bool.fromEnvironment('ALLOW_LIVE_FORMS')) {
      markTestSkipped(
        'forms_live_test hits the LIVE API and creates real CRM records; '
        'pass --dart-define=ALLOW_LIVE_FORMS=true to run it on purpose.',
      );
      return;
    }
    T = t;
    app.main();
    await settle(12000);

    C = ProviderScope.containerOf(t.element(find.byType(MaterialApp).first));
    router = GoRouter.of(t.element(find.byType(Scaffold).first));
    final auth = C.read(authProvider);
    log('portal=$portal signed in: ${auth.status} role=${auth.user?['role']}');
    C.read(apiClientProvider).dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (r, h) {
          final m = r.requestOptions.method;
          if (m != 'GET') {
            calls.add('$m ${r.requestOptions.path} -> ${r.statusCode} ${r.data}');
          }
          h.next(r);
        },
        onError: (e, h) {
          final m = e.requestOptions.method;
          if (m != 'GET') {
            calls.add(
              '$m ${e.requestOptions.path} -> ERROR ${e.response?.statusCode} '
              '${e.response?.data ?? e.message}',
            );
          }
          h.next(e);
        },
      ),
    );

    if (portal == 'investor') {
      await step('D3 Investor Home - Register Interest', () async {
        await fill('Enter Full Name', kName);
        await fill('Enter Email Address', kEmail);
        await fill('Enter Mobile Number', kPhone);
        await fill('Enter Message', kMsg);
        if (await reveal(find.byType(Checkbox))) {
          await T.tap(find.byType(Checkbox).last);
          await settle(300);
        }
        await submit('D3 Investor Home - Register Interest', 'SUBMIT INTEREST');
      });

      final p = await firstProject();
      final id = p['_id'] as String;

      await step('A3 Investor Project - Registration form', () async {
        await go('/investor/projects/$id', extra: p);
        await fill('FULL NAME *', kName);
        await fill('MOBILE NUMBER *', kPhone);
        await fill('EMAIL (OPTIONAL)', kEmail);
        await pickDate();
        await submit('A3 Investor Project - Registration form', 'SUBMIT REQUEST');
      });

      await step('B3 Investor Project - Video call sheet', () async {
        await go('/investor/projects/$id', extra: p);
        if (!await tapText('Connect Now')) return;
        await fill('Enter Full Name', kName, modal: true);
        await fill('Enter Email Address', kEmail, modal: true);
        await fill('Enter Mobile Number', kPhone, modal: true);
        await pickDate(modal: true);
        await submit('B3 Investor Project - Video call sheet', 'CONFIRM BOOKING', modal: true);
      });

      await step('B3 Investor Project - Site visit sheet', () async {
        await go('/investor/projects/$id', extra: p);
        if (!await tapText('Book Tour')) return;
        await fill('Enter Full Name', kName, modal: true);
        await fill('Enter Email Address', kEmail, modal: true);
        await fill('Enter Mobile Number', kPhone, modal: true);
        await pickDate(modal: true);
        await submit('B3 Investor Project - Site visit sheet', 'CONFIRM BOOKING', modal: true);
      });

      await step('A1 Projects tab project page - Registration form', () async {
        await pushPage(ProjectDetailScreen(projectId: id, projectData: p));
        await fill('FULL NAME *', kName);
        await fill('MOBILE NUMBER *', kPhone);
        await fill('EMAIL (OPTIONAL)', kEmail);
        await pickDate();
        await submit('A1 Projects tab project page - Registration form', 'SUBMIT REQUEST');
      });

      await step('B1 Projects tab project page - Site visit dialog', () async {
        await pushPage(ProjectDetailScreen(projectId: id, projectData: p));
        if (!await tapText('Book Tour')) return;
        await fill('Enter Full Name', kName, modal: true);
        await fill('Enter Email Address (Optional)', kEmail, modal: true);
        await fill('Enter Mobile Number', kPhone, modal: true);
        await pickDate(modal: true);
        await submit('B1 Projects tab project page - Site visit dialog', 'SUBMIT INQUIRY', modal: true);
      });

      await step('D4 Investor Relations', () async {
        await pushPage(const InvestorRelationsScreen());
        await fill('Enter First Name', kFirst);
        await fill('Enter Last Name', kLast);
        await fill('Enter Email Address', kEmail);
        await fill('Enter Mobile Number', kPhone);
        await fill('Enter Message', kMsg);
        if (await reveal(find.byType(Checkbox))) {
          for (final e in find.byType(Checkbox).evaluate().toList()) {
            await T.tap(find.byWidget(e.widget), warnIfMissed: false);
            await settle(300);
          }
        }
        await submit('D4 Investor Relations', 'SUBMIT');
      });

      await step('D5 Contact', () async {
        await go('/investor/contact');
        await fill('Full Name *', kName);
        await fill('Email *', kEmail);
        await fill('Enter Number *', kPhone);
        await fill('Message', kMsg);
        final pp = find.textContaining('agree to the Privacy Policy', findRichText: true);
        if (await reveal(pp)) {
          await T.tap(pp.first, warnIfMissed: false);
          await settle(300);
        }
        await submit('D5 Contact', 'SUBMIT INQUIRY');
      });

      if (const bool.fromEnvironment('RUN_D6')) await step('D6 Schedule Visit', () async {
        await pushPage(const ScheduleVisitScreen()); // as the Support tab opens it
        if (await tapText('CHOOSE PROPERTY')) {
          final title = (p['title'] ?? '').toString().toUpperCase();
          if (!await tapText(title, modal: true)) {
            // fall back to any option in the picker
            log('  picking first listed property instead');
          }
        }
        await pickDate();
        await fill('Enter Specific Requirements', kMsg);
        await submit('D6 Schedule Visit', 'SECURE BOOKING');
      });

      await step('D7 Community - Register Interest', () async {
        final comms = C.read(communitiesProvider).communities;
        if (comms.isEmpty) {
          log('RESULT D7 Community: no communities loaded');
          return;
        }
        final c = Map<String, dynamic>.from(comms.first as Map);
        await go('/investor/communities/${c['slug'] ?? c['_id']}', extra: c);
        await fill('Enter Full Name', kName);
        await fill('Enter Email Address', kEmail);
        await fill('Enter Mobile Number', kPhone);
        await fill('Enter City and Country', 'Mumbai India');
        await submit('D7 Community - Register Interest', 'REGISTER INTEREST');
      });
    }
    if (portal == 'investor_fix') {
      if (const bool.fromEnvironment('RUN_D3')) await step('D3 Investor Home - Register Interest', () async {
        await tapText('REGISTER INTEREST');
        await settle(2000);
        await fill('Enter Full Name', kName);
        await fill('Enter Email Address', kEmail);
        await fill('Enter Mobile Number', kPhone);
        await fill('Enter Message', kMsg);
        if (await reveal(find.byType(Checkbox))) {
          await T.tap(find.byType(Checkbox).last);
          await settle(300);
        } else {
          log('  privacy checkbox NOT FOUND');
        }
        await submit('D3 Investor Home - Register Interest', 'SUBMIT INTEREST');
      });

      if (const bool.fromEnvironment('RUN_D4')) await step('D4 Investor Relations', () async {
        await pushPage(const InvestorRelationsScreen());
        await fill('Enter First Name', kFirst);
        await fill('Enter Last Name', kLast);
        await fill('Enter Email Address', kEmail);
        await fill('Enter Mobile Number', kPhone);
        await fill('Enter Message', kMsg);
        await tapText("I've read and agree to the Privacy Policy");
        await submit('D4 Investor Relations', 'SUBMIT');
      });

      final p = await firstProject();
      if (const bool.fromEnvironment('RUN_D6')) await step('D6 Schedule Visit', () async {
        await go('/support/schedule-visit');
        if (await tapText('CHOOSE PROPERTY')) {
          final opt = find.textContaining((p['title'] ?? '').toString().toUpperCase());
          if (await reveal(opt, modal: true)) {
            await T.tap(opt.last, warnIfMissed: false);
            await settle(1000);
          } else {
            log('  property option NOT FOUND');
          }
        }
        await pickDate();
        await fill('Enter Specific Requirements', kMsg);
        await submit('D6 Schedule Visit', 'SECURE BOOKING');
      });

      await step('D7 Community - Register Interest', () async {
        await C.read(communitiesProvider.notifier).fetchCommunities();
        final comms = C.read(communitiesProvider).communities;
        if (comms.isEmpty) {
          log('RESULT D7 Community: no communities on the server');
          return;
        }
        final c = Map<String, dynamic>.from(comms.first as Map);
        log('  using community ${c['name'] ?? c['title']}');
        await go('/investor/communities/${c['slug'] ?? c['_id']}', extra: c);
        await fill('Enter Full Name', kName);
        await fill('Enter Email Address', kEmail);
        await fill('Enter Mobile Number', kPhone);
        await fill('Enter City and Country', 'Mumbai India');
        await submit('D7 Community - Register Interest', 'REGISTER INTEREST');
      });
    }
    if (portal == 'customer') {
      await step('D1 Customer Home - Register Interest', () async {
        await fill('Enter Full Name', kName);
        await fill('Enter Email Address', kEmail);
        await fill('Enter Mobile Number', kPhone);
        await fill('Enter Message', kMsg);
        if (await reveal(find.byType(Checkbox))) {
          await T.tap(find.byType(Checkbox).last);
          await settle(300);
        }
        await submit('D1 Customer Home - Register Interest', 'SUBMIT INTEREST');
      });

      final p = await firstProject();
      final id = p['_id'] as String;

      await step('A1 Customer Project - Registration form (site visit)', () async {
        await pushPage(ProjectDetailScreen(projectId: id, projectData: p));
        await fill('FULL NAME *', kName);
        await fill('MOBILE NUMBER *', kPhone);
        await fill('EMAIL (OPTIONAL)', kEmail);
        await pickDate();
        await submit('A1 Customer Project - Registration form (site visit)', 'SUBMIT REQUEST');
      });

      await step('A1 Customer Project - Registration form (video call)', () async {
        await pushPage(ProjectDetailScreen(projectId: id, projectData: p));
        await fill('FULL NAME *', kName);
        await fill('MOBILE NUMBER *', kPhone);
        await fill('EMAIL (OPTIONAL)', kEmail);
        await tapText('VIDEO CALL');
        await pickDate();
        await submit('A1 Customer Project - Registration form (video call)', 'SUBMIT REQUEST');
      });

      await step('B1 Customer Project - Site visit dialog', () async {
        await pushPage(ProjectDetailScreen(projectId: id, projectData: p));
        if (!await tapText('Book Tour')) return;
        await fill('Enter Full Name', kName, modal: true);
        await fill('Enter Email Address (Optional)', kEmail, modal: true);
        await fill('Enter Mobile Number', kPhone, modal: true);
        await pickDate(modal: true);
        await submit('B1 Customer Project - Site visit dialog', 'SUBMIT INQUIRY', modal: true);
      });

      await step('B1 Customer Project - Video call dialog', () async {
        await pushPage(ProjectDetailScreen(projectId: id, projectData: p));
        if (!await tapText('Connect Now')) return;
        await fill('Enter Full Name', kName, modal: true);
        await fill('Enter Email Address (Optional)', kEmail, modal: true);
        await fill('Enter Mobile Number', kPhone, modal: true);
        await pickDate(modal: true);
        await submit('B1 Customer Project - Video call dialog', 'SUBMIT INQUIRY', modal: true);
      });

      await step('D5 Contact', () async {
        await go('/support/contact');
        await fill('Full Name *', kName);
        await fill('Email *', kEmail);
        await fill('Enter Number *', kPhone);
        await fill('Message', kMsg);
        final pp = find.textContaining('agree to the Privacy Policy', findRichText: true);
        if (await reveal(pp)) {
          await T.tap(pp.first, warnIfMissed: false);
          await settle(300);
        }
        await submit('D5 Contact', 'SUBMIT INQUIRY');
      });

      await step('D7 Community - Register Interest', () async {
        await C.read(communitiesProvider.notifier).fetchCommunities();
        final comms = C.read(communitiesProvider).communities;
        if (comms.isEmpty) {
          log('RESULT D7 Community: no communities on the server');
          return;
        }
        final c = Map<String, dynamic>.from(comms.first as Map);
        await go('/communities/${c['_id']}', extra: c);
        await fill('Enter Full Name', kName);
        await fill('Enter Email Address', kEmail);
        await fill('Enter Mobile Number', kPhone);
        await fill('Enter City and Country', 'Mumbai India');
        await submit('D7 Community - Register Interest', 'REGISTER INTEREST');
      });

      await step('D10 Referral', () async {
        await go('/profile/referral');
        if (!await tapText('REFER FRIEND')) return;
        if (await tapText('CHOOSE PROJECT', modal: true)) {
          final opt = find.textContaining((p['title'] ?? '').toString().toUpperCase());
          if (await reveal(opt, modal: true)) {
            await T.tap(opt.last, warnIfMissed: false);
            await settle(1000);
          } else {
            log('  project option NOT FOUND');
          }
        }
        await fill('Enter Full Name', kName, modal: true);
        await fill('Enter Mobile Number', kPhone, modal: true);
        await fill('Enter Email Address', kEmail, modal: true);
        await submit('D10 Referral', 'SUBMIT LEAD VERIFICATION', modal: true);
      });

      await step('D9 Custom Views consultation', () async {
        await go('/custom-views');
        log('  custom views screen shows: ${visibleTexts().take(30).join(" / ")}');
      });
    }
    log('DONE');
  });
}
