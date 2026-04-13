import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/features/matching/domain/repositories/i_matching_repository.dart';
import 'package:eventbridge/features/matching/models/match_vendor.dart';
import 'package:eventbridge/features/matching/models/event_request.dart';
import 'package:eventbridge/features/messaging/data/datasources/firestore_chat_source.dart';

import 'package:eventbridge/features/shared/providers/shared_lead_state.dart';
import 'package:eventbridge/features/vendors_screen/models/lead_model.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/features/home/presentation/providers/match_provider.dart';

final matchingRepositoryProvider = Provider<MatchingRepository>((ref) {
  return MatchingRepository(ref);
});

class MatchingRepository implements IMatchingRepository {
  final Ref ref;
  MatchingRepository(this.ref);

  @override
  Future<List<MatchVendor>> findMatches(EventRequest request) async {
    try {
      final response = await ApiService.instance.findCustomerMatches(
        eventType: request.eventType,
        budget: request.budget,
        eventDate: request.eventDate.toIso8601String(),
        services: request.services,
        location: request.location,
        guestCount: request.guestCount,
      );

      if (response['success'] == true) {
        final matchesRaw = response['matches'] as List;
        return matchesRaw.map((v) => MatchVendor.fromJson(v)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<String?> sendInquiry({
    required EventRequest request,
    required MatchVendor vendor,
  }) async {
    final storage = StorageService();
    final customerId = storage.getString('user_id') ?? 'usr_001';
    final customerName = storage.getString('user_name') ?? 'Customer';
    final customerPhotoUrl = storage.getString('user_image') ?? '';
    final initialMessage = request.prompt.isNotEmpty
        ? request.prompt
        : 'I would like to inquire about your services.';
    String? leadId;

    String customerPhone = '';
    try {
      final customerProfile = await ApiService.instance.getCustomerProfile(
        customerId,
      );
      final profile = customerProfile['profile'] as Map<String, dynamic>?;
      customerPhone = profile?['phone']?.toString() ?? '';
    } catch (_) {
      // Best effort only; chat bootstrap should not fail on missing profile data.
    }

    // 1. Persist the lead on the backend so the vendor can see it
    try {
      final leadResponse = await ApiService.instance.createLead(
        vendorId: vendor.id,
        customerId: customerId,
        title: request.eventType,
        eventDate: request.eventDate.toIso8601String().split('T')[0],
        eventTime: request.eventTime ?? 'TBD',
        location: request.location.isNotEmpty ? request.location : 'TBD',
        budget: request.budget,
        guests: request.guestCount ?? 0,
        clientMessage: initialMessage,
      );
      final lead = leadResponse['lead'];
      leadId =
          leadResponse['id']?.toString() ??
          (lead is Map<String, dynamic> ? lead['id']?.toString() : null) ??
          (lead is Map ? lead['id']?.toString() : null);
    } catch (e) {
      // Keep the Firestore chat bootstrap resilient even if lead creation fails.
    }

    // 2. Bootstrap the Firestore chat that powers the unified messaging UI.
    final firestoreChatSource = FirestoreChatSource();
    final chat = await firestoreChatSource.createOrGetChat(
      customerId: customerId,
      vendorId: vendor.id,
      customerName: customerName,
      customerPhotoUrl: customerPhotoUrl,
      customerPhone: customerPhone,
      vendorName: vendor.name,
      vendorPhotoUrl: vendor.avatarUrl ?? '',
      vendorPhone: '',
      leadId: leadId,
    );
    final chatId =
        chat?.id ?? FirestoreChatSource.chatId(customerId, vendor.id);

    if (chat != null) {
      await firestoreChatSource.sendMessage(
        chatId: chat.id,
        senderId: customerId,
        text: initialMessage,
      );
    }

    // 3. Create the optimistic Lead object locally for vendor-facing lead state.
    final userEmail = storage.getString('user_email') ?? 'customer@example.com';
    final userName = userEmail.split('@').first;

    final resultLead = Lead(
      id: leadId ?? chatId,
      customerId: customerId,
      title: request.eventType,
      date: request.eventDate.toIso8601String().split('T')[0],
      time: request.eventTime ?? 'TBD',
      location: request.location.isNotEmpty ? request.location : 'TBD',
      matchScore: vendor.matchScore.toInt(),
      budget: request.budget,
      guests: request.guestCount ?? 0,
      responseTime: '5m',
      clientName: userName,
      clientMessage: initialMessage,
      venueName: 'TBD',
      venueAddress: 'TBD',
      clientImageUrl:
          'https://ui-avatars.com/api/?name=$userName&background=random',
      isHighValue: request.budget > 50000,
      lastActive: 'Active now',
      isAccepted: false,
      phoneNumber: customerPhone,
    );

    // 3. Add to the shared global lead state
    ref.read(sharedLeadStateProvider.notifier).addLead(resultLead);

    // 4. Invalidate the recent matches so the Inquiries tab updates
    ref.invalidate(recentMatchesProvider);

    await Future<void>.delayed(const Duration(milliseconds: 600));

    return leadId ?? chatId;
  }

  @override
  Future<MatchVendor?> getVendorById(String id) async {
    try {
      final response = await ApiService.instance.getVendorProfile(id);
      if (response['success'] == true) {
        final p = response['profile'];
        return MatchVendor.fromJson(p);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> submitReview({
    required String vendorId,
    required double rating,
    required String comment,
  }) async {
    final storage = StorageService();
    final customerId = storage.getString('user_id') ?? '';
    
    if (customerId.isEmpty) return;

    await ApiService.instance.submitReview(
      vendorId: vendorId,
      customerId: customerId,
      rating: rating,
      comment: comment,
    );
  }

  @override
  Future<void> saveMatches(String userId, List<MatchVendor> matches) async {
    try {
      final List<Map<String, dynamic>> matchesData = matches.map((m) => {
        'vendorId': m.id,
        'matchScore': m.matchScore / 100.0, // Normalize to 0-1 range for DB if needed
      }).toList();

      await ApiService.instance.saveCustomerMatches(
        userId: userId,
        matches: matchesData,
      );
    } catch (e) {
      print('Error saving matches: $e');
    }
  }

  @override
  Future<List<MatchVendor>> getPersistedMatches(String userId) async {
    try {
      final response = await ApiService.instance.getCustomerMatches(userId);
      if (response['success'] == true) {
        final matchesRaw = response['matches'] as List;
        return matchesRaw.map((v) => MatchVendor.fromJson(v)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting persisted matches: $e');
      return [];
    }
  }

  @override
  Future<bool> toggleFavorite(String userId, String vendorId) async {
    try {
      final response = await ApiService.instance.toggleFavorite(
        userId: userId,
        vendorId: vendorId,
      );
      return response['isFavorite'] ?? false;
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getFavoriteIds(String userId) async {
    try {
      return await ApiService.instance.getCustomerFavorites(userId);
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }
}
