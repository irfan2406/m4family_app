import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m4_mobile/core/utils/api_error.dart';

DioException _resp(int code, {dynamic body}) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: DioExceptionType.badResponse,
  response: Response(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: code,
    data: body,
  ),
);

void main() {
  test('never leaks the raw DioException text', () {
    // The exact shape the two reported bugs showed the user.
    for (final e in [
      _resp(400),
      _resp(403),
      _resp(500),
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      ),
    ]) {
      final msg = friendlyApiError(e);
      expect(msg, isNot(contains('DioException')));
      expect(msg, isNot(contains('validateStatus')));
      expect(msg, isNot(contains('status code of')));
      expect(msg, isNot(contains('developer.mozilla.org')));
      expect(msg.trim(), isNotEmpty);
    }
  });

  test('403 explains the portal/access problem (OTP bug)', () {
    expect(friendlyApiError(_resp(403)).toLowerCase(), contains('access'));
  });

  test('400 asks the user to check the form (submit bug)', () {
    expect(friendlyApiError(_resp(400)).toLowerCase(), contains('check'));
  });

  test('prefers the server message when the API sends one', () {
    expect(
      friendlyApiError(_resp(400, body: {'message': 'Phone already used'})),
      'Phone already used',
    );
  });

  test('reads mongoose-style field errors', () {
    final msg = friendlyApiError(
      _resp(400, body: {
        'errors': {
          'interest': {'message': 'interest is not a valid enum value'},
        },
      }),
    );
    expect(msg, contains('not a valid enum value'));
  });

  test('ignores an HTML error page', () {
    final msg = friendlyApiError(_resp(500, body: '<html>Bad Gateway</html>'));
    expect(msg, isNot(contains('<html>')));
  });

  test('honours the caller fallback for 400', () {
    expect(friendlyApiError(_resp(400), fallback: 'Custom copy'), 'Custom copy');
  });

  test('non-Dio errors still produce a clean sentence', () {
    final msg = friendlyApiError(StateError('boom'));
    expect(msg, isNot(contains('boom')));
    expect(msg.trim(), isNotEmpty);
  });
}
