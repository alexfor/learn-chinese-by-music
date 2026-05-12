import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abstract interface to allow test fakes.
abstract class ConnectivityChecker {
  Future<bool> checkConnectivity();
  Stream<bool> get connectivityStream;
}

final connectivityServiceProvider = Provider<ConnectivityChecker>((ref) {
  return ConnectivityService();
});

class ConnectivityService implements ConnectivityChecker {
  final Connectivity _connectivity;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  @override
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map(
      (results) => results.any((r) => r != ConnectivityResult.none),
    );
  }
}
