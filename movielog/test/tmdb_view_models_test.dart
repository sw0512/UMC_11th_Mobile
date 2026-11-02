import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

import 'helpers/tmdb_fixture_service.dart';

void main() {
  test('DTO converts numeric and nullable fields', () {
    final dto = TmdbMovieDto.fromJson({
      'id': 550,
      'vote_average': 8,
      'genre_ids': [28.0],
    });
    expect(dto.voteAverage, 8.0);
    expect(dto.posterPath, isNull);
    expect(dto.genreIds, [28]);
  });
  test(
    'popular uses at most five and handles short and empty responses',
    () async {
      final service = TmdbFixtureService();
      final vm = MovieHomeViewModel(service);
      await vm.loadPopular();
      expect(vm.movies.length, 5);
      service.popularIds = [1];
      await vm.loadPopular();
      expect(vm.movies.length, 1);
      service.popularIds = [];
      await vm.loadPopular();
      expect(vm.status, MovieHomeLoadStatus.empty);
      vm.dispose();
    },
  );
  test('discover deduplicates pages and stops at thirty', () async {
    final service = TmdbFixtureService()
      ..pages = {
        1: List.generate(20, (i) => i),
        2: List.generate(20, (i) => i + 15),
        3: [100],
      };
    final vm = MovieListViewModel(service);
    await vm.loadInitial();
    expect(vm.movies.length, 30);
    expect(vm.movies.map((m) => m.id).toSet().length, 30);
    expect(service.requests, [(1, null), (2, null)]);
    await vm.selectGenre(28);
    expect(service.requests[2].$1, 1);
    expect(service.requests[2].$2, [28]);
    vm.dispose();
  });
  test(
    'loading blocks genre changes and completion after dispose is ignored',
    () async {
      final service = TmdbFixtureService()
        ..pending = Completer<TmdbMoviePageDto>();
      final vm = MovieListViewModel(service);
      final load = vm.loadInitial();
      await vm.selectGenre(28);
      expect(vm.selectedGenreIds, isNull);
      vm.dispose();
      service.pending!.complete(pageOf([1]));
      await load;
    },
  );
  test('home late responses cannot overwrite a newer result', () async {
    final service = TmdbFixtureService()
      ..pending = Completer<TmdbMoviePageDto>();
    final vm = MovieHomeViewModel(service);
    final pending = service.pending!;
    final old = vm.loadPopular();
    service.pending = null;
    service.popularIds = [999];
    await vm.loadPopular();
    pending.complete(pageOf([1]));
    await old;
    expect(vm.movies.single.id, 999);
    vm.dispose();
  });
}
