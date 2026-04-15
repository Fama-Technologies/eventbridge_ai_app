class EventRequest {
  EventRequest({
    required this.eventType,
    required this.services,
    this.guestCount,
    required this.eventDate,
    required this.location,
    this.latitude,
    this.longitude,
    this.targetRadius = 50.0,
    this.eventTime,
    required this.budget,
    required this.prompt,
  });

  final String eventType;
  final List<String> services;
  final int? guestCount;
  final DateTime eventDate;
  final String location;
  final double? latitude;
  final double? longitude;
  final double targetRadius;
  final String? eventTime;
  final double budget;
  final String prompt;

  factory EventRequest.fromJson(Map<String, dynamic> json) {
    return EventRequest(
      eventType: json['eventType'] ?? '',
      services: List<String>.from(json['services'] ?? []),
      guestCount: json['guestCount'],
      eventDate: json['eventDate'] != null ? DateTime.parse(json['eventDate']) : DateTime.now(),
      location: json['location'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      targetRadius: (json['targetRadius'] as num?)?.toDouble() ?? 50.0,
      eventTime: json['eventTime'],
      budget: (json['budget'] as num?)?.toDouble() ?? 0.0,
      prompt: json['prompt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventType': eventType,
      'services': services,
      'guestCount': guestCount,
      'eventDate': eventDate.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'targetRadius': targetRadius,
      'eventTime': eventTime,
      'budget': budget,
      'prompt': prompt,
    };
  }
}
