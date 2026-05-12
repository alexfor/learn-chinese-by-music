import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'package:learn_chinese_by_music/services/connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityService', () {
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        null,
      );
    });

    test('returns connected for wifi', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'check') return ['wifi'];
          return null;
        },
      );

      final service = ConnectivityService();
      final status = await service.checkConnectivity();
      expect(status, isTrue);
    });

    test('returns connected for mobile', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'check') return ['mobile'];
          return null;
        },
      );

      final service = ConnectivityService();
      final status = await service.checkConnectivity();
      expect(status, isTrue);
    });

    test('returns disconnected for none', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'check') return ['none'];
          return null;
        },
      );

      final service = ConnectivityService();
      final status = await service.checkConnectivity();
      expect(status, isFalse);
    });
  });
}
