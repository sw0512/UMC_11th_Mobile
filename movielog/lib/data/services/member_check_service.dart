import 'package:dio/dio.dart';

import '../models/check_result.dart';

class MemberCheckService {
  MemberCheckService(this._dio);
  final Dio _dio;
  Future<bool> _check(String field, String value) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v5/members/$field/${Uri.encodeComponent(value.trim())}',
    );
    return CheckResult.fromJson(response.data!).available;
  }

  Future<bool> checkNickname(String nickname) => _check('nickname', nickname);
  Future<bool> checkEmail(String email) => _check('email', email);
}
