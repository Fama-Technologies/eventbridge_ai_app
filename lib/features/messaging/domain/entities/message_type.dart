enum MessageType {
  text,
  image,
  system;

  static MessageType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  String toFirestore() => name;
}
