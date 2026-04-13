import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eventbridge/features/matching/domain/repositories/i_matching_repository.dart';
import 'package:eventbridge/features/matching/domain/usecases/matching_use_cases.dart';
import 'package:eventbridge/features/matching/models/event_request.dart';
import 'package:eventbridge/features/matching/models/match_vendor.dart';
import 'package:eventbridge/features/matching/presentation/matching_di.dart';
import 'package:eventbridge/features/vendors_screen/models/lead_model.dart';
import 'package:eventbridge/features/shared/providers/shared_lead_state.dart';
import 'package:intl/intl.dart';

class MatchingState {
  const MatchingState({
    this.request,
    this.matches = const [],
    this.isLoading = false,
    this.error,
    this.inquirySentVendorId,
    this.favoriteIds = const {},
  });

  final EventRequest? request;
  final List<MatchVendor> matches;
  final bool isLoading;
  final String? error;
  final String? inquirySentVendorId;
  final Set<String> favoriteIds;

  MatchingState copyWith({
    EventRequest? request,
    List<MatchVendor>? matches,
    bool? isLoading,
    String? error,
    String? inquirySentVendorId,
    Set<String>? favoriteIds,
  }) {
    return MatchingState(
      request: request ?? this.request,
      matches: matches ?? this.matches,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      inquirySentVendorId: inquirySentVendorId,
      favoriteIds: favoriteIds ?? this.favoriteIds,
    );
  }
}

final matchingControllerProvider =
    NotifierProvider<MatchingController, MatchingState>(MatchingController.new);

class MatchingController extends Notifier<MatchingState> {
  late final FindMatchesUseCase _findMatches;
  late final SendInquiryUseCase _sendInquiry;
  late final GetVendorByIdUseCase _getVendorById;
  late final SubmitReviewUseCase _submitReview;
  late final IMatchingRepository _repository;

  bool _initialized = false;

  @override
  MatchingState build() {
    _findMatches = ref.watch(findMatchesUseCaseProvider);
    _sendInquiry = ref.watch(sendInquiryUseCaseProvider);
    _getVendorById = ref.watch(getVendorByIdUseCaseProvider);
    _submitReview = ref.watch(submitReviewUseCaseProvider);
    _repository = ref.watch(matchingRepositoryContractProvider);
    
    if (!_initialized) {
      _initialized = true;
      // Load favorites and matches in a deferred way
      Future.microtask(() => _initializeState());
    }
    
    return const MatchingState();
  }

  Future<void> submitReview({
    required String vendorId,
    required double rating,
    required String comment,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _submitReview(
        vendorId: vendorId,
        rating: rating,
        comment: comment,
      );
      
      // Refresh the vendor in the matches list to show updated reviews/rating
      final updatedVendor = await _getVendorById(vendorId);
      if (updatedVendor != null) {
        final newMatches = state.matches.map((v) {
          return v.id == vendorId ? updatedVendor : v;
        }).toList();
        state = state.copyWith(matches: newMatches);
      }
      
      state = state.copyWith(isLoading: false, error: null);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to submit review. Please try again.',
      );
    }
  }

  Future<void> _initializeState() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';

    await _loadFavorites(userId);
    
    // Also load persisted matches if local state is empty
    if (state.matches.isEmpty && userId.isNotEmpty) {
      final persisted = await _repository.getPersistedMatches(userId);
      if (persisted.isNotEmpty) {
        state = state.copyWith(matches: persisted);
      }
    }
  }

  Future<void> _loadFavorites(String userId) async {
    try {
      // 1. Load from local prefs for immediate UI
      final prefs = await SharedPreferences.getInstance();
      final localFavorites = prefs.getStringList('favorite_vendor_ids') ?? [];
      
      if (localFavorites.isNotEmpty) {
        state = state.copyWith(favoriteIds: localFavorites.toSet());
      }

      // 2. Sync from remote if userId exists
      if (userId.isNotEmpty) {
        final remoteFavorites = await _repository.getFavoriteIds(userId);
        if (remoteFavorites.isNotEmpty) {
          state = state.copyWith(favoriteIds: remoteFavorites.toSet());
          // Update local cache
          await prefs.setStringList('favorite_vendor_ids', remoteFavorites);
        }
      }
    } catch (_) {
      // Silently fail
    }
  }

  Future<void> toggleFavorite(String vendorId) async {
    final newFavorites = Set<String>.from(state.favoriteIds);
    final isAdding = !newFavorites.contains(vendorId);
    
    if (isAdding) {
      newFavorites.add(vendorId);
    } else {
      newFavorites.remove(vendorId);
    }
    
    state = state.copyWith(favoriteIds: newFavorites);
    
    try {
      // 1. Update local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_vendor_ids', newFavorites.toList());
      
      // 2. Update remote
      final userId = prefs.getString('user_id') ?? '';
      if (userId.isNotEmpty) {
        await _repository.toggleFavorite(userId, vendorId);
      }
    } catch (_) {}
  }

  Future<void> searchMatches(EventRequest request) async {
    state = state.copyWith(isLoading: true, request: request, error: null);
    try {
      final rawMatches = await _findMatches(request);

      // ── STEP 1: STRICT PRE-FILTERING ──────────────────────────────────────
      // Only keep vendors that match at least one requested service AND
      // whose location overlaps with the user's location string.
      final requestedServices = request.services.map((s) => s.toLowerCase()).toSet();
      final userLocation = request.location.toLowerCase().trim();

      final filtered = rawMatches.where((vendor) {
        final vendorServices = vendor.services.map((s) => s.toLowerCase()).toSet();

        // Service gate: vendor must offer at least one of the requested services.
        final serviceMatch = requestedServices.isEmpty ||
            vendorServices.intersection(requestedServices).isNotEmpty;

        // Location gate: vendor location must share keywords with user location.
        final vendorLocation = vendor.location.toLowerCase().trim();
        final locationMatch = userLocation.isEmpty ||
            vendorLocation.contains(userLocation) ||
            userLocation.contains(vendorLocation) ||
            _shareLocationKeyword(userLocation, vendorLocation);

        return serviceMatch && locationMatch;
      }).toList();

      // ── STEP 2: SCORE & SORT ───────────────────────────────────────────────
      final enhancedMatches = filtered.map((vendor) {
        final score = _calculateMatchScore(vendor, request);
        final reasons = _getMatchReasons(vendor, request);
        return vendor.copyWith(matchScore: score, matchReasons: reasons);
      }).toList();

      enhancedMatches.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      
      state = state.copyWith(isLoading: false, matches: enhancedMatches, error: null);

      // Persistence: Save to backend
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      if (userId.isNotEmpty && enhancedMatches.isNotEmpty) {
        await _repository.saveMatches(userId, enhancedMatches);
      }

    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to find matches. Please try again.',
      );
    }
  }

  /// Returns true if the two location strings share at least one meaningful keyword.
  bool _shareLocationKeyword(String a, String b) {
    final stopWords = {'the', 'of', 'in', 'at', 'and', 'or', 'to', 'a', 'an'};
    final aWords = a.split(RegExp(r'[\s,]+'))
        .map((w) => w.trim())
        .where((w) => w.length > 2 && !stopWords.contains(w))
        .toSet();
    final bWords = b.split(RegExp(r'[\s,]+'))
        .map((w) => w.trim())
        .where((w) => w.length > 2 && !stopWords.contains(w))
        .toSet();
    return aWords.intersection(bWords).isNotEmpty;
  }

  /// Plan tier ranking: higher plan = higher priority
  int _planRank(String plan) {
    switch (plan.toLowerCase()) {
      case 'business_pro':
      case 'enterprise':
        return 3;
      case 'pro':
      case 'professional':
        return 2;
      case 'basic':
      case 'starter':
        return 1;
      default:
        return 0; // free / unknown
    }
  }

  double _calculateMatchScore(MatchVendor vendor, EventRequest request) {
    double score = 0.0;

    // 1. SUBSCRIPTION PLAN TIER — highest priority (up to 0.30)
    final rank = _planRank(vendor.plan);
    score += (rank / 3.0) * 0.30;

    // 2. CATEGORY / SERVICE MATCH (up to 0.25)
    final vendorServices = vendor.services.map((s) => s.toLowerCase()).toSet();
    if (request.services.isNotEmpty) {
      final requestedServices = request.services.map((s) => s.toLowerCase()).toSet();
      final intersection = vendorServices.intersection(requestedServices);
      score += (intersection.length / requestedServices.length) * 0.25;
    } else {
      final eventType = request.eventType.toLowerCase();
      if (vendorServices.any((s) => s.contains(eventType) || eventType.contains(s))) {
        score += 0.25;
      } else if (vendorServices.isNotEmpty) {
        score += 0.10;
      }
    }

    // 3. RATINGS (up to 0.15)
    score += (vendor.rating / 5.0) * 0.15;

    // 4. LOCATION MATCH (up to 0.15)
    final userLocation = request.location.toLowerCase().trim();
    final vendorLocation = vendor.location.toLowerCase().trim();
    if (userLocation.isNotEmpty && vendorLocation.isNotEmpty) {
      if (vendorLocation == userLocation) {
        score += 0.15; // Exact match
      } else if (vendorLocation.contains(userLocation) || userLocation.contains(vendorLocation)) {
        score += 0.10; // Partial match (e.g. "Kampala" in "Kampala, Uganda")
      }
    }

    // 5. BUDGET FIT (up to 0.10)
    final price = vendor.minPackagePrice;
    if (price > 0 && request.budget > 0) {
      if (price <= request.budget) {
        score += 0.10;
      } else {
        final ratio = request.budget / price;
        if (ratio > 0.7) score += 0.10 * ratio;
      }
    } else {
      score += 0.03; // Unknown price
    }

    // 6. TRUST & ENGAGEMENT BOOST (up to 0.05)
    if (vendor.isVerified) score += 0.02;
    if (state.favoriteIds.contains(vendor.id)) score += 0.01;
    if (vendor.packages.isNotEmpty) score += 0.02;

    return score.clamp(0.0, 1.0);
  }


  List<String> _getMatchReasons(MatchVendor vendor, EventRequest request) {
    final reasons = <String>[];

    // Plan reason
    final rank = _planRank(vendor.plan);
    if (rank >= 3) {
      reasons.add('Premium Vendor');
    } else if (rank >= 2) {
      reasons.add('Pro Vendor');
    }

    // Service reasons
    final vendorServices = vendor.services.map((s) => s.toLowerCase()).toSet();
    final requestedServices = request.services.map((s) => s.toLowerCase()).toSet();
    final matches = vendorServices.intersection(requestedServices);
    if (matches.isNotEmpty) {
      reasons.add('Offers ${matches.length} requested services');
    }

    // Rating reasons
    if (vendor.rating >= 4.5) {
      reasons.add('Top Rated (${vendor.rating})');
    }

    // Budget reasons
    if (vendor.minPackagePrice > 0 && vendor.minPackagePrice <= request.budget) {
      reasons.add('Fits your budget');
    }

    // Trust reasons
    if (vendor.isVerified) {
      reasons.add('Verified Vendor');
    }

    if (state.favoriteIds.contains(vendor.id)) {
      reasons.add('In your Favorites');
    }

    return reasons;
  }

  Future<MatchVendor?> getVendorById(String id) async {
    for (final vendor in state.matches) {
      if (vendor.id == id) return vendor;
    }
    final fetched = await _getVendorById(id);
    if (fetched != null && !state.matches.any((v) => v.id == fetched.id)) {
      state = state.copyWith(matches: [...state.matches, fetched]);
    }
    return fetched;
  }

  Future<String?> sendInquiry({required MatchVendor vendor, EventRequest? request}) async {
    final effectiveRequest = request ?? state.request;
    if (effectiveRequest == null) {
      state = state.copyWith(error: 'Missing inquiry details.');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final leadId = await _sendInquiry(request: effectiveRequest, vendor: vendor);
      
      final storage = await SharedPreferences.getInstance();
      final customerId = storage.getString('user_id') ?? '';

      // Update local shared state so the vendor sees it immediately
      final newLead = Lead(
        id: 'user_inquiry_${DateTime.now().millisecondsSinceEpoch}',
        customerId: customerId,
        title: effectiveRequest.eventType,
        date: DateFormat('MMM dd, yyyy').format(effectiveRequest.eventDate),
        time: effectiveRequest.eventTime ?? 'TBD',
        location: effectiveRequest.location,
        matchScore: (vendor.matchScore * 100).toInt(),
        budget: effectiveRequest.budget,
        guests: effectiveRequest.guestCount ?? 0,
        responseTime: 'Active now',
        clientName: 'You (Customer)',
        clientMessage: effectiveRequest.prompt,
        venueName: 'TBD',
        venueAddress: effectiveRequest.location,
        clientImageUrl: 'https://ui-avatars.com/api/?name=Customer&background=E2E8F0&color=475569',
        isHighValue: effectiveRequest.budget > 1000000,
        lastActive: 'Just now',
        isAccepted: false,
      );
      
      ref.read(sharedLeadStateProvider.notifier).addLead(newLead);

      state = state.copyWith(
        isLoading: false,
        inquirySentVendorId: vendor.id,
        error: null,
      );
      return leadId;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send inquiry. Please try again.',
      );
      return null;
    }
  }
}
