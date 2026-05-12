import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'package:learn_chinese_by_music/services/sync_service.dart';
import 'package:learn_chinese_by_music/services/connectivity_service.dart';

class FakeConnectivityChecker implements ConnectivityChecker {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _connected = true;

  void setConnected(bool value) {
    _connected = value;
    _controller.add(value);
  }

  @override
  Future<bool> checkConnectivity() async => _connected;

  @override
  Stream<bool> get connectivityStream => _controller.stream;
}

void main() {
  group('SyncService', () {
    test('calls onOnline when connectivity stream emits true', () async {
      final connectivity = FakeConnectivityChecker();
      int callCount = 0;

      final service = SyncService(
        connectivity: connectivity,
        onOnline: () async {
          callCount++;
        },
      );

      service.start();
      connectivity.setConnected(true);
      await Future.delayed(Duration.zero);

      expect(callCount, equals(1));
      service.dispose();
    });

    test('does not call onOnline when connectivity is false', () async {
      final connectivity = FakeConnectivityChecker();
      int callCount = 0;

      final service = SyncService(
        connectivity: connectivity,
        onOnline: () async {
          callCount++;
        },
      );

      service.start();
      connectivity.setConnected(false);
      await Future.delayed(Duration.zero);

      expect(callCount, equals(0));
      service.dispose();
    });

    test('start is idempotent', () async {
      final connectivity = FakeConnectivityChecker();
      int callCount = 0;

      final service = SyncService(
        connectivity: connectivity,
        onOnline: () async {
          callCount++;
        },
      );

      service.start();
      service.start(); // second call should be no-op
      connectivity.setConnected(true);
      await Future.delayed(Duration.zero);

      expect(callCount, equals(1));
      service.dispose();
    });

    test('dispose stops listening', () async {
      final connectivity = FakeConnectivityChecker();
      int callCount = 0;

      final service = SyncService(
        connectivity: connectivity,
        onOnline: () async {
          callCount++;
        },
      );

      service.start();
      service.dispose();
      connectivity.setConnected(true);
      await Future.delayed(Duration.zero);

      expect(callCount, equals(0));
    });
  });
}
