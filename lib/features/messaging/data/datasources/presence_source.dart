import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceSource {
  final FirebaseFirestore _firestore;
  Timer? _timer;

  PresenceSource(this._firestore);

  void connect(String userId) {
    _updatePresence(userId, true);
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updatePresence(userId, true);
    });
  }

  void disconnect(String userId) {
    _timer?.cancel();
    _updatePresence(userId, false);
  }

  Future<void> _updatePresence(String userId, bool online) {
    return _firestore.collection('presence').doc(userId).set({
      'online': online,
      'lastSeen': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
