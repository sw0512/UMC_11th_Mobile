import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

const int sampleMemberId = 1;

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService);
  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final Map<int, TmdbMovieDto?> _cache = {};
  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;
  bool _disposed = false;
  int _version = 0;
  Future<void> load() async {
    if (_disposed) return;
    final version = ++_version;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();
    try {
      final raw = await _service.fetchMyRatings(sampleMemberId);
      if (_disposed || version != _version) return;
      final entries = <RatingWithMovie>[];
      final attempted = <int>{};
      var missing = 0;
      for (final rating in raw) {
        if (_disposed || version != _version) return;
        if (!_cache.containsKey(rating.movieId) &&
            attempted.add(rating.movieId)) {
          try {
            final movie = await _movieService.findMovieById(rating.movieId);
            if (_disposed || version != _version) return;
            _cache[rating.movieId] = movie;
          } on DioException {
            /* Transient failures are retried on the next load. */
          }
        }
        final movie = _cache[rating.movieId];
        if (movie == null) missing++;
        entries.add(RatingWithMovie(rating: rating, movie: movie));
      }
      if (_disposed || version != _version) return;
      ratings = List.unmodifiable(entries);
      status = ratings.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (missing > 0) message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
    } on DioException catch (error) {
      if (_disposed || version != _version) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    } catch (_) {
      if (_disposed || version != _version) return;
      status = MyRatingsLoadStatus.error;
      message = '평점 응답을 처리하지 못했습니다. 다시 시도해 주세요.';
    }
    if (!_disposed && version == _version) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _version++;
    super.dispose();
  }
}
