import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connectivity service for checking network status
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Stream of connectivity results
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  /// Check current connectivity status
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return await _connectivity.checkConnectivity();
  }

  /// Check if device is online (has any connection)
  Future<bool> isOnline() async {
    final results = await checkConnectivity();
    return results.any((result) =>
        result != ConnectivityResult.none);
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
  }
}

/// Connectivity service provider
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Online status provider (true if online, false if offline)
final onlineStatusProvider = StreamProvider<bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  
  return connectivityService.onConnectivityChanged.map((results) {
    return results.any((result) => result != ConnectivityResult.none);
  });
});

/// Current connectivity results provider
final connectivityResultsProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.onConnectivityChanged;
});

