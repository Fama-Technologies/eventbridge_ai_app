enum ChatStatus {
  pending,
  accepted,
  declined;

  static ChatStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'accepted':
        return ChatStatus.accepted;
      case 'declined':
        return ChatStatus.declined;
      default:
        return ChatStatus.pending;
    }
  }

  String toFirestore() => name; // 'pending', 'accepted', 'declined'

  bool get isAccepted => this == ChatStatus.accepted;
}
