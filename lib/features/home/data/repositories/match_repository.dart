import 'package:eventbridge/features/home/domain/models/vendor_match.dart';
import '../../../../core/network/api_service.dart';

class MatchRepository {
  final ApiService _apiService = ApiService.instance;

  Future<List<VendorMatch>> getRecentMatches(String userId) async {
    try {
      final response = await _apiService.getCustomerMatches(userId);
      if (response['success'] == true) {
        final List matchesRaw = response['matches'] ?? [];
        return matchesRaw.map((m) => VendorMatch.fromJson(m)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
