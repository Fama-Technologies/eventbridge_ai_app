import 'package:dio/dio.dart';
import 'network_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;

  ApiService._internal() {
    _dio = NetworkService().dio;
    // Override the base URL to our new AWS Lambda endpoint
    _dio.options.baseUrl = 'https://3nqhgc5y2l.execute-api.us-east-1.amazonaws.com/dev';
  }

  static ApiService get instance => _instance;

  // ── Auth ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String password,
    String role = 'CUSTOMER',
  }) async {
    try {
      final names = fullName.split(' ');
      final firstName = names[0];
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : ' ';
      
      final response = await _dio.post(
        '/api/auth/signup',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'accountType': role.toUpperCase(),
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> googleAuth({
    required String idToken,
    required String accountType,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/google',
        data: {
          'idToken': idToken,
          'accountType': accountType.toUpperCase(),
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> submitVendorOnboarding({
    required String userId,
    required String businessName,
    String? country,
    String? location,
    String? description,
    String? experience,
    String? price,
    List<String>? serviceCategories,
    String? avatarUrl,
    List<String>? galleryUrls,
    String? website,
    int? travelRadius,
    Map<String, String>? workingHours,
  }) async {
    try {
      final response = await _dio.post(
        '/api/vendor/onboarding',
        data: {
          'userId': userId,
          'businessName': businessName,
          'country': country,
          'location': location,
          'description': description,
          'experience': experience,
          'price': price,
          'serviceCategories': serviceCategories,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
          if (galleryUrls != null && galleryUrls.isNotEmpty) 'galleryUrls': galleryUrls,
          if (website != null) 'website': website,
          if (travelRadius != null) 'travelRadius': travelRadius,
          if (workingHours != null) 'workingHours': workingHours,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getVendorProfile(String userId) async {
    try {
      final response = await _dio.get('/api/vendor/profile/$userId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> saveVendorPackages({
    required String userId,
    required List<Map<String, dynamic>> packages,
  }) async {
    try {
      final response = await _dio.post(
        '/api/vendor/packages',
        data: {
          'userId': userId,
          'packages': packages,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getVendorAvailability(String userId) async {
    try {
      final response = await _dio.get('/api/vendor/availability/$userId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> saveVendorAvailability({
    required String userId,
    Map<String, dynamic>? workingHours,
    List<String>? blockedDates,
    bool? sameDayService,
  }) async {
    try {
      final response = await _dio.post(
        '/api/vendor/availability',
        data: {
          'userId': userId,
          'workingHours': workingHours,
          'blockedDates': blockedDates,
          'sameDayService': sameDayService,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Upload ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getPresignedUrl({
    required String fileName,
    required String contentType,
    String folder = 'uploads',
  }) async {
    try {
      final response = await _dio.post(
        '/api/upload/presigned-url',
        data: {
          'fileName': fileName,
          'contentType': contentType,
          'folder': folder,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Error Handling ───────────────────────────────────────────────────────

  Exception _handleError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final message = e.response?.data['message'] ?? 'Unknown network error';
      return Exception(message);
    }
    return Exception(e.message ?? 'Failed to connect to backend');
  }
}
