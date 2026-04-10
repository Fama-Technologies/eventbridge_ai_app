import '../../domain/models/vendor.dart';
import '../../../../core/network/api_service.dart';

class VendorRepository {
  final ApiService _apiService = ApiService();

  Future<List<Vendor>> getRecommendedVendors() async {
    try {
      final response = await _apiService.getCustomerRecommendedVendors();
      final List<dynamic> data = response['vendors'] ?? [];
      return data.map((json) => Vendor.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Vendor?> getVendorById(String id) async {
    try {
      final response = await _apiService.getVendorProfile(id);
      if (response['success'] == true && response['profile'] != null) {
        return Vendor.fromJson(response['profile']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
