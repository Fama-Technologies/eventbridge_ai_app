class EventRequest {
  EventRequest({
    required this.eventType,
    required this.services,
    this.guestCount,
    required this.eventDate,
    required this.location,
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
  final double targetRadius;
  final String? eventTime;
  final double budget;
  final String prompt;
}
