import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import '../../domain/models/customer_profile.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository());

class ProfileRepository {
  final ApiService _api = ApiService.instance;
  final StorageService _storage = StorageService();

  Future<CustomerProfile?> getCustomerProfile(String userId) async {
    try {
      final response = await _api.getCustomerProfile(userId);
      if (response['success'] == true && response['profile'] != null) {
        final profile = CustomerProfile.fromJson(response['profile']);
        
        // Enrich with local storage if fields are null coming from API
        final localPhone = _storage.getString('user_phone_$userId');
        final localLocation = _storage.getString('user_location_$userId');
        
        return CustomerProfile(
          name: profile.name,
          email: profile.email,
          imageUrl: profile.imageUrl,
          phone: profile.phone ?? localPhone,
          location: profile.location ?? localLocation,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateCustomerProfile({
    required String userId,
    String? name,
    String? email,
    String? imageUrl,
    String? phone,
    String? location,
  }) async {
    try {
      final response = await _api.updateCustomerProfile(
        userId: userId,
        name: name,
        email: email,
        imageUrl: imageUrl,
        phone: phone,
        location: location,
      );
      
      if (response['success'] == true) {
        // Cache locally since backend might not return these immediately
        if (phone != null) await _storage.setString('user_phone_$userId', phone);
        if (location != null) await _storage.setString('user_location_$userId', location);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAccount(String userId) async {
    try {
      final response = await _api.deleteAccount(userId);
      if (response['success'] == true) {
        await _storage.remove('user_phone_$userId');
        await _storage.remove('user_location_$userId');
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
