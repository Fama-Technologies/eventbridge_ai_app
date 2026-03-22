import 'package:eventbridge/core/services/notification_service.dart';
import 'dart:math';

class SuggestionService {
  static final SuggestionService _instance = SuggestionService._internal();
  factory SuggestionService() => _instance;
  SuggestionService._internal();

  final List<String> _suggestions = [
    "We found a perfect florist for your upcoming wedding! 🌸",
    "Don't forget to book your venue before the weekend rush! 🏰",
    "Check out these top-rated photographers in your area. 📸",
    "Your event is in 30 days! Ready to finalize the catering? 🍽️",
    "Need help with decorations? Our AI suggests these trendy vendors. ✨",
  ];

  Future<void> sendRandomFriendlySuggestion() async {
    final random = Random();
    final index = random.nextInt(_suggestions.length);
    final suggestion = _suggestions[index];

    await NotificationService().showLocalOnlyNotification(
      title: 'Friendly Suggestion',
      body: suggestion,
      payload: 'vendor:rec_${random.nextInt(100)}',
    );
  }

  Future<void> sendSpecificSuggestion({
    required String title,
    required String body,
    String? vendorId,
  }) async {
    await NotificationService().showLocalOnlyNotification(
      title: title,
      body: body,
      payload: vendorId != null ? 'vendor:$vendorId' : null,
    );
  }
}
