class VendorMatch {
  final String id;
  final String vendorId;
  final String vendorName;
  final String? imageUrl;
  final List<String> images;
  final String location;
  final double rating;
  final String eventType;
  final DateTime eventDate;
  final double budget;
  final String status;
  final double matchScore;
  final List<String> matchReasons;
  final DateTime createdAt;

  VendorMatch({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    this.imageUrl,
    this.images = const [],
    required this.location,
    this.rating = 4.5,
    required this.eventType,
    required this.eventDate,
    required this.budget,
    required this.status,
    required this.matchScore,
    this.matchReasons = const [],
    required this.createdAt,
  });

  factory VendorMatch.fromJson(Map<String, dynamic> json) {
    return VendorMatch(
      id: json['id']?.toString() ?? '',
      vendorId: json['vendorId']?.toString() ?? '',
      vendorName: json['vendorName'] ?? 'Unknown Vendor',
      imageUrl: json['imageUrl']?.toString(),
      images: json['images'] is List 
          ? List<String>.from(json['images'])
          : [],
      location: json['location'] ?? 'Kampala',
      rating: (json['rating'] ?? 4.5).toDouble(),
      eventType: json['eventType'] ?? 'Unknown Event',
      eventDate: json['eventDate'] != null 
          ? DateTime.parse(json['eventDate'])
          : DateTime.now(),
      budget: (json['budget'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      matchScore: (json['matchScore'] ?? 0.0).toDouble(),
      matchReasons: json['matchReasons'] is List 
          ? List<String>.from(json['matchReasons'])
          : [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
