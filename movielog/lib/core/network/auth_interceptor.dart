import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_error.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this.storage, {
    required this.sessionVersion,
    required this.onExpired,
  });
  final TokenStorage storage;
  final int Function() sessionVersion;
  final Future<void> Function(int) onExpired;
  bool isProtected(RequestOptions options) =>
      options.uri.scheme == 'https' &&
      options.uri.host == 'workbook.devnoco.com' &&
      options.uri.port == 443 &&
      (options.uri.path == '/v7/members/me' ||
          options.uri.path == '/v7/ratings' ||
          RegExp(r'^/v7/ratings/[0-9]+$').hasMatch(options.uri.path));
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers.remove('Authorization');
    if (!isProtected(options)) {
      handler.next(options);
      return;
    }
    options.followRedirects = false;
    final version =
        options.extra['expectedSessionVersion'] as int? ?? sessionVersion();
    if (version != sessionVersion()) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          error: '세션이 변경됐습니다.',
        ),
      );
      return;
    }
    options.extra['sessionVersion'] = version;
    String? token;
    try {
      token = await storage.readAccessToken();
    } catch (_) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: StateError('보안 저장소를 읽지 못했습니다.'),
        ),
      );
      return;
    }
    if (version != sessionVersion()) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          error: '세션이 변경됐습니다.',
        ),
      );
      return;
    }
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final version = err.requestOptions.extra['sessionVersion'];
    if (isProtected(err.requestOptions) &&
        err.response?.statusCode == 401 &&
        isExpiredCode(apiErrorCode(err)) &&
        version is int &&
        version == sessionVersion()) {
      await onExpired(version);
    }
    handler.next(err);
  }
}
