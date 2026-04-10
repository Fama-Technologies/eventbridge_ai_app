import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/features/home/domain/models/vendor_match.dart';
import '../../data/repositories/match_repository.dart';
import '../../../../core/storage/storage_service.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository();
});

final recentMatchesProvider = FutureProvider<List<VendorMatch>>((ref) async {
  final userId = StorageService().getString('user_id') ?? '';
  if (userId.isEmpty) return [];
  
  return ref.watch(matchRepositoryProvider).getRecentMatches(userId);
});
