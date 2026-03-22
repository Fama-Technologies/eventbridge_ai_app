import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eventbridge/features/matching/data/matching_repository.dart';
import 'package:eventbridge/features/matching/models/event_request.dart';
import 'package:eventbridge/features/matching/models/match_vendor.dart';

class MatchingState {
  const MatchingState({
    this.request,
    this.matches = const [],
    this.isLoading = false,
    this.error,
    this.inquirySentVendorId,
  });

  final EventRequest? request;
  final List<MatchVendor> matches;
  final bool isLoading;
  final String? error;
  final String? inquirySentVendorId;

  MatchingState copyWith({
    EventRequest? request,
    List<MatchVendor>? matches,
    bool? isLoading,
    String? error,
    String? inquirySentVendorId,
  }) {
    return MatchingState(
      request: request ?? this.request,
      matches: matches ?? this.matches,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      inquirySentVendorId: inquirySentVendorId,
    );
  }
}

final matchingControllerProvider =
    NotifierProvider<MatchingController, MatchingState>(MatchingController.new);

class MatchingController extends Notifier<MatchingState> {
  late final MatchingRepository _repository;

  @override
  MatchingState build() {
    _repository = ref.read(matchingRepositoryProvider);
    return const MatchingState();
  }

  Future<void> searchMatches(EventRequest request) async {
    state = state.copyWith(isLoading: true, request: request, error: null);
    try {
      final matches = await _repository.findMatches(request);
      state = state.copyWith(isLoading: false, matches: matches, error: null);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to find matches. Please try again.',
      );
    }
  }

  Future<MatchVendor?> getVendorById(String id) async {
    for (final vendor in state.matches) {
      if (vendor.id == id) return vendor;
    }
    return await _repository.getVendorById(id);
  }

  Future<void> sendInquiry(MatchVendor vendor) async {
    if (state.request == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.sendInquiry(request: state.request!, vendor: vendor);
      state = state.copyWith(
        isLoading: false,
        inquirySentVendorId: vendor.id,
        error: null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send inquiry. Please try again.',
      );
    }
  }
}
