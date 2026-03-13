class EventRequest {
  EventRequest({
    required this.eventType,
    required this.services,
    this.guestCount,
    required this.eventDate,
    required this.location,
    this.eventTime,
    required this.budget,
    required this.prompt,
  });

  final String eventType;
  final List<String> services;
  final int? guestCount;
  final DateTime eventDate;
  final String location;
  final String? eventTime;
  final double budget;
  final String prompt;
}
