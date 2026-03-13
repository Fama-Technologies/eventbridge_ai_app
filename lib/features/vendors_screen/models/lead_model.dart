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

  Lead({
    required this.id,
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
  });
}
