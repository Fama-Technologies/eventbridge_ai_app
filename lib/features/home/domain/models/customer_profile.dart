class CustomerProfile {
  final String name;
  final String email;
  final String? imageUrl;
  final String? phone;
  final String? location;

  CustomerProfile({
    required this.name,
    required this.email,
    this.imageUrl,
    this.phone,
    this.location,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      name: json['name'] as String? ?? 'Guest User',
      email: json['email'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      phone: json['phone'] as String?,
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'imageUrl': imageUrl,
      'phone': phone,
      'location': location,
    };
  }
}
