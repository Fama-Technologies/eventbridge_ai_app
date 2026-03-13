import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eventbridge_ai/features/matching/models/event_request.dart';
import 'package:eventbridge_ai/features/matching/models/match_vendor.dart';

final matchingRepositoryProvider = Provider<MatchingRepository>((ref) {
  return MatchingRepository();
});

class MatchingRepository {
  Future<List<MatchVendor>> findMatches(EventRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final normalizedServices = request.services
        .map((s) => s.toLowerCase().trim())
        .toList();

    final filtered = _vendors.where((vendor) {
      final dateAvailable = vendor.availableDates.any(
        (d) =>
            d.year == request.eventDate.year &&
            d.month == request.eventDate.month &&
            d.day == request.eventDate.day,
      );

      final budgetFit = vendor.minPackagePrice <= request.budget;

      final serviceFit = normalizedServices.isEmpty
          ? true
          : normalizedServices.any(
              (s) => vendor.services.map((v) => v.toLowerCase()).contains(s),
            );

      return dateAvailable && budgetFit && serviceFit;
    }).toList();

    final ranked = filtered..sort((a, b) => b.rating.compareTo(a.rating));

    // Ensure a minimum list is shown while backend ranking is still mocked.
    final fallback = _vendors
        .where((v) => !_containsVendor(ranked, v.id))
        .take(5)
        .toList();
    return [...ranked, ...fallback].take(5).toList();
  }

  Future<void> sendInquiry({
    required EventRequest request,
    required MatchVendor vendor,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  MatchVendor? getVendorById(String id) {
    try {
      return _vendors.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  bool _containsVendor(List<MatchVendor> vendors, String id) {
    return vendors.any((v) => v.id == id);
  }

  final List<MatchVendor> _vendors = [
    MatchVendor(
      id: 'v1',
      name: 'Golden Hour Studio',
      businessOverview:
          'Wedding and event photography with cinematic edits and quick delivery.',
      services: ['photography', 'videography'],
      location: 'Kampala',
      plan: 'business_pro',
      rating: 4.9,
      isVerified: true,
      portfolio: List<String>.generate(
        20,
        (i) =>
            'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?auto=format&fit=crop&w=600&q=60',
      ),
      packages: [
        VendorPackage(
          id: 'p1',
          title: 'Classic Wedding',
          description: '8 hours, 1 photographer',
          price: 650,
        ),
        VendorPackage(
          id: 'p2',
          title: 'Cinematic Premium',
          description: '10 hours photo + video',
          price: 1200,
        ),
      ],
      reviews: [
        VendorReview(
          id: 'r1',
          customerName: 'Nina',
          rating: 5,
          comment: 'Amazing quality and timing.',
        ),
        VendorReview(
          id: 'r2',
          customerName: 'Peter',
          rating: 4.5,
          comment: 'Very professional team.',
        ),
      ],
      socialLinks: {
        'instagram': 'https://instagram.com',
        'website': 'https://example.com',
      },
      availableDates: _availability(),
    ),
    MatchVendor(
      id: 'v2',
      name: 'Elite Catering',
      businessOverview:
          'Full-service catering for weddings, birthdays, and corporate events.',
      services: ['catering'],
      location: 'Kampala',
      plan: 'pro',
      rating: 4.7,
      isVerified: true,
      portfolio: List<String>.generate(
        12,
        (i) =>
            'https://images.unsplash.com/photo-1555244162-803834f70033?auto=format&fit=crop&w=600&q=60',
      ),
      packages: [
        VendorPackage(
          id: 'p3',
          title: 'Buffet Basic',
          description: 'Up to 100 guests',
          price: 400,
        ),
        VendorPackage(
          id: 'p4',
          title: 'Premium Dining',
          description: 'Up to 200 guests',
          price: 900,
        ),
      ],
      reviews: [
        VendorReview(
          id: 'r3',
          customerName: 'Sandra',
          rating: 5,
          comment: 'Food and service were top notch.',
        ),
      ],
      socialLinks: {
        'instagram': 'https://instagram.com',
        'tiktok': 'https://tiktok.com',
      },
      availableDates: _availability(offsetDays: 1),
    ),
    MatchVendor(
      id: 'v3',
      name: 'Pulse DJs',
      businessOverview: 'Event DJ and sound setup for all major celebrations.',
      services: ['dj', 'sound'],
      location: 'Entebbe',
      plan: 'pro',
      rating: 4.6,
      isVerified: false,
      portfolio: List<String>.generate(
        12,
        (i) =>
            'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?auto=format&fit=crop&w=600&q=60',
      ),
      packages: [
        VendorPackage(
          id: 'p5',
          title: 'Party Mix',
          description: '5 hours DJ set',
          price: 300,
        ),
      ],
      reviews: [
        VendorReview(
          id: 'r4',
          customerName: 'Joan',
          rating: 4.5,
          comment: 'Great music selection.',
        ),
      ],
      socialLinks: {'facebook': 'https://facebook.com'},
      availableDates: _availability(offsetDays: 2),
    ),
    MatchVendor(
      id: 'v4',
      name: 'Bloom Decor',
      businessOverview: 'Decor and floral design for elegant events.',
      services: ['decor', 'florist'],
      location: 'Kampala',
      plan: 'business_pro',
      rating: 4.8,
      isVerified: true,
      portfolio: List<String>.generate(
        20,
        (i) =>
            'https://images.unsplash.com/photo-1520854221256-17451cc331bf?auto=format&fit=crop&w=600&q=60',
      ),
      packages: [
        VendorPackage(
          id: 'p6',
          title: 'Minimal Decor',
          description: 'Stage + center pieces',
          price: 500,
        ),
        VendorPackage(
          id: 'p7',
          title: 'Luxury Decor',
          description: 'Full premium setup',
          price: 1400,
        ),
      ],
      reviews: [
        VendorReview(
          id: 'r5',
          customerName: 'David',
          rating: 5,
          comment: 'Stunning decorations.',
        ),
      ],
      socialLinks: {
        'instagram': 'https://instagram.com',
        'website': 'https://example.com',
      },
      availableDates: _availability(offsetDays: 3),
    ),
    MatchVendor(
      id: 'v5',
      name: 'Grand Venue Spaces',
      businessOverview: 'Premium event venues and setup support.',
      services: ['venue'],
      location: 'Mukono',
      plan: 'pro',
      rating: 4.4,
      isVerified: false,
      portfolio: List<String>.generate(
        12,
        (i) =>
            'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&w=600&q=60',
      ),
      packages: [
        VendorPackage(
          id: 'p8',
          title: 'Half Day Venue',
          description: '6 hour booking',
          price: 700,
        ),
      ],
      reviews: [
        VendorReview(
          id: 'r6',
          customerName: 'Rose',
          rating: 4,
          comment: 'Nice venue and support team.',
        ),
      ],
      socialLinks: {'website': 'https://example.com'},
      availableDates: _availability(offsetDays: 4),
    ),
  ];

  static List<DateTime> _availability({int offsetDays = 0}) {
    final now = DateTime.now();
    return List<DateTime>.generate(
      30,
      (i) => DateTime(now.year, now.month, now.day + i + offsetDays),
    );
  }
}
