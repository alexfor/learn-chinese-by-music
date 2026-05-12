import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/constants.dart';

final apiProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  late final Dio _dio;
  String? Function()? _tokenProvider;
  void Function()? _onUnauthorized;

  ApiService([Dio? dio]) {
    _dio = dio ??
        Dio(BaseOptions(
          baseUrl: apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Accept-Language': 'en'},
        ));

    if (dio == null) {
      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokenProvider?.call();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _onUnauthorized?.call();
          }
          handler.next(error);
        },
      ));
    }
  }

  void setTokenProvider(String? Function() provider) {
    _tokenProvider = provider;
  }

  void setOnUnauthorized(void Function() callback) {
    _onUnauthorized = callback;
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}
