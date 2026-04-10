import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

// A global stream that services can use to "fast-fail" the connectivity status
// when they hit a real connection error (e.g. Dio connection refused).
final globalConnectivityErrorController = StreamController<void>.broadcast();

final networkStatusProvider = AsyncNotifierProvider<NetworkStatusNotifier, NetworkStatus>(() {
  return NetworkStatusNotifier();
});

class NetworkStatusNotifier extends AsyncNotifier<NetworkStatus> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  late StreamSubscription<void> _errorSubscription;
  Timer? _heartbeatTimer;

  @override
  FutureOr<NetworkStatus> build() async {
    // 1. Listen to hardware connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      _checkStatus(results);
    });

    // 2. Listen to "Fast Failure" signals from ApiService
    _errorSubscription = globalConnectivityErrorController.stream.listen((_) {
      _handleFastFailure();
    });

    // 3. Start a heartbeat timer to catch "connected but no data" cases
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _performPeriodicCheck();
    });

    ref.onDispose(() {
      _connectivitySubscription.cancel();
      _errorSubscription.cancel();
      _heartbeatTimer?.cancel();
    });

    // Initial check
    final initialResults = await Connectivity().checkConnectivity();
    return _verifyActualInternet(initialResults);
  }

  void _handleFastFailure() {
    // If we get an explicit error signal, we are offline immediately
    if (state.value != NetworkStatus.offline) {
      state = const AsyncValue.data(NetworkStatus.offline);
    }
  }

  Future<void> _checkStatus(List<ConnectivityResult> results) async {
    final status = await _verifyActualInternet(results);
    state = AsyncValue.data(status);
  }

  Future<void> _performPeriodicCheck() async {
    final results = await Connectivity().checkConnectivity();
    final status = await _verifyActualInternet(results);
    
    if (state.hasValue && state.value != status) {
      state = AsyncValue.data(status);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final results = await Connectivity().checkConnectivity();
    final status = await _verifyActualInternet(results);
    state = AsyncValue.data(status);
  }

  Future<NetworkStatus> _verifyActualInternet(List<ConnectivityResult> results) async {
    // 1. Hardware Check (Airplane mode / WiFi off)
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return NetworkStatus.offline;
    }

    // 2. Precision Active Check (Backend Reachability)
    // We specifically check the EventBridge backend. If we can't reach it, 
    // it doesn't matter if Google is reachable.
    try {
      const backendDomain = '3nqhgc5y2l.execute-api.us-east-1.amazonaws.com';
      
      // We try a Socket connection to the HTTPS port (443) of the backend.
      // This is the most accurate check for "can the app function?".
      final socket = await Socket.connect(
        backendDomain,
        443,
        timeout: const Duration(seconds: 4),
      );
      await socket.close();
      return NetworkStatus.online;
    } catch (e) {
      debugPrint('🚨 Precision reachability check failed (Backend unreachable): $e');
    }

    return NetworkStatus.offline;
  }
}
