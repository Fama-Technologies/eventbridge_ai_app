import 'package:eventbridge/features/matching/models/event_request.dart';
import 'package:eventbridge/features/matching/models/match_vendor.dart';

abstract class IMatchingRepository {
  Future<List<MatchVendor>> findMatches(EventRequest request);

  Future<String?> sendInquiry({
    required EventRequest request,
    required MatchVendor vendor,
  });

  Future<MatchVendor?> getVendorById(String id);

  Future<void> submitReview({
    required String vendorId,
    required double rating,
    required String comment,
  });

  Future<void> saveMatches(String userId, List<MatchVendor> matches);

  Future<List<MatchVendor>> getPersistedMatches(String userId);

  Future<bool> toggleFavorite(String userId, String vendorId);

  Future<List<String>> getFavoriteIds(String userId);
}