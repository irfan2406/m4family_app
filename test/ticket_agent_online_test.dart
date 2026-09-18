import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m4_mobile/core/network/api_client.dart';
import 'package:m4_mobile/presentation/providers/auth_provider.dart';
import 'package:m4_mobile/presentation/screens/support/ticket_detail_screen.dart';

/// Ticket chat header (CP, Investor and Customer share this screen): the live
/// status matches the web — a green "active" dot and AGENT ONLINE in the
/// header's bold sans. It used to be a #163A2C dot, which reads as black
/// rather than as "online", next to a serif SUPPORT AGENT ONLINE.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://api.example.com');

  @override
  Future<Response> getTicketDetail(String ticketId) async => Response(
    requestOptions: RequestOptions(path: '/api/tickets/$ticketId'),
    statusCode: 200,
    data: {'status': true, 'data': _ticket},
  );
}

const _ticket = {
  '_id': '6a70ae0000000000006a70ae',
  'ticketId': 'TICK-6A70AE',
  'subject': 'Inquiry: Clédor',
  'status': 'open',
  'messages': [
    {'message': 'hii', 'sender': 'user', 'createdAt': '2026-09-18T08:13:00Z'},
  ],
};

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('the header shows a green AGENT ONLINE status', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(_FakeApiClient())],
        child: const MaterialApp(
          home: TicketDetailScreen(
            ticketId: '6a70ae0000000000006a70ae',
            initialTicket: _ticket,
          ),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    // The words, in the header's bold sans rather than the old serif.
    expect(find.text('SUPPORT AGENT ONLINE'), findsNothing);
    final label = find.text('AGENT ONLINE');
    expect(label, findsOneWidget);
    final style = tester.widget<Text>(label).style!;
    expect(style.fontFamily, startsWith('Inter'));
    expect(style.fontSize, 8);
    expect(style.fontWeight, FontWeight.w700);
    expect(style.letterSpacing, 1.5);

    // The dot beside it is the green "active" indicator.
    final row = find.ancestor(of: label, matching: find.byType(Row)).first;
    final dots = tester
        .widgetList<Container>(
          find.descendant(of: row, matching: find.byType(Container)),
        )
        .where((c) {
          final d = c.decoration;
          return d is BoxDecoration && d.shape == BoxShape.circle;
        })
        .toList();
    expect(dots, hasLength(1));
    expect(
      (dots.single.decoration! as BoxDecoration).color,
      const Color(0xFF22C55E),
    );
    final dotRect = tester.getRect(find.byWidget(dots.single));
    expect(dotRect.size, const Size(6, 6));
    // Dot first, then 6dp, then the words — the web's order and spacing.
    expect(tester.getRect(label).left - dotRect.right, 6);

    // The title above it is untouched.
    final title = find.text('INQUIRY: CLÉDOR');
    expect(title, findsOneWidget);
    final titleStyle = tester.widget<Text>(title).style!;
    expect(titleStyle.fontSize, 14);
    expect(titleStyle.fontWeight, FontWeight.w600);

    expect(tester.takeException(), isNull);
  });
}
