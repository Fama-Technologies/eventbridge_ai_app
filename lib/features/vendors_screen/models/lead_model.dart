import 'package:flutter/foundation.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderImage;
  final String text;
  final DateTime timestamp;
  final bool isVendor;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderImage,
    required this.text,
    required this.timestamp,
    required this.isVendor,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName'] ?? 'Unknown',
      senderImage: json['senderImage'] ?? '',
      text: json['text'] ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      isVendor: json['isVendor'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderImage': senderImage,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isVendor': isVendor,
    };
  }
}

class Lead {
  final String id;
  final String title;
  final String date;
  final String time;
  final String location;
  final int matchScore;
  final double budget;
  final int guests;
  final String responseTime;
  final String clientName;
  final String clientMessage;
  final String venueName;
  final String venueAddress;
  final String clientImageUrl;
  final bool isHighValue;
  final String lastActive;
  final bool isAccepted;
  final String? phoneNumber;
  final String? vendorResponse;
  final List<ChatMessage> messages;
  final DateTime? acceptedAt;
  final String? customerId;
  final String status;

  Lead({
    required this.id,
    this.customerId,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.matchScore,
    required this.budget,
    required this.guests,
    required this.responseTime,
    required this.clientName,
    required this.clientMessage,
    required this.venueName,
    required this.venueAddress,
    required this.clientImageUrl,
    this.isHighValue = false,
    required this.lastActive,
    this.isAccepted = false,
    this.phoneNumber,
    this.vendorResponse,
    this.messages = const [],
    this.acceptedAt,
    this.status = 'pending',
  });

  Lead copyWith({
    String? id,
    String? customerId,
    String? title,
    String? date,
    String? time,
    String? location,
    int? matchScore,
    double? budget,
    int? guests,
    String? responseTime,
    String? clientName,
    String? clientMessage,
    String? venueName,
    String? venueAddress,
    String? clientImageUrl,
    bool? isHighValue,
    String? lastActive,
    bool? isAccepted,
    String? phoneNumber,
    String? vendorResponse,
    List<ChatMessage>? messages,
    DateTime? acceptedAt,
    String? status,
  }) {
    return Lead(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      matchScore: matchScore ?? this.matchScore,
      budget: budget ?? this.budget,
      guests: guests ?? this.guests,
      responseTime: responseTime ?? this.responseTime,
      clientName: clientName ?? this.clientName,
      clientMessage: clientMessage ?? this.clientMessage,
      venueName: venueName ?? this.venueName,
      venueAddress: venueAddress ?? this.venueAddress,
      clientImageUrl: clientImageUrl ?? this.clientImageUrl,
      isHighValue: isHighValue ?? this.isHighValue,
      lastActive: lastActive ?? this.lastActive,
      isAccepted: isAccepted ?? this.isAccepted,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      vendorResponse: vendorResponse ?? this.vendorResponse,
      messages: messages ?? this.messages,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      status: status ?? this.status,
    );
  }

  factory Lead.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    final client   = json['client'];
    final user     = json['user'];
    final inquiry  = json['inquiry'];
    final request  = json['request'];   // AWS backends often use "request"
    final requester = json['requester'];

    String? nestedId(dynamic value) {
      if (value is! Map) return null;
      return value['id']?.toString() ??
          value['userId']?.toString() ??
          value['user_id']?.toString() ??
          value['customerId']?.toString() ??
          value['customer_id']?.toString() ??
          value['clientId']?.toString() ??
          value['client_id']?.toString() ??
          value['requesterId']?.toString() ??
          value['requester_id']?.toString();
    }

    final firstName = json['first_name'] ?? json['firstName'] ?? '';
    final lastName  = json['last_name']  ?? json['lastName']  ?? '';
    final fullName  = (firstName.isEmpty && lastName.isEmpty)
        ? (json['clientName'] ?? 'Client')
        : '$firstName $lastName'.trim();

    final messagesJson = json['messages'] as List<dynamic>? ?? [];
    final messagesList = messagesJson
        .map((msg) => ChatMessage.fromJson(msg as Map<String, dynamic>))
        .toList();

    final leadId = json['id']?.toString() ?? '';
    final custId =
        json['customerId']?.toString() ??
        json['customer_id']?.toString() ??
        json['userId']?.toString() ??
        json['client_id']?.toString() ??
        json['clientId']?.toString() ??
        json['customer_user_id']?.toString() ??
        json['inquiryCustomerId']?.toString() ??
        json['requestCustomerId']?.toString() ??
        json['requestUserId']?.toString() ??
        json['request_user_id']?.toString() ??
        json['requesterId']?.toString() ??
        json['requester_id']?.toString() ??
        json['createdBy']?.toString() ??
        json['created_by']?.toString() ??
        nestedId(customer) ??
        nestedId(client) ??
        nestedId(user) ??
        nestedId(inquiry) ??
        nestedId(request) ??
        nestedId(requester);

    if (custId == null || custId.isEmpty) {
      // ── DIAGNOSTIC DUMP ────────────────────────────────────────────────────
      // Log the full raw lead JSON so we can find the correct customerId field.
      // Remove once the field name is identified and added above.
      debugPrint('⚠️ [Lead.fromJson] No customerId found for lead $leadId');
      debugPrint('⚠️ [Lead.fromJson] ALL KEYS: ${json.keys.toList()}');
      // Print every top-level key/value pair
      for (final entry in json.entries) {
        debugPrint('⚠️ [Lead.fromJson]   ${entry.key}: ${entry.value}');
      }
    } else {
      debugPrint('[Lead.fromJson] Lead $leadId → customerId=$custId ✓');
    }

    return Lead(
      id: leadId,
      customerId: custId,
      title: json['title'] ?? json['eventType'] ?? 'Lead',
      date:
          json['date'] ??
          json['event_date'] ??
          json['eventDate']?.toString().split(' ')[0] ??
          'TBD',
      time: json['time'] ?? json['event_time'] ?? 'TBD',
      location: json['location'] ?? 'TBD',
      matchScore:
          int.tryParse(
            json['matchScore']?.toString() ??
                json['match_score']?.toString() ??
                '0',
          ) ??
          0,
      budget: (json['budget'] is num)
          ? (json['budget'] as num).toDouble()
          : double.tryParse(json['budget']?.toString() ?? '0.0') ?? 0.0,
      guests: int.tryParse(json['guests']?.toString() ?? '0') ?? 0,
      responseTime: json['responseTime'] ?? '2h',
      clientName: fullName,
      clientMessage:
          json['clientMessage'] ??
          json['client_message'] ??
          json['notes'] ??
          '',
      venueName: json['venueName'] ?? '',
      venueAddress: json['venueAddress'] ?? '',
      clientImageUrl:
          json['client_image'] ??
          json['clientImageUrl'] ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(fullName)}&background=random',
      isHighValue: json['isHighValue'] ?? json['is_high_value'] ?? false,
      lastActive: json['lastActive'] ?? 'Active now',
      isAccepted:
          json['isAccepted'] ??
          (json['status'] == 'ACCEPTED' ||
              json['status'] == 'accepted' ||
              json['status'] == 'CONFIRMED'),
      phoneNumber:
          json['phone']?.toString() ??
          json['phoneNumber']?.toString() ??
          json['clientPhone']?.toString(),
      vendorResponse:
          json['vendorResponse']?.toString() ??
          json['vendor_response']?.toString(),
      messages: messagesList,
      acceptedAt: DateTime.tryParse(
        json['acceptedAt']?.toString() ?? json['accepted_at']?.toString() ?? '',
      ),
      status: json['status']?.toString() ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'title': title,
      'date': date,
      'time': time,
      'location': location,
      'matchScore': matchScore,
      'budget': budget,
      'guests': guests,
      'responseTime': responseTime,
      'clientName': clientName,
      'clientMessage': clientMessage,
      'venueName': venueName,
      'venueAddress': venueAddress,
      'clientImageUrl': clientImageUrl,
      'isHighValue': isHighValue,
      'lastActive': lastActive,
      'isAccepted': isAccepted,
      'phoneNumber': phoneNumber,
      'vendorResponse': vendorResponse,
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'status': status,
    };
  }
  static Lead empty() {
    return Lead(
      id: '',
      title: '',
      date: '',
      time: '',
      location: '',
      matchScore: 0,
      budget: 0,
      guests: 0,
      responseTime: '',
      clientName: '',
      clientMessage: '',
      venueName: '',
      venueAddress: '',
      clientImageUrl: '',
      lastActive: '',
      customerId: '',
    );
  }
}
