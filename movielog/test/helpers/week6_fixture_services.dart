import 'dart:async';

import 'package:dio/dio.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';

import 'tmdb_fixture_service.dart';

import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/api_failure.dart';

class CheckFixtureService extends SignUpService {
  CheckFixtureService() : super(Dio());
  int signups = 0;
  ApiFailure? signupFailure;
  Completer<CommonResponse<SignUpResult>>? signupPending;
  @override
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    signups++;
    if (signupFailure != null) throw signupFailure!;
    return signupPending?.future ??
        Future.value(
          CommonResponse(
            isSuccess: true,
            code: 'COMMON201',
            message: '회원가입 성공',
            result: SignUpResult(
              memberId: 77,
              email: request.email.trim(),
              nickname: request.nickname.trim(),
            ),
          ),
        );
  }

  bool available = true;
  bool fail = false;
  int nicknameCalls = 0;
  int emailCalls = 0;
  Completer<bool>? nicknamePending;
  Completer<bool>? emailPending;
  @override
  Future<bool> checkNickname(String nickname) async {
    nicknameCalls++;
    if (fail) {
      throw DioException(requestOptions: RequestOptions(path: '/nickname'));
    }
    return nicknamePending?.future ?? Future.value(available);
  }

  @override
  Future<bool> checkEmail(String email) async {
    emailCalls++;
    if (fail) {
      throw DioException(requestOptions: RequestOptions(path: '/email'));
    }
    return emailPending?.future ?? Future.value(available);
  }
}

RatingDto sampleRating(int id, int movieId, {String? comment}) => RatingDto(
  ratingId: id,
  movieId: movieId,
  score: 4,
  comment: comment,
  createdAt: DateTime.utc(2026, 11, 3),
);

class RatingsFixtureService extends RatingApiService {
  RatingsFixtureService() : super(Dio());
  List<RatingDto> items = [sampleRating(1, 550, comment: '좋은 영화')];
  DioException? failure;
  Completer<List<RatingDto>>? pending;
  final members = <int>[];
  final createRequests = <CreateRatingRequest>[];
  final writeMembers = <int>[];
  int creates = 0;
  int updates = 0;
  final deletes = <int>[];
  final deleteFailures = <int>{};
  ApiFailure? writeFailure;
  bool failReadAfterWrite = false;
  Completer<void>? writeGate;
  Future<void> beforeWrite() async {
    await writeGate?.future;
    if (writeFailure != null) throw writeFailure!;
  }

  @override
  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    creates++;
    createRequests.add(request);
    writeMembers.add(memberId);
    await beforeWrite();
    items = [
      ...items,
      RatingDto(
        ratingId: 1000 + creates,
        movieId: request.movieId,
        score: request.score,
        comment: request.comment,
        createdAt: DateTime.utc(2026, 11, 8),
      ),
    ];
    if (failReadAfterWrite) {
      failure = DioException(requestOptions: RequestOptions(path: '/ratings'));
    }
  }

  @override
  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    updates++;
    writeMembers.add(memberId);
    await beforeWrite();
    items = items
        .map(
          (r) => r.ratingId != ratingId
              ? r
              : RatingDto(
                  ratingId: r.ratingId,
                  movieId: r.movieId,
                  score: score,
                  comment: comment,
                  createdAt: r.createdAt,
                ),
        )
        .toList();
    if (failReadAfterWrite) {
      failure = DioException(requestOptions: RequestOptions(path: '/ratings'));
    }
  }

  @override
  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    deletes.add(ratingId);
    writeMembers.add(memberId);
    await beforeWrite();
    if (deleteFailures.contains(ratingId)) {
      throw const ApiFailure('삭제 실패', code: 'COMMON403', status: 403);
    }
    items = items.where((r) => r.ratingId != ratingId).toList();
    if (failReadAfterWrite) {
      failure = DioException(requestOptions: RequestOptions(path: '/ratings'));
    }
  }

  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    members.add(memberId);
    if (failure != null) throw failure!;
    return pending?.future ?? Future.value(items);
  }
}

class DetailFixtureService extends TmdbFixtureService {
  final detailCalls = <int>[];
  final missing = <int>{};
  final transient = <int>{};
  @override
  Future<TmdbMovieDto?> findMovieById(int id) async {
    detailCalls.add(id);
    if (transient.contains(id)) {
      throw DioException(requestOptions: RequestOptions(path: '/movie/$id'));
    }
    return missing.contains(id) ? null : movie(id);
  }
}
