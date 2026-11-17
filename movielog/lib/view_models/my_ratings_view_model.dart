import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../data/models/api_failure.dart';
import 'auth_view_model.dart';
import 'session_ratings.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.session) {
    session.addListener(_changed);
  }
  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final SessionRatings session;
  AuthViewModel get auth => session.auth;
  final Map<int, TmdbMovieDto?> _cache = {};
  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;
  bool _disposed = false;
  int _version = 0;
  void _changed() {
    if (auth.status != AuthStatus.signedIn) {
      ratings = const [];
      _selected.clear();
      editing = false;
      _version++;
      if (!_disposed) notifyListeners();
    } else if (!isWriting) {
      load();
    }
  }

  Future<void> load({bool afterWrite = false}) async {
    if (_disposed || (isWriting && !afterWrite)) return;
    final version = ++_version;
    final sessionVersion = auth.sessionVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();
    final entries = <RatingWithMovie>[];
    final attempted = <int>{};
    for (final rating in session.items) {
      if (!_cache.containsKey(rating.movieId) &&
          attempted.add(rating.movieId)) {
        try {
          final movie = await _movieService.findMovieById(rating.movieId);
          if (_disposed ||
              version != _version ||
              !auth.isCurrent(sessionVersion)) {
            return;
          }
          _cache[rating.movieId] = movie;
        } catch (_) {
          /* Keep the rating even when TMDB is unavailable; retry metadata later. */
        }
      }
      entries.add(
        RatingWithMovie(rating: rating, movie: _cache[rating.movieId]),
      );
    }
    if (_disposed || version != _version || !auth.isCurrent(sessionVersion)) {
      return;
    }
    ratings = List.unmodifiable(entries);
    if (entries.any((r) => r.movie == null)) {
      message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
    }
    _selected.removeWhere((id) => !entries.any((r) => r.rating.ratingId == id));
    status = ratings.isEmpty
        ? MyRatingsLoadStatus.empty
        : MyRatingsLoadStatus.success;
    notifyListeners();
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
        !session.items.any((r) => r.ratingId == id)) {
      return;
    }
    if (!_selected.add(id)) _selected.remove(id);
    notifyListeners();
  }

  void _requireOwned(int id) {
    if (auth.status != AuthStatus.signedIn ||
        !session.items.any((r) => r.ratingId == id)) {
      throw const ApiFailure('현재 로그인에서 등록한 평점만 변경할 수 있습니다.');
    }
  }

  Future<void> _write(
    Future<void> Function(int) action, {
    required int ratingId,
  }) async {
    if (_disposed || isWriting) throw const ApiFailure('요청을 처리 중입니다.');
    final version = auth.sessionVersion;
    isWriting = true;
    writeMessage = null;
    notifyListeners();
    try {
      await action(version);
      if (!auth.isCurrent(version)) throw const ApiFailure('세션이 변경됐습니다.');
      await load(afterWrite: true);
    } catch (e) {
      await auth.handleFailure(e, version);
      if (_disposed) return;
      writeMessage = ApiFailure.from(e).message;
      if (ApiFailure.from(e).code == 'RATING404_1' && auth.isCurrent(version)) {
        session.remove(ratingId, version);
        await load(afterWrite: true);
        writeMessage = '서버에서 없어진 평점을 현재 세션 목록에서 제외했습니다.';
      }
      throw ApiFailure.from(e);
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
    await _write((version) async {
      final updated = await _service.updateRating(
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
      session.upsert(updated, version);
    }, ratingId: ratingId);
  }

  Future<void> deleteRating(int ratingId) async {
    _requireOwned(ratingId);
    await _write((version) async {
      await _service.deleteRating(ratingId);
      session.remove(ratingId, version);
    }, ratingId: ratingId);
  }

  Future<String> deleteSelected() async {
    if (_disposed || isWriting || _selected.isEmpty) return '';
    final ids = _selected.toList();
    for (final id in ids) {
      _requireOwned(id);
    }
    final version = auth.sessionVersion;
    isWriting = true;
    notifyListeners();
    var success = 0;
    try {
      for (final id in ids) {
        if (_disposed || !auth.isCurrent(version)) return '';
        try {
          await _service.deleteRating(id);
          if (!auth.isCurrent(version)) return '';
          session.remove(id, version);
          _selected.remove(id);
          success++;
        } catch (e) {
          await auth.handleFailure(e, version);
          if (!auth.isCurrent(version)) return '';
        }
      }
      if (_disposed || !auth.isCurrent(version)) return '';
      await load(afterWrite: true);
      if (_selected.isEmpty) editing = false;
      writeMessage = _selected.isEmpty
          ? '$success개의 평점을 삭제했습니다.'
          : '$success개 삭제, ${_selected.length}개 실패했습니다. 실패한 항목만 다시 시도해 주세요.';
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
    session.removeListener(_changed);
    super.dispose();
  }
}
