import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_service.dart';
import '../features/auth/auth_controller.dart';

class AuthService {
  final ApiService _api;
  final AuthNotifier _authNotifier;
  final Ref _ref;

  AuthService({
    required ApiService api,
    required AuthNotifier authNotifier,
    required Ref ref,
  })  : _api = api,
        _authNotifier = authNotifier,
        _ref = ref;

  bool get isAuthenticated => _ref.read(authStateProvider).isAuthenticated;
  String? get token => _ref.read(authStateProvider).token;

  /// Authenticate with a provider identity token.
  /// Calls backend POST /api/auth/login.
  Future<void> loginWithToken({
    required String provider,
    required String identityToken,
  }) async {
    final resp = await _api.post('/api/auth/login', data: {
      'provider': provider,
      'identity_token': identityToken,
    });

    final data = resp.data as Map<String, dynamic>;
    _authNotifier.setAuth(
      token: data['token'] as String,
      userId: data['user_id'] as String,
    );
  }

  void signOut() {
    _authNotifier.clearAuth();
  }
}
