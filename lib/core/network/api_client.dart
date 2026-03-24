import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  ApiClient({required String baseUrl})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            // Handle Logout or Refresh Token logic here
          }
          return handler.next(e);
        },
      ),
    );

    // Logging for Debugging
    dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      compact: true,
    ));
  }

  // Auth Methods
  Future<Response> sendOtp(String identifier, String role) async {
    return dio.post('/api/auth/send-otp', data: {
      'identifier': identifier,
      'role': role,
    });
  }

  Future<Response> verifyOtp(String identifier, String code, String role) async {
    return dio.post('/api/auth/verify-otp', data: {
      'identifier': identifier,
      'token': code,
      'role': role,
    });
  }

  // Catalog Methods
  Future<Response> getProjects() async {
    return dio.get('/api/catalog/projects');
  }

  Future<Response> getLocations() async {
    return dio.get('/api/catalog/locations');
  }
}
