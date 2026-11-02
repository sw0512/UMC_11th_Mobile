import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/models/tmdb_genre_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieListLoadStatus { idle, loading, empty, error, success }

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service);
  final TmdbMovieService _service;
  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];
  List<int>? selectedGenreIds;
  List<int>? displayedGenreIds;
  List<int>? _failedGenreIds;
  List<TmdbMovieDto> _lastSuccess = const [];
  bool _hasSuccess = false;
  bool isRefreshing = false;
  int errorVersion = 0;
  String message = '';
  MovieListLoadStatus status = MovieListLoadStatus.idle;
  bool _disposed = false;
  int _version = 0;
  bool get isLoading => status == MovieListLoadStatus.loading;
  bool get showingPreviousResults =>
      status == MovieListLoadStatus.error && _hasSuccess;

  Future<List<TmdbMovieDto>> _fetchThirty(List<int>? ids, int version) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    while (!_disposed && version == _version && byId.length < 30) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreIds: ids,
      );
      if (_disposed || version != _version) return const [];
      for (final movie in page.results) {
        byId.putIfAbsent(movie.id, () => movie);
        if (byId.length == 30) break;
      }
      if (page.results.isEmpty || pageNumber >= page.totalPages) break;
      pageNumber++;
    }
    return List.unmodifiable(byId.values);
  }

  Future<void> loadInitial() => _load();
  Future<void> refresh() => _load(refresh: true);
  Future<void> selectGenre(int? id) => selectGenres(id == null ? null : [id]);
  Future<void> selectGenres(List<int>? ids) async {
    if (_disposed || isLoading) return;
    final normalized = ids == null ? <int>[] : (ids.toSet().toList()..sort());
    selectedGenreIds = normalized.isEmpty
        ? null
        : List.unmodifiable(normalized);
    await _load();
  }

  Future<void> retry() async {
    if (_disposed || isLoading) return;
    selectedGenreIds = _failedGenreIds;
    await _load(refresh: _hasSuccess);
  }

  void dismissError() {
    if (_disposed || status != MovieListLoadStatus.error) return;
    if (_hasSuccess) {
      selectedGenreIds = displayedGenreIds;
      status = movies.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
      message = '';
      notifyListeners();
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (_disposed || isLoading) return;
    final version = ++_version;
    final requested = selectedGenreIds;
    isRefreshing = refresh && _hasSuccess;
    if (!isRefreshing) movies = const [];
    status = MovieListLoadStatus.loading;
    message = '';
    notifyListeners();
    try {
      if (genres.isEmpty) {
        final result = await _service.fetchGenres();
        if (_disposed || version != _version) return;
        genres = List.unmodifiable(result);
      }
      final result = await _fetchThirty(requested, version);
      if (_disposed || version != _version) return;
      movies = result;
      _lastSuccess = result;
      _hasSuccess = true;
      displayedGenreIds = requested;
      status = result.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } catch (_) {
      if (_disposed || version != _version) return;
      movies = _lastSuccess;
      _failedGenreIds = requested;
      status = MovieListLoadStatus.error;
      message = '영화를 불러오지 못했어요. 네트워크를 확인하고 다시 시도해 주세요.';
      errorVersion++;
    }
    if (!_disposed && version == _version) {
      isRefreshing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _version++;
    super.dispose();
  }
}
