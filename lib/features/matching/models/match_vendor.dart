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
  });

  final String id;
  final String name;
  final String businessOverview;
  final List<String> services;
  final String location;
  final String plan;
  final double rating;
  final bool isVerified;
  final List<String> portfolio;
  final List<VendorPackage> packages;
  final List<VendorReview> reviews;
  final Map<String, String> socialLinks;
  final List<DateTime> availableDates;

  double get minPackagePrice => packages.isEmpty
      ? 0
      : packages.map((p) => p.price).reduce((a, b) => a < b ? a : b);

  int get maxPortfolioItems => plan == 'business_pro' ? 20 : 12;
}
