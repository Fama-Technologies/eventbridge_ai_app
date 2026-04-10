import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/features/auth/presentation/auth_provider.dart';
import '../../domain/models/customer_profile.dart';
import '../../data/repositories/profile_repository.dart';

final customerProfileProvider = FutureProvider<CustomerProfile?>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  final profileRepo = ref.watch(profileRepositoryProvider);
  final userId = authRepo.getUserId();
  
  if (userId == null || userId.isEmpty) {
    return null;
  }

  return profileRepo.getCustomerProfile(userId);
});
