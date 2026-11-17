import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

Dio createMovieLogClient() => Dio(
  BaseOptions(
    baseUrl: 'https://workbook.devnoco.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ),
);
Dio createAuthMovieLogClient(
  TokenStorage storage, {
  required int Function() sessionVersion,
  required Future<void> Function(int) onExpired,
}) {
  final dio = createMovieLogClient();
  dio.interceptors.add(
    AuthInterceptor(
      storage,
      sessionVersion: sessionVersion,
      onExpired: onExpired,
    ),
  );
  return dio;
}
