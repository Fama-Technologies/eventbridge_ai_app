
import 'dart:convert';

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

class VendorProject {
  VendorProject({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.images,
  });

  final String id;
  final String title;
  final String thumbnail;
  final List<String> images;

  factory VendorProject.fromJson(Map<String, dynamic> json) {
    return VendorProject(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'Untitled Project',
      thumbnail: json['thumbnail'] ?? (json['images'] is List && (json['images'] as List).isNotEmpty ? json['images'][0] : ''),
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'thumbnail': thumbnail,
    'images': images,
  };
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
    this.avatarUrl,
    required this.portfolio,
    required this.projects,
    required this.packages,
    required this.reviews,
    required this.socialLinks,
    required this.availableDates,
    this.planExpiry,
    this.matchScore = 0.0,
    this.matchReasons = const [],
    this.latitude,
    this.longitude,
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
  final String? avatarUrl;
  final List<String> portfolio;
  final List<VendorProject> projects;
  final List<VendorPackage> packages;
  final List<VendorReview> reviews;
  final Map<String, String> socialLinks;
  final List<DateTime> availableDates;
  final double matchScore;
  final List<String> matchReasons;
  final double? latitude;
  final double? longitude;

  MatchVendor copyWith({
    String? id,
    String? name,
    String? businessOverview,
    List<String>? services,
    String? plan,
    DateTime? planExpiry,
    String? location,
    double? rating,
    bool? isVerified,
    String? avatarUrl,
    List<String>? portfolio,
    List<VendorProject>? projects,
    List<VendorPackage>? packages,
    List<VendorReview>? reviews,
    Map<String, String>? socialLinks,
    List<DateTime>? availableDates,
    double? matchScore,
    List<String>? matchReasons,
    double? latitude,
    double? longitude,
  }) {
    return MatchVendor(
      id: id ?? this.id,
      name: name ?? this.name,
      businessOverview: businessOverview ?? this.businessOverview,
      services: services ?? this.services,
      plan: plan ?? this.plan,
      planExpiry: planExpiry ?? this.planExpiry,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      isVerified: isVerified ?? this.isVerified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      portfolio: portfolio ?? this.portfolio,
      projects: projects ?? this.projects,
      packages: packages ?? this.packages,
      reviews: reviews ?? this.reviews,
      socialLinks: socialLinks ?? this.socialLinks,
      availableDates: availableDates ?? this.availableDates,
      matchScore: matchScore ?? this.matchScore,
      matchReasons: matchReasons ?? this.matchReasons,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  static String _getSafeUrl(dynamic url) {
    if (url == null) return '';
    
    if (url is Map && url.containsKey('url')) {
      return _getSafeUrl(url['url']);
    }

    String urlStr = url.toString();
    
    int maxDepth = 3;
    while (urlStr.startsWith('{') && urlStr.contains('url') && maxDepth > 0) {
      maxDepth--;
      try {
        final decoded = jsonDecode(urlStr);
        if (decoded is Map && decoded.containsKey('url')) {
          final next = decoded['url'];
          urlStr = next is String ? next : next.toString();
          continue;
        }
      } catch (_) {}
      
      // Fallback regex if it's a malformed JSON string (e.g Dart map toString)
      final regex = RegExp(r'"url"\s*:\s*"([^"]+)"');
      final match = regex.firstMatch(urlStr);
      if (match != null && match.group(1) != null) {
        urlStr = match.group(1)!;
        continue;
      }
      
      // Secondary regex for unquoted keys
      final regex2 = RegExp(r'url\s*:\s*([^,}]+)');
      final match2 = regex2.firstMatch(urlStr);
      if (match2 != null && match2.group(1) != null) {
        urlStr = match2.group(1)!.trim();
        continue;
      }
      
      break;
    }
    
    return urlStr;
  }

  factory MatchVendor.fromJson(Map<String, dynamic> json) {
    final rawPortfolio = (json['portfolio'] as List<dynamic>?)?.map((e) => _getSafeUrl(e)).toList() ?? [];
    final galleryData = json['galleryUrls'] as List<dynamic>?;
    final rawGallery = galleryData?.map((e) => _getSafeUrl(e is Map ? e['url'] : e)).toList() ?? [];
    
    final avatarUrl = _getSafeUrl(json['avatarUrl'] ?? json['avatar_url']);
    
    // Ensure avatar isn't in portfolio/gallery lists if possible
    final portfolioRaw = rawPortfolio.isNotEmpty ? rawPortfolio : rawGallery;
    final cleanPortfolio = portfolioRaw.where((url) => url != avatarUrl).toList();
    
    // Prioritize 'projects' field from API
    List<VendorProject> projects = [];
    if (json['projects'] != null && (json['projects'] as List).isNotEmpty) {
      projects = (json['projects'] as List).map((e) => VendorProject.fromJson(e)).toList();
    } else if (galleryData != null && galleryData.isNotEmpty) {
      // Fallback: Group galleryUrls by category into projects
      final Map<String, List<String>> groups = {};
      for (var item in galleryData) {
        if (item is Map) {
          final cat = item['category']?.toString() ?? 'Other';
          final url = _getSafeUrl(item['url']);
          if (url.isNotEmpty) {
            groups.putIfAbsent(cat, () => []).add(url);
          }
        }
      }
      
      if (groups.isNotEmpty) {
        projects = groups.entries.map((entry) => VendorProject(
          id: entry.key,
          title: entry.key,
          thumbnail: entry.value.first,
          images: entry.value,
        )).toList();
      }
    }

    // Secondary fallback for very old data
    if (projects.isEmpty && cleanPortfolio.isNotEmpty) {
      projects = [
        VendorProject(
          id: 'default',
          title: 'General Portfolio',
          thumbnail: cleanPortfolio.first,
          images: cleanPortfolio,
        )
      ];
    } else if (projects.isEmpty && avatarUrl.isNotEmpty) {
       projects = [
        VendorProject(
          id: 'avatar',
          title: 'Profile',
          thumbnail: avatarUrl,
          images: [avatarUrl],
        )
      ];
    }

    return MatchVendor(
      id: json['id']?.toString() ?? json['vendorId']?.toString() ?? json['vendor_profile_id']?.toString() ?? '',
      name: json['name'] ?? json['businessName'] ?? json['business_name'] ?? '',
      businessOverview: json['business_overview'] ?? json['businessOverview'] ?? json['description'] ?? '',
      services: (json['services'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? 
                (json['serviceCategories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? 
                (json['services_list'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      location: json['location'] ?? 'Unknown location',
      plan: json['plan'] ?? json['subscriptionPlan'] ?? json['subscription_status'] ?? 'pro',
      planExpiry: json['plan_expiry'] != null ? DateTime.tryParse(json['plan_expiry']) : null,
      rating: double.tryParse((json['rating'] ?? json['averageRating'] ?? json['average_rating'] ?? 0.0).toString()) ?? 0.0,
      isVerified: json['is_verified'] ?? json['isVerified'] ?? json['isVerifiedBadge'] ?? (json['verification_status'] == 'verified') ?? false,
      avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
      portfolio: cleanPortfolio.isNotEmpty ? cleanPortfolio : (avatarUrl.isNotEmpty ? [avatarUrl] : []),
      projects: projects,
      packages: (json['packages'] as List<dynamic>?)?.map((e) => VendorPackage.fromJson(e)).toList() ?? [],
      reviews: (json['reviews'] as List<dynamic>?)?.map((e) => VendorReview.fromJson(e)).toList() ?? [],
      socialLinks: Map<String, String>.from(json['social_links'] ?? {}),
      availableDates: (json['blockedDates'] as List<dynamic>?)?.map((e) => DateTime.tryParse(e.toString())).whereType<DateTime>().toList() ?? [],
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
    );
  }

  double get minPackagePrice => packages.isEmpty
      ? 0
      : packages.map((p) => p.price).reduce((a, b) => a < b ? a : b);

  bool get isPlanExpired => planExpiry != null && DateTime.now().isAfter(planExpiry!);

  int get maxPortfolioItems => plan == 'business_pro' ? 6 : 3;
}
