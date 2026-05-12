import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_service.dart';
import '../features/progress/progress_controller.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    connectivity: ref.read(connectivityServiceProvider),
    onOnline: () => ref.read(progressControllerProvider.notifier).syncPendingProgress(),
  );
  service.start();
  ref.onDispose(() => service.dispose());
  return service;
});

class SyncService {
  final ConnectivityChecker _connectivity;
  final Future<void> Function() _onOnline;
  StreamSubscription<bool>? _subscription;
  bool _started = false;

  SyncService({
    required ConnectivityChecker connectivity,
    required Future<void> Function() onOnline,
  })  : _connectivity = connectivity,
        _onOnline = onOnline;

  void start() {
    if (_started) return;
    _started = true;
    _subscription = _connectivity.connectivityStream.listen((connected) {
      if (connected) {
        _onOnline();
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
    _started = false;
  }
}
