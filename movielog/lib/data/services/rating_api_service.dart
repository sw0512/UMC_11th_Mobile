import 'package:dio/dio.dart';

import '../models/rating_dto.dart';
import '../models/rating_request.dart';
import '../models/common_response.dart';
import '../models/api_failure.dart';

class RatingApiService {
  RatingApiService(this._dio);
  final Dio _dio;
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/v6/members/$memberId/ratings',
      );
      return List.unmodifiable(
        response.data!.map(
          (v) => RatingDto.fromJson(v as Map<String, dynamic>),
        ),
      );
    } catch (e) {
      throw ApiFailure.from(e);
    }
  }

  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v6/members/$memberId/ratings',
        data: request.toJson(),
      );
      _checkWrite(response, 201);
    } catch (e) {
      throw ApiFailure.from(e);
    }
  }

  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    validateServerScore(score.toDouble());
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/v6/members/$memberId/ratings/$ratingId',
        data: {'score': score, 'comment': normalizedComment(comment)},
      );
      _checkWrite(response, 200);
    } catch (e) {
      throw ApiFailure.from(e);
    }
  }

  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    try {
      final response = await _dio.delete<void>(
        '/v6/members/$memberId/ratings/$ratingId',
      );
      if (response.statusCode != 204) {
        throw const ApiFailure('삭제 결과를 확인하지 못했습니다. 목록을 다시 조회해 주세요.');
      }
    } catch (e) {
      throw ApiFailure.from(e);
    }
  }

  void _checkWrite(Response<Map<String, dynamic>> response, int expected) {
    final common = CommonResponse<Object?>.fromJson(response.data!, (v) => v);
    if (response.statusCode != expected || !common.isSuccess) {
      throw ApiFailure(
        common.message,
        code: common.code,
        status: response.statusCode,
      );
    }
  }
}

String writeMyRatingsErrorMessage(Object error) =>
    ApiFailure.from(error).message;
