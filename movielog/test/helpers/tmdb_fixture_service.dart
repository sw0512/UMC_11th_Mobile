import 'dart:async';

import 'package:dio/dio.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

TmdbMovieDto movie(int id) => TmdbMovieDto(
  id: id,
  title: '영화 $id',
  overview: '',
  posterPath: null,
  backdropPath: null,
  releaseDate: null,
  genreIds: [28],
  voteAverage: 8,
  popularity: 1,
);
TmdbMoviePageDto pageOf(List<int> ids, {int page = 1, int totalPages = 1}) =>
    TmdbMoviePageDto(
      page: page,
      results: ids.map(movie).toList(),
      totalPages: totalPages,
      totalResults: ids.length,
    );

class TmdbFixtureService extends TmdbMovieService {
  TmdbFixtureService() : super(Dio());
  int popularCalls = 0;
  bool fail = false;
  List<int> popularIds = [101, 102, 103, 104, 105, 106];
  final requests = <(int, List<int>?)>[];
  Map<int, List<int>> pages = {
    1: [101, 102],
  };
  Completer<TmdbMoviePageDto>? pending;
  @override
  Future<TmdbMovieDto> fetchMovieDetail(int movieId) async => movie(movieId);

  @override
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async {
    popularCalls++;
    if (fail) throw StateError('fixture failure');
    return pending?.future ?? Future.value(pageOf(popularIds));
  }

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async => [
    const TmdbGenreDto(id: 28, name: '액션'),
    const TmdbGenreDto(id: 35, name: '코미디'),
  ];
  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async {
    requests.add((page, genreIds));
    if (fail) throw StateError('fixture failure');
    return pending?.future ??
        Future.value(
          pageOf(pages[page] ?? [], page: page, totalPages: pages.length),
        );
  }
}
