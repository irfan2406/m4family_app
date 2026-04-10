import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class ApiClient {
  final Dio dio;
  final String baseUrl;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  ApiClient({required this.baseUrl})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
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

  Future<Response> getCurrentUser() async {
    return dio.get('/api/auth/me');
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

  Future<Response> getGlobalUpdates() async {
    return dio.get('/api/catalog/updates', queryParameters: {
      'status': 'Published',
    });
  }

  Future<Response> getProjectProgress(String projectId) async {
    return dio.get('/api/catalog/projects/$projectId/progress');
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

  Future<Response> getCommunities() async {
    return dio.get('/api/catalog/communities');
  }

  Future<Response> getCommunityBySlug(String slug) async {
    return dio.get('/api/catalog/communities/$slug');
  }

  Future<Response> getProjectsByCommunity(String communityId) async {
    return dio.get('/api/catalog/projects/community/$communityId');
  }

  // Custom Views Methods
  Future<Response> submitCustomViews(Map<String, dynamic> data) async {
    return dio.post('/api/custom-views', data: data);
  }

  Future<Response> getMyCustomViews() async {
    return dio.get('/api/custom-views/my');
  }

  // Lead Generation
  // Lead Generation
  Future<Response> submitLead(Map<String, dynamic> data) async {
    return dio.post('/api/leads', data: data);
  }

  // Profile Management
  Future<Response> updateMe(Map<String, dynamic> data) async {
    return dio.patch('/api/auth/me', data: data);
  }

  Future<Response> deleteMe() async {
    return dio.delete('/api/auth/me');
  }

  Future<Response> uploadAvatar(String filePath) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    return dio.post(
      '/api/upload',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
  }

  // Notifications
  Future<Response> getNotifications() async {
    return dio.get('/api/notifications');
  }

  Future<Response> markAllNotificationsAsRead() async {
    return dio.patch('/api/notifications/mark-all-read');
  }

  // System Logs
  Future<Response> getLogs() async {
    return dio.get('/api/logs');
  }

  // Support Tickets
  Future<Response> getTickets() async {
    return dio.get('/api/tickets');
  }

  Future<Response> createTicket(Map<String, dynamic> data) async {
    if (data.containsKey('attachments') && (data['attachments'] as List).isNotEmpty) {
      final List<String> filePaths = List<String>.from(data['attachments']);
      final Map<String, dynamic> formDataMap = Map<String, dynamic>.from(data);
      
      final List<MultipartFile> multipartFiles = [];
      for (final path in filePaths) {
        final fileName = path.split('/').last;
        multipartFiles.add(await MultipartFile.fromFile(path, filename: fileName));
      }
      
      formDataMap['attachments'] = multipartFiles;
      final formData = FormData.fromMap(formDataMap);
      
      return dio.post(
        '/api/tickets',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
    }
    
    return dio.post('/api/tickets', data: data);
  }

  // CMS Methods
  Future<Response> getCmsPages() async {
    return dio.get('/api/cms');
  }

  Future<Response> getCmsPage(String slug, {String portal = 'guest'}) async {
    return dio.get('/api/cms/$slug', queryParameters: {'portal': portal});
  }

  // Content Hub Methods
  Future<Response> getContent(String type, {String role = 'guest', String? projectId}) async {
    final Map<String, dynamic> params = {
      'type': type,
      'role': role,
      'isPublished': 'true',
    };
    if (projectId != null) params['projectId'] = projectId;
    return dio.get('/api/content', queryParameters: params);
  }

  Future<Response> getContentBySlug(String slug) async {
    return dio.get('/api/content/$slug');
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

  // User Preferences & Theme
  Future<Response> updateTheme(String theme) async {
    return dio.patch('/api/user/theme', data: {'theme': theme});
  }

  Future<Response> getMyPreferences() async {
    return dio.get('/api/user/preferences');
  }

  // Investor & Referrals
  Future<Response> getInvestorWallet() async {
    return dio.get('/api/investor/wallet');
  }

  Future<Response> getReferralDashboard() async {
    return dio.get('/api/user/referrals/dashboard');
  }

  Future<Response> submitReferral(Map<String, dynamic> data) async {
    return dio.post('/api/referral', data: data);
  }

  Future<Response> redeemPoints(Map<String, dynamic> data) async {
    return dio.post('/api/user/referrals/redeem', data: data);
  }

  // Site Visits & Bookings
  Future<Response> scheduleSiteVisit(Map<String, dynamic> data) async {
    return dio.post('/api/user/site-visit', data: data);
  }

  Future<Response> getMyBookings() async {
    return dio.get('/api/user/bookings');
  }

  Future<Response> getMySupportDocuments() async {
    return dio.get('/api/user/documents');
  }

  String resolveUrl(String? url) {
    if (url == null || url.isEmpty) {
      return 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&q=80';
    }
    if (url.startsWith('http') || url.startsWith('tel:') || url.startsWith('mailto:')) return url;

    String root = baseUrl;
    if (root.endsWith('/api')) root = root.substring(0, root.length - 4);
    if (root.endsWith('/')) root = root.substring(0, root.length - 1);

    final path = url.startsWith('/') ? url : '/$url';
    return '$root$path';
  }
}



