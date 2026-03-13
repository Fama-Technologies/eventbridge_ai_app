import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Loads the mock REST API data from assets/mock/api_mock.json.
///
/// Usage:
///   final api = await MockApiService.instance;
///   final leads = await api.getLeads();
///
/// When the real backend is ready, implement [ApiService] with RealApiService
/// (using NetworkService / Dio) and swap the provider in one place.
class MockApiService {
  static MockApiService? _instance;
  late final Map<String, dynamic> _data;

  static const String _fallbackMockJson = '''
{
  "mock_data": {
    "auth": {
      "current_user_customer": {
        "id": "usr_001",
        "role": "customer",
        "full_name": "Alex Rivera",
        "email": "alex@example.com",
        "is_verified": true
      },
      "current_user_vendor": {
        "id": "usr_002",
        "role": "vendor",
        "full_name": "Elite Events",
        "email": "elite@example.com",
        "is_verified": true
      },
      "token": "mock_token"
    },
    "vendors": [],
    "packages": [],
    "leads": [],
    "events": [],
    "conversations": [],
    "messages": {},
    "notifications": [],
    "vendor_analytics": {
      "vendor_id": "usr_002",
      "period": "last_30_days",
      "total_leads": 0,
      "accepted_leads": 0,
      "acceptance_rate": 0.0,
      "total_revenue": 0.0,
      "currency": "USD",
      "profile_views": 0,
      "response_rate": 0.0,
      "avg_rating": 0.0,
      "reviews_this_period": 0
    }
  }
}
''';

  MockApiService._(this._data);

  /// Returns the singleton, loading the JSON once.
  static Future<MockApiService> get instance async {
    if (_instance != null) return _instance!;
    String raw;
    try {
      raw = await rootBundle.loadString('assets/mock/api_mock.json');
      if (raw.trim().isEmpty) {
        raw = _fallbackMockJson;
      }
    } catch (_) {
      raw = _fallbackMockJson;
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _instance = MockApiService._(json['mock_data'] as Map<String, dynamic>);
    return _instance!;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _list(String key) =>
      (_data[key] as List).cast<Map<String, dynamic>>();

  Map<String, dynamic> _map(String key) => _data[key] as Map<String, dynamic>;

  // ── Auth ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    await _fakeDelay();
    return {
      'token': _map('auth')['token'],
      'user': _map('auth')['current_user_customer'],
    };
  }

  Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String password,
    String role = 'customer',
  }) async {
    await _fakeDelay();
    final userKey = role == 'vendor'
        ? 'current_user_vendor'
        : 'current_user_customer';
    return {'token': _map('auth')['token'], 'user': _map('auth')[userKey]};
  }

  Future<Map<String, dynamic>> getMe() async {
    await _fakeDelay();
    return _map('auth')['current_user_customer'] as Map<String, dynamic>;
  }

  // ── Vendors ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getVendors({
    String? category,
    String? location,
  }) async {
    await _fakeDelay();
    var vendors = _list('vendors');
    if (category != null) {
      vendors = vendors
          .where(
            (v) =>
                (v['category'] as String).toLowerCase() ==
                category.toLowerCase(),
          )
          .toList();
    }
    if (location != null) {
      vendors = vendors
          .where(
            (v) => (v['location'] as String).toLowerCase().contains(
              location.toLowerCase(),
            ),
          )
          .toList();
    }
    return vendors;
  }

  Future<Map<String, dynamic>?> getVendorById(String id) async {
    await _fakeDelay();
    try {
      return _list('vendors').firstWhere((v) => v['id'] == id);
    } catch (_) {
      return null;
    }
  }

  // ── Packages ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPackages(String vendorId) async {
    await _fakeDelay();
    return _list('packages').where((p) => p['vendor_id'] == vendorId).toList();
  }

  // ── Leads ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getLeads({String? status}) async {
    await _fakeDelay();
    var leads = _list('leads');
    if (status != null) {
      leads = leads.where((l) => l['status'] == status).toList();
    }
    return leads;
  }

  Future<Map<String, dynamic>?> getLeadById(String id) async {
    await _fakeDelay();
    try {
      return _list('leads').firstWhere((l) => l['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> acceptLead(String leadId) async {
    await _fakeDelay();
    return {'message': 'Lead accepted.', 'conversation_id': 'conv_001'};
  }

  Future<Map<String, dynamic>> declineLead(String leadId) async {
    await _fakeDelay();
    return {'message': 'Lead declined.'};
  }

  // ── Events ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getEvents({String? status}) async {
    await _fakeDelay();
    var events = _list('events');
    if (status != null) {
      events = events.where((e) => e['status'] == status).toList();
    }
    return events;
  }

  Future<Map<String, dynamic>?> getEventById(String id) async {
    await _fakeDelay();
    try {
      return _list('events').firstWhere((e) => e['id'] == id);
    } catch (_) {
      return null;
    }
  }

  // ── Conversations & Messages ───────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getConversations() async {
    await _fakeDelay();
    return _list('conversations');
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    await _fakeDelay();
    final messages = _map('messages');
    if (messages.containsKey(conversationId)) {
      return (messages[conversationId] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getNotifications({bool? isRead}) async {
    await _fakeDelay();
    var notifications = _list('notifications');
    if (isRead != null) {
      notifications = notifications
          .where((n) => n['is_read'] == isRead)
          .toList();
    }
    return notifications;
  }

  // ── Analytics ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getVendorAnalytics() async {
    await _fakeDelay();
    return _map('vendor_analytics');
  }

  // ── Util ──────────────────────────────────────────────────────────────────

  /// Simulates network latency so the UI behaves as it will with a real API.
  Future<void> _fakeDelay([int ms = 300]) =>
      Future.delayed(Duration(milliseconds: ms));
}
