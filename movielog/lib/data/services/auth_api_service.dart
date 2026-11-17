import 'package:dio/dio.dart';

import '../models/login_models.dart';
import '../models/api_failure.dart';
import '../models/common_response.dart';

class AuthApiService {
  AuthApiService(this._dio);
  final Dio _dio;
  Future<LoginResult> login(LoginRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v7/auth/login',
        data: request.toJson(),
      );
      final common = CommonResponse<LoginResult>.fromJson(
        response.data!,
        (v) => LoginResult.fromJson(v as Map<String, dynamic>),
      );
      if (response.statusCode != 200 ||
          !common.isSuccess ||
          common.result == null) {
        throw ApiFailure(
          common.message,
          code: common.code,
          status: response.statusCode,
        );
      }
      return common.result!;
    } catch (e) {
      throw ApiFailure.from(e);
    }
  }
}
