import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Turns any API failure into a short, human sentence safe to show a user.
///
/// The backend returns an EMPTY body for 4xx responses, so `e.toString()` used
/// to surface the raw Dio dump ("DioException [bad response]: This exception was
/// thrown because the response has a status code of 400 and
/// RequestOptions.validateStatus was configured to throw...") directly in a
/// SnackBar. This maps the failure to a message a normal user can act on, and
/// still prefers the server's own `message` whenever it sends one.
String friendlyApiError(Object error, {String? fallback}) {
  // Always keep the full technical detail in the debug console for developers.
  debugPrint('API error: $error');

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server is taking too long to respond. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network and try again.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      case DioExceptionType.badCertificate:
        return 'Could not establish a secure connection.';
      default:
        // badResponse / unknown / any future type: fall through to the
        // status-code mapping below.
        break;
    }

    // Prefer whatever the server actually said, when it says anything.
    final serverMessage = _serverMessage(error.response?.data);
    if (serverMessage != null && serverMessage.isNotEmpty) return serverMessage;

    switch (error.response?.statusCode) {
      case 400:
        return fallback ??
            'Some details look incorrect. Please check the form and try again.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'This account does not have access here. Please check you '
            'selected the right portal, or contact support.';
      case 404:
        return 'We could not find what you were looking for.';
      case 409:
        return 'This entry already exists.';
      case 422:
        return 'Some details look incorrect. Please check the form and try again.';
      case 429:
        return 'Too many attempts. Please wait a moment and try again.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'The server is having trouble right now. Please try again shortly.';
    }
  }

  return fallback ?? 'Something went wrong. Please try again.';
}

/// Digs a human message out of common API error shapes.
String? _serverMessage(dynamic data) {
  if (data == null) return null;
  if (data is String) {
    final s = data.trim();
    // Guard against an HTML error page being shown verbatim.
    if (s.isEmpty || s.startsWith('<')) return null;
    return s;
  }
  if (data is Map) {
    for (final key in const ['message', 'error', 'msg', 'detail']) {
      final v = data[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    // Mongoose-style: { errors: { field: { message: "..." } } }
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final messages = <String>[];
      for (final v in errors.values) {
        if (v is Map && v['message'] is String) {
          messages.add((v['message'] as String).trim());
        } else if (v is String && v.trim().isNotEmpty) {
          messages.add(v.trim());
        }
      }
      if (messages.isNotEmpty) return messages.join('\n');
    }
  }
  return null;
}
