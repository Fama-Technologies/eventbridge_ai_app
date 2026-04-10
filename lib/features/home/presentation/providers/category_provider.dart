import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/category.dart';
import '../../data/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final categoryProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategories();
});
