import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/vendor.dart';
import '../../data/repositories/vendor_repository.dart';

import 'package:eventbridge/features/matching/presentation/matching_controller.dart';

final recommendedVendorsProvider = FutureProvider<List<Vendor>>((ref) async {
  return VendorRepository().getRecommendedVendors();
});

final savedVendorsProvider = FutureProvider<List<Vendor>>((ref) async {
  final favoriteIds = ref.watch(matchingControllerProvider.select((s) => s.favoriteIds));
  final repo = VendorRepository();
  
  if (favoriteIds.isEmpty) return [];

  final List<Vendor> vendors = [];
  for (final id in favoriteIds) {
    try {
      final vendor = await repo.getVendorById(id);
      if (vendor != null) vendors.add(vendor);
    } catch (_) {}
  }
  return vendors;
});
