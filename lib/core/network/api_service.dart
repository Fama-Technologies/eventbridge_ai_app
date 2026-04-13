import 'package:dio/dio.dart';
import 'network_exceptions.dart';
import 'network_service.dart';
import 'network_status_provider.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;

  ApiService._internal() {
    _dio = NetworkService().dio;
    // Override the base URL to our new AWS Lambda endpoint
    _dio.options.baseUrl =
        'https://3nqhgc5y2l.execute-api.us-east-1.amazonaws.com/dev';
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
        data: {'idToken': idToken, 'accountType': accountType.toUpperCase()},
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
    List<String>? eventCategories,
    String? avatarUrl,
    List<dynamic>? galleryUrls,
    List<dynamic>? projects,
    String? website,
    int? travelRadius,
    double? latitude,
    double? longitude,
    String? currency,
    String? priceUnit,
    bool? isVerified,
    String? plan,
    String? planExpiry,
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
          'eventCategories': eventCategories,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
          if (galleryUrls != null) 'galleryUrls': galleryUrls,
          if (projects != null) 'projects': projects,
          if (website != null) 'website': website,
          if (travelRadius != null) 'travelRadius': travelRadius,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (currency != null) 'currency': currency,
          if (priceUnit != null) 'priceUnit': priceUnit,
          if (isVerified != null) 'isVerified': isVerified,
          if (plan != null) 'plan': plan,
          if (planExpiry != null) 'planExpiry': planExpiry,
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

  Future<Map<String, dynamic>> updateVendorProfile({
    required String userId,
    String? businessName,
    String? phone,
    String? location,
    String? description,
    String? avatarUrl,
    int? yearsExperience,
    double? hourlyRate,
  }) async {
    try {
      final response = await _dio.put(
        '/api/vendor/profile',
        data: {
          'userId': userId,
          if (businessName != null) 'businessName': businessName,
          if (phone != null) 'phone': phone,
          if (location != null) 'location': location,
          if (description != null) 'description': description,
          if (avatarUrl != null) 'profileImage': avatarUrl,
          if (yearsExperience != null) 'yearsExperience': yearsExperience,
          if (hourlyRate != null) 'hourlyRate': hourlyRate,
        },
      );
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
        data: {'userId': userId, 'packages': packages},
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

  // ── Leads ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createLead({
    required String vendorId,
    required String customerId,
    required String title,
    required String eventDate,
    String? eventTime,
    String? location,
    double? budget,
    int? guests,
    String? clientMessage,
  }) async {
    try {
      final response = await _dio.post(
        '/api/vendor/leads',
        data: {
          'vendorId': vendorId,
          'customerId': customerId,
          'title': title,
          'eventDate': eventDate,
          'eventTime': eventTime,
          'location': location,
          'budget': budget,
          'guests': guests,
          'clientMessage': clientMessage,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getVendorLeads(
    String userId, {
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        '/api/vendor/leads/$userId',
        queryParameters: status != null ? {'status': status} : null,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fetch the full details for a single lead by leadId.
  /// Tries common REST patterns; returns null if the backend doesn't support it.
  Future<Map<String, dynamic>?> getVendorLeadById(String leadId) async {
    try {
      final response = await _dio.get('/api/vendor/leads/lead/$leadId');
      return response.data;
    } on DioException catch (e) {
      // 404 → endpoint doesn't exist or lead not found — not a hard error
      if (e.response?.statusCode == 404 ||
          e.response?.statusCode == 405) {
        try {
          // Try alternative pattern
          final response2 = await _dio.get('/api/leads/$leadId');
          return response2.data;
        } on DioException catch (_) {
          return null;
        }
      }
      return null;
    }
  }

  Future<Map<String, dynamic>> updateLeadStatus({
    required String leadId,
    required String status,
  }) async {
    try {
      final response = await _dio.put(
        '/api/vendor/leads/$leadId/status',
        data: {'status': status},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getVendorDashboardStats(String userId) async {
    try {
      final response = await _dio.get('/api/vendor/dashboard-stats/$userId');
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

  // ── Bookings ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getVendorBookings(String userId) async {
    try {
      final response = await _dio.get('/api/vendor/bookings/$userId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createVendorBooking({
    required String userId,
    required String bookingDate,
    String? clientName,
    String? eventType,
    double? totalPrice,
    String? notes,
    String? clientPhone,
    String? leadId,
    String? clientId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/vendor/bookings',
        data: {
          'userId': userId,
          'bookingDate': bookingDate,
          'clientName': clientName,
          'eventType': eventType,
          'totalPrice': totalPrice,
          'notes': notes,
          'clientPhone': clientPhone,
          'leadId': leadId,
          'clientId': clientId,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateBookingStatus({
    required int bookingId,
    required String status,
  }) async {
    try {
      final response = await _dio.put(
        '/api/vendor/bookings/$bookingId/status',
        data: {'status': status},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Error Handling ───────────────────────────────────────────────────────

  Exception _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionTimeout) {
      // Fast-fail the global connectivity status
      globalConnectivityErrorController.add(null);
      return NoInternetException('Check your internet connection and try again');
    }

    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      final statusCode = e.response?.statusCode;

      if (statusCode == 401) return UnauthenticatedException();

      if (data is Map) {
        final message = data['message'] ?? 'Unknown network error';
        return ServerException(message, statusCode: statusCode);
      } else if (data is String) {
        final cleanMsg = data.length > 100 ? data.substring(0, 100) : data;
        return ServerException('Server Error ($statusCode): $cleanMsg',
            statusCode: statusCode);
      }
    }
    return ServerException(e.message ?? 'Failed to connect to backend');
  }

  Future<bool> updateFcmToken(String userId, String token) async {
    try {
      final response = await _dio.put(
        '/api/user/fcm-token',
        data: {'userId': userId, 'fcmToken': token},
      );
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getNotifications(String userId) async {
    try {
      final response = await _dio.get('/api/vendor/notifications/$userId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final response = await _dio.put(
        '/api/vendor/notifications/$notificationId/read',
      );
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead(String userId) async {
    try {
      final response = await _dio.post(
        '/api/vendor/notifications/read-all',
        data: {'userId': userId},
      );
      return response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // ── Subscriptions ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> upgradePlan(String userId, String plan) async {
    try {
      final response = await _dio.post(
        '/api/vendor/upgrade-plan',
        data: {'userId': userId, 'plan': plan},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> upgradePlanPesapal(
    String userId,
    String plan, {
    String currency = 'USD',
  }) async {
    try {
      final response = await _dio.post(
        '/api/vendor/upgrade-pesapal',
        data: {'userId': userId, 'plan': plan, 'currency': currency},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteAccount(String userId) async {
    try {
      final response = await _dio.delete('/api/user/$userId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Customer Endpoints ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCustomerRecommendedVendors() async {
    try {
      final response = await _dio.get('/api/customer/recommended-vendors');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> findCustomerMatches({
    required String eventType,
    required double budget,
    required String eventDate,
    required List<String> services,
    String? location,
    int? guestCount,
  }) async {
    try {
      final response = await _dio.post(
        '/api/customer/match',
        data: {
          'eventType': eventType,
          'budget': budget,
          'eventDate': eventDate,
          'services': services,
          if (location != null) 'location': location,
          if (guestCount != null) 'guestCount': guestCount,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Chat endpoints removed: messaging now runs entirely on Firestore +
  // Firebase Cloud Functions (see lib/features/messaging/ and
  // eventbridge_ai_app/functions/index.js). The legacy Postgres chat
  // pipeline (/api/vendor/chats/*, /api/customer/chats/*) was a second
  // identity/storage surface that split the data and silently broke
  // push notifications.

  Future<Map<String, dynamic>> getCustomerProfile(String userId) async {
    try {
      final response = await _dio.get('/api/customer/profile/$userId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateCustomerProfile({
    required String userId,
    String? name,
    String? email,
    String? imageUrl,
    String? phone,
    String? location,
  }) async {
    try {
      final response = await _dio.put(
        '/api/customer/profile/$userId',
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (imageUrl != null) 'imageUrl': imageUrl,
          if (phone != null) 'phone': phone,
          if (location != null) 'location': location,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> saveCustomerMatches({
    required String userId,
    required List<Map<String, dynamic>> matches,
  }) async {
    try {
      final response = await _dio.post(
        '/api/customer/matches',
        data: {'userId': userId, 'matches': matches},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> toggleFavorite({
    required String userId,
    required String vendorId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/customer/favorites/toggle',
        data: {'userId': userId, 'vendorId': vendorId},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<String>> getCustomerFavorites(String userId) async {
    try {
      final response = await _dio.get('/api/customer/favorites/$userId');
      if (response.data['success'] == true) {
        return List<String>.from(response.data['favoriteIds']);
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCustomerMatches(String userId) async {
    try {
      final response = await _dio.get('/api/customer/matches/$userId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _dio.get('/api/categories');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      throw Exception('Invalid response format for categories');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getNearbyVendors({
    required double lat,
    required double lng,
    double radiusKm = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/api/customer/vendors/nearby',
        queryParameters: {'lat': lat, 'lng': lng, 'radius': radiusKm},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> submitReview({
    required String vendorId,
    required String customerId,
    required double rating,
    required String comment,
  }) async {
    try {
      final response = await _dio.post(
        '/api/vendor/review',
        data: {
          'vendorId': vendorId,
          'customerId': customerId,
          'rating': rating,
          'comment': comment,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
