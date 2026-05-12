import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learn_chinese_by_music/features/auth/auth_controller.dart';

void main() {
  group('AuthController', () {
    test('initial state is unauthenticated', () {
      final container = ProviderContainer(overrides: []);
      final state = container.read(authStateProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.userId, isNull);
      expect(state.token, isNull);
    });

    test('setAuth updates state', () {
      final container = ProviderContainer(overrides: []);
      container.read(authStateProvider.notifier).setAuth(
            token: 'test-token',
            userId: 'user-123',
          );
      final state = container.read(authStateProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.userId, equals('user-123'));
      expect(state.token, equals('test-token'));
    });

    test('clearAuth resets state', () {
      final container = ProviderContainer(overrides: []);
      final notifier = container.read(authStateProvider.notifier);
      notifier.setAuth(token: 'test-token', userId: 'user-123');
      notifier.clearAuth();
      final state = container.read(authStateProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.userId, isNull);
      expect(state.token, isNull);
    });
  });
}
