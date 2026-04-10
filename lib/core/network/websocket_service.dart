import 'package:flutter/foundation.dart';

/// Lightweight compatibility shim for legacy websocket listeners.
///
/// The app now relies on API polling/Firestore for most chat updates,
/// but older vendor screens still subscribe to this interface.
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  static String? activeChatId;

  final List<void Function(Map<String, dynamic>)> _listeners = [];

  void connect() {
    // Intentionally no-op: retained for backwards compatibility.
    debugPrint('[WebSocketService] connect() called (compat mode)');
  }

  void addListener(void Function(Map<String, dynamic>) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void removeListener(void Function(Map<String, dynamic>) listener) {
    _listeners.remove(listener);
  }

  void emit(Map<String, dynamic> event) {
    for (final listener in List<void Function(Map<String, dynamic>)>.from(
      _listeners,
    )) {
      listener(event);
    }
  }
}
