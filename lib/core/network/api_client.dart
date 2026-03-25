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

  Future<Response> getProjectDetails(String id) async {
    return dio.get('/api/catalog/projects/$id');
  }

  Future<Response> getProjectUpdates(String projectId) async {
    return dio.get('/api/catalog/updates', queryParameters: {
      'project': projectId,
      'status': 'Published',
    });
  }

  Future<Response> getProjectInventory(String projectId) async {
    return dio.get('/api/catalog/projects/$projectId/inventory');
  }

  Future<Response> getLocations() async {
    return dio.get('/api/catalog/locations');
  }

  Future<Response> getCustomizationOptions() async {
    return dio.get('/api/catalog/customization-options');
  }

  // Custom Views Methods
  Future<Response> submitCustomViews(Map<String, dynamic> data) async {
    return dio.post('/api/custom-views', data: data);
  }

  // Lead Generation
  Future<Response> submitLead(Map<String, dynamic> data) async {
    return dio.post('/api/leads', data: data);
  }

  // Notifications
  Future<Response> getNotifications() async {
    return dio.get('/api/notifications');
  }

  Future<Response> markAllNotificationsAsRead() async {
    return dio.patch('/api/notifications/mark-all-read');
  }

  // Support Tickets
  Future<Response> getTickets() async {
    return dio.get('/api/tickets');
  }

  Future<Response> createTicket(Map<String, dynamic> data) async {
    return dio.post('/api/tickets', data: data);
  }

  // CMS Methods
  Future<Response> getCmsPages() async {
    return dio.get('/api/cms');
  }

  Future<Response> getCmsPage(String slug) async {
    return dio.get('/api/cms/$slug');
  }

  // System Config
  Future<Response> getSystemConfig() async {
    return dio.get('/api/config');
  }

  // Careers Methods
  Future<Response> getJobs() async {
    return dio.get('/api/careers/jobs');
  }

  Future<Response> uploadResume(String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'resume': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    return dio.post(
      '/api/careers/upload/resume',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
  }

  Future<Response> applyJob(Map<String, dynamic> data) async {
    return dio.post('/api/careers/apply', data: data);
  }
}



