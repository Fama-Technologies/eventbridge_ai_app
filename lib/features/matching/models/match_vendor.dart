class VendorPackage {
  VendorPackage({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
  });

  final String id;
  final String title;
  final String description;
  final double price;

  factory VendorPackage.fromJson(Map<String, dynamic> json) {
    return VendorPackage(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class VendorReview {
  VendorReview({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
  });

  final String id;
  final String customerName;
  final double rating;
  final String comment;

  factory VendorReview.fromJson(Map<String, dynamic> json) {
    return VendorReview(
      id: json['id']?.toString() ?? '',
      customerName: json['customer_name'] ?? '',
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      comment: json['comment'] ?? '',
    );
  }
}

class MatchVendor {
  MatchVendor({
    required this.id,
    required this.name,
    required this.businessOverview,
    required this.services,
    required this.location,
    required this.plan,
    required this.rating,
    required this.isVerified,
    required this.portfolio,
    required this.packages,
    required this.reviews,
    required this.socialLinks,
    required this.availableDates,
    this.planExpiry,
  });

  final String id;
  final String name;
  final String businessOverview;
  final List<String> services;
  final String plan;
  final DateTime? planExpiry;
  final String location;
  final double rating;
  final bool isVerified;
  final List<String> portfolio;
  final List<VendorPackage> packages;
  final List<VendorReview> reviews;
  final Map<String, String> socialLinks;
  final List<DateTime> availableDates;

  factory MatchVendor.fromJson(Map<String, dynamic> json) {
    return MatchVendor(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      businessOverview: json['business_overview'] ?? '',
      services: (json['services'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      location: json['location'] ?? '',
      plan: json['plan'] ?? 'pro', // Default to pro for initial trial
      planExpiry: json['plan_expiry'] != null ? DateTime.parse(json['plan_expiry']) : null,
      rating: (json['rating'] ?? 0.0).toDouble(),
      isVerified: json['is_verified'] ?? false,
      portfolio: (json['portfolio'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      packages: (json['packages'] as List<dynamic>?)?.map((e) => VendorPackage.fromJson(e)).toList() ?? [],
      reviews: (json['reviews'] as List<dynamic>?)?.map((e) => VendorReview.fromJson(e)).toList() ?? [],
      socialLinks: Map<String, String>.from(json['social_links'] ?? {}),
      availableDates: [],
    );
  }

  double get minPackagePrice => packages.isEmpty
      ? 0
      : packages.map((p) => p.price).reduce((a, b) => a < b ? a : b);

  bool get isPlanExpired => planExpiry != null && DateTime.now().isAfter(planExpiry!);

  int get maxPortfolioItems => plan == 'business_pro' ? 6 : 3;
}
