import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

import 'helpers/tmdb_fixture_service.dart';

void main() {
  test(
    'refresh keeps movies and OR genre IDs, blocks overlapping requests',
    () async {
      final service = TmdbFixtureService();
      final vm = MovieListViewModel(service);
      await vm.selectGenres([35, 28, 35]);
      expect(vm.selectedGenreIds, [28, 35]);
      service.pending = Completer<TmdbMoviePageDto>();
      final refresh = vm.refresh();
      expect(vm.movies.map((m) => m.id), [101, 102]);
      expect(vm.isRefreshing, true);
      await vm.refresh();
      await vm.selectGenres([99]);
      expect(service.requests.length, 2);
      expect(service.requests.last.$1, 1);
      expect(service.requests.last.$2, [28, 35]);
      service.pending!.complete(pageOf([200]));
      await refresh;
      expect(vm.movies.single.id, 200);
      expect(vm.isRefreshing, false);
      vm.dispose();
    },
  );
  test('failed new filter restores last success and retries the failed filter from page one', () async {
    final service = TmdbFixtureService();
    final vm = MovieListViewModel(service);
    await vm.selectGenres([28]);
    service.fail = true;
    await vm.selectGenres([35]);
    expect(vm.movies.map((m) => m.id), [101, 102]);
    expect(vm.displayedGenreIds, [28]);
    expect(vm.status, MovieListLoadStatus.error);
    service.fail = false;
    service.pages = {
      1: [300],
    };
    await vm.retry();
    expect(service.requests.last.$1, 1);
    expect(service.requests.last.$2, [35]);
    expect(vm.movies.single.id, 300);
    vm.dispose();
  });
  test(
    'cancel restores successful filter and empty selection requests all',
    () async {
      final service = TmdbFixtureService();
      final vm = MovieListViewModel(service);
      await vm.selectGenres([28]);
      service.fail = true;
      await vm.selectGenres([35]);
      vm.dismissError();
      expect(vm.selectedGenreIds, [28]);
      expect(vm.status, MovieListLoadStatus.success);
      service.fail = false;
      await vm.selectGenres([]);
      expect(service.requests.last, (1, null));
      vm.dispose();
    },
  );
  test('partial pagination failure never publishes partial results', () async {
    final service = PageTwoFailure();
    final vm = MovieListViewModel(service);
    await vm.loadInitial();
    expect(vm.movies, isEmpty);
    expect(vm.status, MovieListLoadStatus.error);
    vm.dispose();
  });
}

class PageTwoFailure extends TmdbFixtureService {
  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    List<int>? genreIds,
  }) async {
    if (page == 2) throw StateError('page two failed');
    return pageOf([1, 2], totalPages: 2);
  }
}
