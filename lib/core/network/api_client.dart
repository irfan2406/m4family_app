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

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, dynamic data) async {
    return dio.post(path, data: data);
  }

  Future<Response> patch(String path, dynamic data) async {
    return dio.patch(path, data: data);
  }

  Future<Response> delete(String path) async {
    return dio.delete(path);
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

  /// Password login (web CP: `identifier` = CP ID / phone / email).
  Future<Response> loginWithPassword(String identifier, String password) async {
    return dio.post('/api/auth/login', data: {
      'identifier': identifier,
      'password': password,
    });
  }

  /// Registration (web CP signup: `role`: `CP`, plus CP fields).
  Future<Response> register(Map<String, dynamic> body) async {
    return dio.post('/api/auth/register', data: body);
  }

  Future<Response> forgotPassword(String identifier) async {
    return dio.post('/api/auth/forgot-password', data: {'identifier': identifier});
  }

  Future<Response> resetPassword({
    required String identifier,
    required String token,
    required String newPassword,
  }) async {
    return dio.post('/api/auth/reset-password', data: {
      'identifier': identifier,
      'token': token,
      'newPassword': newPassword,
    });
  }

  Future<Response> getCurrentUser() async {
    return dio.get('/api/auth/me');
  }

  /// Public app config (matches web `GET /api/config` — e.g. support phone/WhatsApp).
  Future<Response> getPublicConfig() async {
    return dio.get('/api/config');
  }

  // ─── Channel Partner (`/api/cp/*`, requireAuth) ─────────────────────────────
  Future<Response> getCpWallet() async {
    return dio.get('/api/cp/wallet');
  }

  Future<Response> getCpReferrals() async {
    return dio.get('/api/cp/referrals');
  }

  Future<Response> createCpReferral(Map<String, dynamic> body) async {
    return dio.post('/api/cp/referrals', data: body);
  }

  Future<Response> patchCpReferralStatus(String id, String status) async {
    return dio.patch('/api/cp/referrals/$id/status', data: {'status': status});
  }

  Future<Response> getCpCommissions() async {
    return dio.get('/api/cp/commissions');
  }

  Future<Response> getCpTracker({Map<String, dynamic>? queryParameters}) async {
    return dio.get('/api/cp/tracker', queryParameters: queryParameters);
  }

  Future<Response> createCpTracker(Map<String, dynamic> body) async {
    return dio.post('/api/cp/tracker', data: body);
  }

  Future<Response> updateCpTracker(String id, Map<String, dynamic> body) async {
    return dio.patch('/api/cp/tracker/$id', data: body);
  }

  Future<Response> getCpPerformance() async {
    return dio.get('/api/cp/performance');
  }

  /// CP tax / TDS statements (same mock payload as investor tax-reports).
  Future<Response> getCpTaxReports({String? year}) async {
    final q = year != null ? <String, dynamic>{'year': year} : null;
    return dio.get('/api/cp/tax-reports', queryParameters: q);
  }

  /// CP team members (web `GET /api/cp/employees`).
  Future<Response> getCpEmployees() async {
    return dio.get('/api/cp/employees');
  }

  /// Web `POST /api/cp/employees` — body: `{ name, phone, email? }`.
  Future<Response> createCpEmployee(Map<String, dynamic> body) async {
    return dio.post('/api/cp/employees', data: body);
  }

  /// Paginated site visits (web `GET /api/cp/visits`).
  Future<Response> getCpVisits({int page = 1, int limit = 10}) async {
    return dio.get('/api/cp/visits', queryParameters: {'page': page, 'limit': limit});
  }

  Future<Response> patchCpVisitStatus(String id, String status) async {
    return dio.patch('/api/cp/visits/$id/status', data: {'status': status});
  }

  /// Authenticated leads list (filters: `source`, `status`, etc.).
  Future<Response> getLeads({Map<String, dynamic>? queryParameters}) async {
    return dio.get('/api/leads', queryParameters: queryParameters);
  }

  /// CP bookings (`GET /api/cp/bookings`).
  Future<Response> getCpBookings() async {
    return dio.get('/api/cp/bookings');
  }

  /// Notify Admin about 100% payment settlement (`POST /api/cp/bookings/:id/notify-admin`).
  Future<Response> notifyAdminForSettlement(String bookingId) async {
    return dio.post('/api/cp/bookings/$bookingId/notify-admin', data: {});
  }

  Future<Response> getCatalogContactStaff() async {
    return dio.get('/api/catalog/contact-staff');
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

  Future<Response> getMyUnits() async {
    return dio.get('/api/customization/my-units');
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

  Future<Response> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return dio.patch('/api/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<Response> logoutAllSessions() async {
    return dio.post('/api/auth/logout-all');
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

  Future<Response> updatePreferences(Map<String, dynamic> preferences) async {
    return dio.patch('/api/preferences', data: preferences);
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

  Future<Response> getUserBookings() async {
    return dio.get('/api/user/bookings');
  }

  Future<Response> getMySupportDocuments() async {
    return dio.get('/api/user/documents');
  }

  String resolveUrl(String? url) {
    if (url == null || url.isEmpty) return "";
    if (url.startsWith('http') || url.startsWith('tel:') || url.startsWith('mailto:')) return url;

    String root = baseUrl;
    if (root.endsWith('/api')) root = root.substring(0, root.length - 4);
    if (root.endsWith('/')) root = root.substring(0, root.length - 1);

    final path = url.startsWith('/') ? url : '/$url';
    return '$root$path';
  }
}



