class Category {
  final String id;
  final String name;
  final String iconName;

  Category({
    required this.id,
    required this.name,
    required this.iconName,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] ?? json['userId'] ?? '').toString(),
      name: json['name']?.toString() ?? 'Unknown',
      iconName: json['iconName']?.toString() ?? 'help_outline',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
    };
  }
}
