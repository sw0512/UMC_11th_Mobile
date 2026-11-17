import 'package:dio/dio.dart';

import '../models/rating_dto.dart';
import '../models/rating_request.dart';
import '../models/common_response.dart';
import '../models/api_failure.dart';

class RatingApiService {
  RatingApiService(this._publicDio, this._authDio, {this.sessionVersion});
  final int Function()? sessionVersion;
  Options get _authOptions => Options(
    extra: {
      if (sessionVersion != null)
        'expectedSessionVersion': sessionVersion?.call(),
    },
  );
  final Dio _publicDio;
  final Dio _authDio;
  // Public user list requires an explicitly known ID. It is not a JWT "my ratings" API.
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    try {
      final response = await _publicDio.get<List<dynamic>>(
        '/v7/members/$memberId/ratings',
      );
      return response.data!
          .map((v) => RatingDto.fromJson(v as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiFailure.from(e);
    }
  }

  RatingDto _rating(Response<Map<String, dynamic>> response, int expected) {
    final c = CommonResponse<RatingDto>.fromJson(
      response.data!,
      (v) => RatingDto.fromJson(v as Map<String, dynamic>),
    );
    if (response.statusCode != expected || !c.isSuccess || c.result == null) {
      throw ApiFailure(c.message, code: c.code, status: response.statusCode);
    }
    return c.result!;
  }

  Future<RatingDto> createRating(CreateRatingRequest request) async {
    try {
      return _rating(
        await _authDio.post<Map<String, dynamic>>(
          '/v7/ratings',
          data: request.toJson(),
          options: _authOptions,
        ),
        201,
      );
    } catch (e) {
      throw ApiFailure.from(e);
    }
  }

  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    validateServerScore(score.toDouble());
    try {
      return _rating(
        await _authDio.patch<Map<String, dynamic>>(
          '/v7/ratings/$ratingId',
          data: {'score': score, 'comment': normalizedComment(comment)},
          options: _authOptions,
        ),
        200,
      );
    } catch (e) {
      throw ApiFailure.from(e);
    }
  }

  Future<void> deleteRating(int ratingId) async {
    try {
      final response = await _authDio.delete<Map<String, dynamic>>(
        '/v7/ratings/$ratingId',
        options: _authOptions,
      );
      final c = CommonResponse<Object?>.fromJson(response.data!, (v) => v);
      if (response.statusCode != 200 || !c.isSuccess || c.result != null) {
        throw ApiFailure(c.message, code: c.code, status: response.statusCode);
      }
    } catch (e) {
      throw ApiFailure.from(e);
    }
  }
}

String writeMyRatingsErrorMessage(Object error) =>
    ApiFailure.from(error).message;
