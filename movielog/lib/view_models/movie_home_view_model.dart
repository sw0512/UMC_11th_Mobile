import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieHomeLoadStatus { idle, loading, empty, error, success }

class MovieHomeViewModel extends ChangeNotifier {
  MovieHomeViewModel(this._service);
  final TmdbMovieService _service;
  List<TmdbMovieDto> movies = const [];
  MovieHomeLoadStatus status = MovieHomeLoadStatus.idle;
  String message = '';
  bool _disposed = false;
  int _version = 0;
  Future<void> loadPopular() async {
    final version = ++_version;
    status = MovieHomeLoadStatus.loading;
    notifyListeners();
    try {
      final page = await _service.fetchPopular();
      if (_disposed || version != _version) return;
      movies = List.unmodifiable(page.results.take(5));
      status = movies.isEmpty
          ? MovieHomeLoadStatus.empty
          : MovieHomeLoadStatus.success;
    } catch (_) {
      if (_disposed || version != _version) return;
      message = '인기 영화를 불러오지 못했어요. TMDB 토큰과 네트워크를 확인해 주세요.';
      status = MovieHomeLoadStatus.error;
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
