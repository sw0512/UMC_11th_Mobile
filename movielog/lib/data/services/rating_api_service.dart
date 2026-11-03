import 'package:dio/dio.dart';

import '../models/rating_dto.dart';

class RatingApiService {
  RatingApiService(this._dio);
  final Dio _dio;
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get<List<dynamic>>(
      '/v5/members/$memberId/ratings',
    );
    return List.unmodifiable(
      response.data!.map((v) => RatingDto.fromJson(v as Map<String, dynamic>)),
    );
  }
}

String writeMyRatingsErrorMessage(DioException error) {
  switch (error.response?.statusCode) {
    case 400:
      return 'memberId 형식을 다시 확인해 주세요.';
    case 404:
      return '존재하지 않는 회원입니다.';
    default:
      return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
  }
}
