import 'package:dio/dio.dart';

import '../models/check_result.dart';
import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/sign_up_models.dart';
import '../models/api_failure.dart';

class SignUpService {
  SignUpService(this._dio);
  final Dio _dio;
  Future<bool> _check(String field, String value) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v6/members/$field/${Uri.encodeComponent(value.trim())}',
      );
      return CheckResult.fromJson(response.data!).available;
    } catch (e) {
      throw ApiFailure.from(e);
    }
  }

  Future<bool> checkNickname(String value) => _check('nickname', value);
  Future<bool> checkEmail(String value) => _check('email', value);
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v6/members',
        data: request.toJson(),
      );
      final result = CommonResponse<SignUpResult>.fromJson(
        response.data!,
        (v) => SignUpResult.fromJson(v as Map<String, dynamic>),
      );
      if (response.statusCode != 201 ||
          !result.isSuccess ||
          result.result == null ||
          result.result!.memberId < 1) {
        throw const ApiFailure('가입 결과를 확인하지 못했습니다. 새 요청 전에 서버 상태를 확인해 주세요.');
      }
      return result;
    } catch (e) {
      throw ApiFailure.from(e);
    }
  }
}
