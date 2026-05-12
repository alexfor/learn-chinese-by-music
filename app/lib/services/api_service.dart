import 'package:dio/dio.dart';
import '../shared/constants.dart';

class ApiService {
  late final Dio _dio;

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
          // TODO: attach JWT token when auth is implemented
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ));
    }
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
