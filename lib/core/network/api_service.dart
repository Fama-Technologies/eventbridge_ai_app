import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
    List<String>? eventCategories,
    String? avatarUrl,
    List<dynamic>? galleryUrls,
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

  // ── Leads ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getVendorLeads(String userId, {String? status}) async {
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

  // ── Messaging ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getVendorChats(String userId) async {
    try {
      final response = await _dio.get('/api/vendor/chats/$userId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getChatMessages(String chatId) async {
    try {
      final response = await _dio.get('/api/vendor/chats/$chatId/messages');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> sendChatMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? imageUrl,
  }) async {
    try {
      final response = await _dio.post(
        '/api/vendor/chats/$chatId/messages',
        data: {
          'senderId': senderId,
          'text': text,
          if (imageUrl != null) 'imageUrl': imageUrl,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await _dio.post(
        '/api/vendor/chats/$chatId/typing',
        data: {'userId': userId, 'isTyping': isTyping},
      );
    } on DioException catch (e) {
      debugPrint('Typing Error: $e');
    }
  }

  Future<void> markChatAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      await _dio.post(
        '/api/vendor/chats/$chatId/read',
        data: {'userId': userId},
      );
    } on DioException catch (e) {
      debugPrint('Read Status Error: $e');
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
  }) async {
    try {
      final response = await _dio.post('/api/vendor/bookings', data: {
        'userId': userId,
        'bookingDate': bookingDate,
        'clientName': clientName,
        'eventType': eventType,
        'totalPrice': totalPrice,
        'notes': notes,
      });
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
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map) {
        final message = data['message'] ?? 'Unknown network error';
        return Exception(message);
      } else if (data is String) {
        // Handle HTML or text error pages
        final cleanMsg = data.length > 100 ? data.substring(0, 100) : data;
        return Exception('Server Error (${e.response?.statusCode}): $cleanMsg');
      }
    }
    return Exception(e.message ?? 'Failed to connect to backend');
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
      final response = await _dio.put('/api/vendor/notifications/$notificationId/read');
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

  Future<Map<String, dynamic>> upgradePlanPesapal(String userId, String plan, {String currency = 'USD'}) async {
    try {
      final response = await _dio.post(
        '/api/vendor/upgrade-pesapal',
        data: {
          'userId': userId,
          'plan': plan,
          'currency': currency,
        },
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
  }) async {
    try {
      final response = await _dio.post(
        '/api/customer/match',
        data: {
          'eventType': eventType,
          'budget': budget,
          'eventDate': eventDate,
          'services': services,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCustomerChats(String userId) async {
    try {
      final response = await _dio.get('/api/customer/chats/$userId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

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
  }) async {
    try {
      final response = await _dio.put(
        '/api/customer/profile/$userId',
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (imageUrl != null) 'imageUrl': imageUrl,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> initChat(String customerId, String vendorId) async {
    try {
      final response = await _dio.post(
        '/api/customer/chats/init',
        data: {
          'customerId': customerId,
          'vendorId': vendorId,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCustomerChatMessages(String chatId) async {
    try {
      final response = await _dio.get('/api/customer/chats/$chatId/messages');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> sendCustomerChatMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? imageUrl,
  }) async {
    try {
      final response = await _dio.post(
        '/api/customer/chats/$chatId/messages',
        data: {
          'senderId': senderId,
          'text': text,
          if (imageUrl != null) 'imageUrl': imageUrl,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
