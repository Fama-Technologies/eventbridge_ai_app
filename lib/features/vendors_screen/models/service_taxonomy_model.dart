class ServiceCategory {
  final int id;
  final String name;
  final String? description;

  ServiceCategory({
    required this.id,
    required this.name,
    this.description,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['category_id'] ?? json['id'],
      name: json['category_name'] ?? json['name'],
      description: json['category_description'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceCategory && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ServiceItem {
  final int id;
  final String name;
  final String? description;
  final int categoryId;
  final String categoryName;

  ServiceItem({
    required this.id,
    required this.name,
    this.description,
    required this.categoryId,
    required this.categoryName,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      categoryId: json['category_id'],
      categoryName: json['category_name'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
