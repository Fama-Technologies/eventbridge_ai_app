import 'dart:convert';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  WebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  final List<Function(Map<String, dynamic>)> _listeners = [];

  // This should be updated after deployment with the actual wss endpoint
  // For now, we derive it from the API base URL if possible, 
  // but usually WebSocket APIs have their own ID.
  // We'll use a placeholder that matches the user's API pattern.
  final String _wsBaseUrl = 'wss://3nqhgc5y2l.execute-api.us-east-1.amazonaws.com/dev';

  void connect() {
    if (_isConnected) return;

    final userId = StorageService().getString('user_id');
    if (userId == null) return;

    final url = '$_wsBaseUrl?userId=$userId';
    debugPrint('Connecting to WebSocket: $url');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;
      _reconnectAttempts = 0; // Reset on successful attempt

      _channel!.stream.listen(
        (message) {
          debugPrint('WebSocket Message Received: $message');
          _handleMessage(message);
        },
        onDone: () {
          debugPrint('WebSocket Connection Closed');
          _isConnected = false;
          _reconnect();
        },
        onError: (error) {
          debugPrint('WebSocket Error: $error');
          _isConnected = false;
          _reconnect();
        },
      );
    } catch (e) {
      debugPrint('WebSocket Connection Failed: $e');
      _isConnected = false;
      _reconnect();
    }
  }

  int _reconnectAttempts = 0;
  void _reconnect() {
    if (_isConnected) return;
    
    _reconnectAttempts++;
    // Exponential backoff: 2s, 4s, 8s, 16s... max 30s
    final delay = (2 * _reconnectAttempts).clamp(2, 30);
    
    debugPrint('WebSocket Reconnecting in $delay seconds (Attempt $_reconnectAttempts)');
    Future.delayed(Duration(seconds: delay), () {
      if (!_isConnected) connect();
    });
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      for (var listener in _listeners) {
        listener(data);
      }
    } catch (e) {
      debugPrint('Error handling WS message: $e');
    }
  }

  void addListener(Function(Map<String, dynamic>) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(Map<String, dynamic>) listener) {
    _listeners.remove(listener);
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }
}
