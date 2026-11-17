import 'package:dio/dio.dart';

String? apiErrorCode(DioException e) =>
    e.response?.data is Map ? e.response?.data['code'] as String? : null;
String? apiErrorMessage(DioException e) =>
    e.response?.data is Map ? e.response?.data['message'] as String? : null;
bool isExpiredCode(String? code) =>
    const {'AUTH401_2', 'AUTH401_3', 'AUTH401_4'}.contains(code);
