import 'package:dio/dio.dart';

import 'api_service.dart';
import '../features/auth/auth_controller.dart';

class AuthService {
  final ApiService _api;
  final AuthNotifier _authNotifier;

  AuthService({
    required ApiService api,
    required AuthNotifier authNotifier,
  })  : _api = api,
        _authNotifier = authNotifier;

  bool get isAuthenticated => _authNotifier.state.isAuthenticated;
  String? get token => _authNotifier.state.token;

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
