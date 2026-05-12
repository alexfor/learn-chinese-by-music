import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class AuthState {
  final String? token;
  final String? userId;
  final bool isAuthenticated;

  const AuthState({
    this.token,
    this.userId,
    this.isAuthenticated = false,
  });
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  void setAuth({required String token, required String userId}) {
    state = AuthState(
      token: token,
      userId: userId,
      isAuthenticated: true,
    );
  }

  void clearAuth() {
    state = const AuthState();
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final authServiceProvider = Provider<AuthService>((ref) {
  final api = ref.read(apiProvider);
  final authNotifier = ref.read(authStateProvider.notifier);

  // Wire up JWT injection
  api.setTokenProvider(() => ref.read(authStateProvider).token);

  // Wire up 401 → clear auth
  api.setOnUnauthorized(() => authNotifier.clearAuth());

  return AuthService(api: api, authNotifier: authNotifier);
});
