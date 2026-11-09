import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../data/models/api_failure.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);
  final int memberId;
  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final Map<int, TmdbMovieDto?> _cache = {};
  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;
  bool _disposed = false;
  int _version = 0;
  Future<void> load({bool afterWrite = false}) async {
    if (_disposed || (isWriting && !afterWrite)) return;
    final version = ++_version;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();
    try {
      final raw = await _service.fetchMyRatings(memberId);
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
      refreshWarning = null;
      final ids = entries.map((r) => r.rating.ratingId).toSet();
      _selected.removeWhere((id) => !ids.contains(id));
      status = ratings.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (missing > 0) message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
    } on ApiFailure catch (error) {
      if (_disposed || version != _version) return;
      status = MyRatingsLoadStatus.error;
      message = error.message;
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

  bool isWriting = false;
  bool editing = false;
  final Set<int> _selected = {};
  Set<int> get selectedRatingIds => Set.unmodifiable(_selected);
  String? refreshWarning;
  String? writeMessage;
  void toggleEditing() {
    if (_disposed || isWriting) return;
    editing = !editing;
    _selected.clear();
    notifyListeners();
  }

  void toggleSelected(int id) {
    if (_disposed ||
        isWriting ||
        !editing ||
        !ratings.any((r) => r.rating.ratingId == id)) {
      return;
    }
    if (!_selected.add(id)) _selected.remove(id);
    notifyListeners();
  }

  void _requireOwned(int id) {
    if (!ratings.any((r) => r.rating.ratingId == id)) {
      throw const ApiFailure(
        '현재 회원의 평점만 변경할 수 있습니다.',
        code: 'COMMON403',
        status: 403,
      );
    }
  }

  Future<void> _refreshAfterWrite() async {
    await load(afterWrite: true);
    if (_disposed) return;
    if (status == MyRatingsLoadStatus.error) {
      refreshWarning = '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
    }
    notifyListeners();
  }

  Future<void> _write(Future<void> Function() action, {int? deletingId}) async {
    if (_disposed || isWriting) throw const ApiFailure('요청을 처리 중입니다.');
    isWriting = true;
    writeMessage = null;
    notifyListeners();
    try {
      await action();
      if (_disposed) return;
      if (deletingId != null) {
        ratings = List.unmodifiable(
          ratings.where((r) => r.rating.ratingId != deletingId),
        );
        _selected.remove(deletingId);
      }
      await _refreshAfterWrite();
    } catch (e) {
      if (_disposed) return;
      final error = ApiFailure.from(e);
      writeMessage = error.message;
      if (error.shouldRefresh) await load(afterWrite: true);
      throw error;
    } finally {
      if (!_disposed) {
        isWriting = false;
        notifyListeners();
      }
    }
  }

  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    _requireOwned(ratingId);
    await _write(
      () => _service.updateRating(
        memberId: memberId,
        ratingId: ratingId,
        score: score,
        comment: comment,
      ),
    );
  }

  Future<void> deleteRating(int ratingId) async {
    _requireOwned(ratingId);
    await _write(
      () => _service.deleteRating(memberId: memberId, ratingId: ratingId),
      deletingId: ratingId,
    );
  }

  Future<String> deleteSelected() async {
    if (_disposed || isWriting || _selected.isEmpty) return '';
    final ids = _selected.toList();
    for (final id in ids) {
      _requireOwned(id);
    }
    isWriting = true;
    writeMessage = null;
    notifyListeners();
    final succeeded = <int>{};
    final failed = <int>{};
    try {
      for (final id in ids) {
        if (_disposed) return '';
        try {
          await _service.deleteRating(memberId: memberId, ratingId: id);
          succeeded.add(id);
        } catch (_) {
          failed.add(id);
        }
      }
      if (_disposed) return '';
      ratings = List.unmodifiable(
        ratings.where((r) => !succeeded.contains(r.rating.ratingId)),
      );
      _selected.removeAll(succeeded);
      await _refreshAfterWrite();
      if (_disposed) return '';
      final existing = ratings.map((r) => r.rating.ratingId).toSet();
      _selected.removeWhere((id) => !existing.contains(id));
      if (failed.isEmpty) {
        editing = false;
        _selected.clear();
      }
      writeMessage = failed.isEmpty
          ? '${succeeded.length}개의 평점을 삭제했습니다.'
          : '${succeeded.length}개 삭제, ${failed.length}개 삭제에 실패했습니다. 실패한 항목을 다시 시도해 주세요.';
      return writeMessage!;
    } finally {
      if (!_disposed) {
        isWriting = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _version++;
    super.dispose();
  }
}
