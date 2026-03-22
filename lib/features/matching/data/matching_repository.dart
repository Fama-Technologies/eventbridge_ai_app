import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/features/matching/models/match_vendor.dart';
import 'package:eventbridge/features/matching/models/event_request.dart';

final matchingRepositoryProvider = Provider<MatchingRepository>((ref) {
  return MatchingRepository();
});

class MatchingRepository {
  Future<List<MatchVendor>> findMatches(EventRequest request) async {
    try {
      final response = await ApiService.instance.findCustomerMatches(
        eventType: request.eventType,
        budget: request.budget,
        eventDate: request.eventDate.toIso8601String(),
        services: request.services,
      );

      if (response['success'] == true) {
        final matchesRaw = response['matches'] as List;
        return matchesRaw.map((v) => MatchVendor.fromJson(v)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> sendInquiry({
    required EventRequest request,
    required MatchVendor vendor,
  }) async {
    // Lead generation logic would go here
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  Future<MatchVendor?> getVendorById(String id) async {
    try {
      final response = await ApiService.instance.getVendorProfile(id);
      if (response['success'] == true) {
        final p = response['profile'];
        return MatchVendor(
            id: id,
            name: p['businessName'] ?? '',
            businessOverview: p['description'] ?? '',
            services: (p['serviceCategories'] as List<dynamic>?)?.map((s) => s.toString()).toList() ?? [],
            location: p['location'] ?? '',
            plan: 'pro',
            rating: 4.5,
            isVerified: true,
            portfolio: (p['galleryUrls'] as List<dynamic>?)?.map((g) => g is Map ? g['url'].toString() : g.toString()).toList() ?? [],
            packages: (p['packages'] as List<dynamic>?)?.map((pkg) => VendorPackage.fromJson(pkg)).toList() ?? [],
            reviews: [],
            socialLinks: {},
            availableDates: []
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
