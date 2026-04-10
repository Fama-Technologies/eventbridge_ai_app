import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/features/vendors_screen/models/lead_model.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';

final sharedLeadStateProvider = NotifierProvider<SharedLeadState, List<Lead>>(() {
  return SharedLeadState();
});

class SharedLeadState extends Notifier<List<Lead>> {
  @override
  List<Lead> build() {
    // Start with empty list, will be populated via fetchLeads
    return [];
  }

  Future<void> fetchLeads(String userId) async {
    try {
      final results = await Future.wait([
        ApiService.instance.getVendorLeads(userId),
        ApiService.instance.getVendorBookings(userId),
      ]);

      final leadsResult = results[0];
      final bookingsResult = results[1];

      List<Lead> leads = [];
      if (leadsResult['success'] == true) {
        final List<dynamic> leadsData = leadsResult['leads'] ?? [];
        // Debug: log the raw keys from the first lead to identify field naming
        if (leadsData.isNotEmpty) {
          final sample = leadsData.first as Map<String, dynamic>;
          debugPrint('[LeadState] Raw API lead keys: ${sample.keys.toList()}');
          debugPrint('[LeadState] Raw API lead (first 5 fields): ${Map.fromEntries(sample.entries.take(5))}');
          // Specifically look for any field that might carry customer ID
          final custRelatedKeys = sample.keys
              .where((k) => k.toLowerCase().contains('cust') ||
                            k.toLowerCase().contains('client') ||
                            k.toLowerCase().contains('user') ||
                            k.toLowerCase().contains('buyer'))
              .toList();
          debugPrint('[LeadState] Customer-related keys in API response: $custRelatedKeys');
          for (final key in custRelatedKeys) {
            debugPrint('[LeadState]   $key => ${sample[key]}');
          }
        }
        leads = leadsData.map((json) => Lead.fromJson(json)).toList();
      }

      if (bookingsResult['success'] == true) {
        final List<dynamic> bookingsData = bookingsResult['bookings'] ?? [];
        for (var b in bookingsData) {
          final bookingId = b['id'].toString();
          if (!leads.any((l) => l.id == bookingId)) {
            leads.add(Lead.fromJson({
              ...b,
              'status': 'CONFIRMED',
              'isAccepted': true,
            }));
          }
        }
      }

      state = leads;
    } catch (e) {
      debugPrint('[LeadState] Error fetching leads: $e');
      rethrow;
    }
  }

  void addLead(Lead newLead) {
    state = [...state, newLead];
  }

  Future<bool> updateLeadStatus(String leadId, String newStatus) async {
    try {
      debugPrint('[LeadState] Calling updateLeadStatus for leadId: $leadId, status: $newStatus');
      final response = await ApiService.instance.updateLeadStatus(
        leadId: leadId,
        status: newStatus,
      );
      debugPrint('[LeadState] updateLeadStatus response: $response');

      if (response['success'] == true) {
        state = state.map((lead) {
          if (lead.id == leadId) {
            final lowerStatus = newStatus.toLowerCase();
            final accepted = lowerStatus == 'accepted' ||
                lowerStatus == 'confirmed' ||
                lowerStatus == 'booked';
            return lead.copyWith(isAccepted: accepted, status: lowerStatus);
          }
          return lead;
        }).toList();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[LeadState] Error in updateLeadStatus: $e');
      return false;
    }
  }

  Lead? getById(String id) {
    try {
      return state.firstWhere((lead) => lead.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Attempt to fetch the full lead from the API to recover a missing
  /// [customerId]. Patches the lead in state and returns the resolved ID,
  /// or null if it still cannot be determined.
  Future<String?> enrichLeadCustomerId(String leadId) async {
    try {
      // 1. Already in state with a valid customerId?
      final existing = getById(leadId);
      if (existing?.customerId?.isNotEmpty == true) {
        return existing!.customerId;
      }

      // 2. Call the single-lead endpoint
      final raw = await ApiService.instance.getVendorLeadById(leadId);
      if (raw == null) {
        debugPrint('[LeadState] getVendorLeadById returned null for $leadId');
        return null;
      }

      // Log all keys so we can spot the right field name
      debugPrint('[LeadState] Single-lead response keys: ${raw.keys.toList()}');

      final enriched = Lead.fromJson(raw);
      final custId = enriched.customerId;

      if (custId != null && custId.isNotEmpty) {
        // Patch in state
        state = state.map((l) {
          if (l.id == leadId) return l.copyWith(customerId: custId);
          return l;
        }).toList();
        debugPrint('[LeadState] Patched customerId=$custId for lead $leadId');
        return custId;
      }

      debugPrint('[LeadState] enrichLeadCustomerId: still no customerId after API call');
      return null;
    } catch (e) {
      debugPrint('[LeadState] enrichLeadCustomerId error: $e');
      return null;
    }
  }

  Future<bool> confirmBooking({
    required String leadId,
    required DateTime bookingDate,
    String? clientName,
    String? eventType,
    double? price,
    String? notes,
  }) async {
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return false;

      debugPrint('[LeadState] Creating booking for lead $leadId');
      final result = await ApiService.instance.createVendorBooking(
        userId: userId,
        bookingDate: bookingDate.toIso8601String(),
        clientName: clientName,
        eventType: eventType,
        totalPrice: price,
        notes: notes,
      );

      if (result['success'] == true) {
        debugPrint('[LeadState] Booking created, updating status to booked');
        return await updateLeadStatus(leadId, 'booked');
      }
      return false;
    } catch (e) {
      debugPrint('[LeadState] Error confirming booking: $e');
      return false;
    }
  }
}
