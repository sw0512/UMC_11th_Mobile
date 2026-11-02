import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class TmdbLoggingInterceptor extends Interceptor {
  String _safeMessage(DioException error) {
    var message = error.message ?? error.type.name;
    for (final header in error.requestOptions.headers.entries) {
      if (header.key.toLowerCase() == 'authorization') {
        final secret = header.value.toString();
        message = message.replaceAll(secret, 'Bearer ***');
        if (secret.startsWith('Bearer ') && secret.length > 7) {
          message = message.replaceAll(secret.substring(7), '***');
        }
      }
    }
    return message;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final headers = Map<String, dynamic>.from(options.headers);
      for (final key in headers.keys.toList()) {
        if (key.toLowerCase() == 'authorization') headers[key] = 'Bearer ***';
      }
      debugPrint('[TMDB 요청] ${options.method} ${options.uri}');
      debugPrint('[TMDB 요청 Header] $headers');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[TMDB 응답] ${response.statusCode} ${response.requestOptions.uri}',
      );
      debugPrint('[TMDB 응답 Body] ${response.data}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[TMDB 오류] ${err.requestOptions.uri} status=${err.response?.statusCode} type=${err.type.name} message=${_safeMessage(err)}',
      );
    }
    handler.next(err);
  }
}
