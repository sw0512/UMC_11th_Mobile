import 'package:dio/dio.dart';

import 'common_response.dart';

class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.code, this.status});
  final String message;
  final String? code;
  final int? status;
  factory ApiFailure.from(Object error) {
    if (error is ApiFailure) return error;
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> &&
          data['isSuccess'] is bool &&
          data['code'] is String &&
          data['message'] is String) {
        final common = CommonResponse<Object?>.fromJson(data, (v) => v);
        return ApiFailure(
          common.message,
          code: common.code,
          status: error.response?.statusCode,
        );
      }
      return ApiFailure(
        '요청에 실패했습니다. 네트워크를 확인하고 다시 시도해 주세요.',
        status: error.response?.statusCode,
      );
    }
    return const ApiFailure('서버 응답을 확인하지 못했습니다. 다시 시도해 주세요.');
  }
  bool get shouldRefresh => code == 'COMMON403' || code == 'COMMON404';
  @override
  String toString() => message;
}
