import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eventbridge/features/matching/data/matching_repository.dart';
import 'package:eventbridge/features/matching/domain/repositories/i_matching_repository.dart';
import 'package:eventbridge/features/matching/domain/usecases/matching_use_cases.dart';

final matchingRepositoryContractProvider = Provider<IMatchingRepository>((ref) {
  return ref.watch(matchingRepositoryProvider);
});

final findMatchesUseCaseProvider = Provider<FindMatchesUseCase>((ref) {
  return FindMatchesUseCase(ref.watch(matchingRepositoryContractProvider));
});

final sendInquiryUseCaseProvider = Provider<SendInquiryUseCase>((ref) {
  return SendInquiryUseCase(ref.watch(matchingRepositoryContractProvider));
});

final getVendorByIdUseCaseProvider = Provider<GetVendorByIdUseCase>((ref) {
  return GetVendorByIdUseCase(ref.watch(matchingRepositoryContractProvider));
});