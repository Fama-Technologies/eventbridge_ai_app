class Presence {
  final String userId;
  final bool online;
  final DateTime? lastSeen;

  const Presence({
    required this.userId,
    required this.online,
    this.lastSeen,
  });

  static const offline = Presence(userId: '', online: false);
}
