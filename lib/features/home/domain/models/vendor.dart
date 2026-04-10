import 'dart:convert';
import '../../../../features/matching/models/match_vendor.dart';

class Vendor {
  final String id;
  final String businessName;
  final String location;
  final List<String> serviceCategories;
  final String? avatarUrl;
  final List<String> images;
  final double rating;
  final String? price;
  final List<VendorProject> projects;

  Vendor({
    required this.id,
    required this.businessName,
    required this.location,
    required this.serviceCategories,
    this.avatarUrl,
    this.images = const [],
    this.rating = 4.5,
    this.price,
    this.matchScore = 0.0,
    this.matchReasons = const [],
    this.projects = const [],
  });

  final double matchScore;
  final List<String> matchReasons;

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
      break;
    }
    
    return urlStr;
  }

  factory Vendor.fromJson(Map<String, dynamic> json) {
    // 1. Identify all possible image sources
    final avatarUrl = _getSafeUrl(json['avatarUrl'] ?? json['avatar_url']);
    
    // Portfolio images
    final rawPortfolio = (json['portfolio'] as List<dynamic>?)?.map((e) => _getSafeUrl(e)).toList() ?? [];
    
    // Gallery images
    final galleryData = json['galleryUrls'] as List<dynamic>?;
    final rawGallery = galleryData?.map((e) => _getSafeUrl(e is Map ? e['url'] : e)).toList() ?? [];
    
    // Projects
    List<VendorProject> projects = [];
    if (json['projects'] != null && (json['projects'] as List).isNotEmpty) {
      projects = (json['projects'] as List).map((e) => VendorProject.fromJson(e)).toList();
    }

    // 2. Flatten all images for the card preview
    final List<String> flattenedImages = [];
    
    // Priority 1: Explicit 'images' field (if exists)
    if (json['images'] is List) {
      flattenedImages.addAll(List<String>.from(json['images']));
    }
    
    // Priority 2: Project images
    for (var project in projects) {
      flattenedImages.addAll(project.images);
    }
    
    // Priority 3: Portfolio/Gallery fallbacks
    if (flattenedImages.isEmpty) {
      flattenedImages.addAll(rawPortfolio);
      flattenedImages.addAll(rawGallery);
    }
    
    // Clean up duplicates and empty strings
    final finalImages = flattenedImages.where((url) => url.isNotEmpty).toSet().toList();

    return Vendor(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? json['vendorId']?.toString() ?? '',
      businessName: json['businessName'] ?? json['name'] ?? 'Unknown Business',
      location: json['location'] ?? 'Kampala',
      serviceCategories: (json['serviceCategories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? 
                         (json['services'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
      images: finalImages,
      rating: (json['rating'] ?? json['averageRating'] ?? 4.5).toDouble(),
      price: json['price']?.toString(),
      matchScore: (json['matchScore'] ?? 0.0).toDouble(),
      matchReasons: json['matchReasons'] is List 
          ? List<String>.from(json['matchReasons'])
          : [],
      projects: projects,
    );
  }
}
