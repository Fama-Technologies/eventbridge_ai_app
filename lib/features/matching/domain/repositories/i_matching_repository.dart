import 'package:eventbridge/features/matching/models/event_request.dart';
import 'package:eventbridge/features/matching/models/match_vendor.dart';

abstract class IMatchingRepository {
  Future<List<MatchVendor>> findMatches(EventRequest request);

  Future<void> sendInquiry({
    required EventRequest request,
    required MatchVendor vendor,
  });

  Future<MatchVendor?> getVendorById(String id);
}