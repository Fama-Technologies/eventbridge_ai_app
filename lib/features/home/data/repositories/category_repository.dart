import '../../domain/models/category.dart';
import '../../../../core/network/api_service.dart';

class CategoryRepository {
  final ApiService _apiService = ApiService();

  Future<List<Category>> getCategories() async {
    try {
      final jsonList = await _apiService.getCategories();
      return jsonList.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      // Re-throw to handle it in the UI (e.g. show error message)
      rethrow;
    }
  }
}
