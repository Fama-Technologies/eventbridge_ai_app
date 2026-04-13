import 'package:eventbridge/features/matching/domain/repositories/i_matching_repository.dart';
import 'package:eventbridge/features/matching/models/event_request.dart';
import 'package:eventbridge/features/matching/models/match_vendor.dart';

class FindMatchesUseCase {
  FindMatchesUseCase(this._repository);

  final IMatchingRepository _repository;

  Future<List<MatchVendor>> call(EventRequest request) {
    return _repository.findMatches(request);
  }
}

class SendInquiryUseCase {
  SendInquiryUseCase(this._repository);

  final IMatchingRepository _repository;

  Future<String?> call({
    required EventRequest request,
    required MatchVendor vendor,
  }) {
    return _repository.sendInquiry(request: request, vendor: vendor);
  }
}

class GetVendorByIdUseCase {
  GetVendorByIdUseCase(this._repository);

  final IMatchingRepository _repository;

  Future<MatchVendor?> call(String id) {
    return _repository.getVendorById(id);
  }
}

class SubmitReviewUseCase {
  SubmitReviewUseCase(this._repository);

  final IMatchingRepository _repository;

  Future<void> call({
    required String vendorId,
    required double rating,
    required String comment,
  }) {
    return _repository.submitReview(
      vendorId: vendorId,
      rating: rating,
      comment: comment,
    );
  }
}