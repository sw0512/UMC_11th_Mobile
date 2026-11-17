import 'package:dio/dio.dart';

import '../models/member_info.dart';
import '../models/common_response.dart';
import '../models/api_failure.dart';

class MemberApiService {
  MemberApiService(this._dio, {this.sessionVersion});
  final int Function()? sessionVersion;
  Options get _authOptions => Options(
    extra: {
      if (sessionVersion != null)
        'expectedSessionVersion': sessionVersion?.call(),
    },
  );
  final Dio _dio;
  MemberInfo _parse(Response<Map<String, dynamic>> response) {
    final common = CommonResponse<MemberInfo>.fromJson(
      response.data!,
      (v) => MemberInfo.fromJson(v as Map<String, dynamic>),
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
  }

  Future<MemberInfo> fetchMe() async {
    try {
      return _parse(
        await _dio.get<Map<String, dynamic>>(
          '/v7/members/me',
          options: _authOptions,
        ),
      );
    } catch (e) {
      throw ApiFailure.from(e);
    }
  }

  Future<MemberInfo> updateNickname(String nickname) async {
    try {
      return _parse(
        await _dio.patch<Map<String, dynamic>>(
          '/v7/members/me',
          data: {'nickname': nickname.trim()},
          options: _authOptions,
        ),
      );
    } catch (e) {
      throw ApiFailure.from(e);
    }
  }
}
