class CustomerProfile {
  final String name;
  final String email;
  final String? imageUrl;
  final String? phone;
  final String? location;
  final int likesCount;
  final int reviewsCount;
  final int packagesCount;

  CustomerProfile({
    required this.name,
    required this.email,
    this.imageUrl,
    this.phone,
    this.location,
    this.likesCount = 0,
    this.reviewsCount = 0,
    this.packagesCount = 0,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      name: json['name'] as String? ?? 'Guest User',
      email: json['email'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      phone: json['phone'] as String?,
      location: json['location'] as String?,
      likesCount: json['likesCount'] as int? ?? 0,
      reviewsCount: json['reviewsCount'] as int? ?? 0,
      packagesCount: json['packagesCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'imageUrl': imageUrl,
      'phone': phone,
      'location': location,
      'likesCount': likesCount,
      'reviewsCount': reviewsCount,
      'packagesCount': packagesCount,
    };
  }
}
