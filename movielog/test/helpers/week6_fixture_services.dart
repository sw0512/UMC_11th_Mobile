import 'dart:async';

import 'package:dio/dio.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';

import 'tmdb_fixture_service.dart';

class CheckFixtureService extends MemberCheckService {
  CheckFixtureService() : super(Dio());
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
