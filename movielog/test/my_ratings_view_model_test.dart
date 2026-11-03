import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';

import 'helpers/week6_fixture_services.dart';

void main() {
  test('RatingDto accepts numeric values and null comment', () {
    final dto = RatingDto.fromJson({
      'ratingId': 1.0,
      'movieId': 550,
      'score': 5,
      'comment': null,
      'createdAt': '2026-11-03T00:00:00Z',
    });
    expect(dto.ratingId, 1);
    expect(dto.comment, isNull);
    expect(dto.createdAt.isUtc, true);
  });
  test('member 1 is fixed; repeated movies are fetched once and 404 preserves ratings', () async {
    final service = RatingsFixtureService()
      ..items = [
        sampleRating(1, 550),
        sampleRating(2, 550),
        sampleRating(3, 999),
      ];
    final movies = DetailFixtureService()..missing.add(999);
    final vm = MyRatingsViewModel(service, movies);
    await vm.load();
    expect(service.members, [1]);
    expect(movies.detailCalls, [550, 999]);
    expect(vm.ratings.length, 3);
    expect(vm.ratings.last.movie, isNull);
    expect(vm.ratings.last.rating.movieId, 999);
    expect(vm.status, MyRatingsLoadStatus.success);
    expect(vm.message, isNotNull);
    await vm.load();
    expect(movies.detailCalls.length, 2);
    vm.dispose();
  });
  test(
    'transient TMDB failures are retried on next load without losing ratings',
    () async {
      final service = RatingsFixtureService()
        ..items = [sampleRating(1, 550), sampleRating(2, 550)];
      final movies = DetailFixtureService()..transient.add(550);
      final vm = MyRatingsViewModel(service, movies);
      await vm.load();
      expect(vm.ratings.length, 2);
      expect(movies.detailCalls, [550]);
      movies.transient.clear();
      await vm.load();
      expect(vm.ratings.first.movie, isNotNull);
      expect(movies.detailCalls, [550, 550]);
      vm.dispose();
    },
  );
  test('empty differs from 400, 404 and connection errors', () async {
    final service = RatingsFixtureService()..items = [];
    final vm = MyRatingsViewModel(service, DetailFixtureService());
    await vm.load();
    expect(vm.status, MyRatingsLoadStatus.empty);
    for (final status in <int?>[400, 404, 500, null]) {
      final options = RequestOptions(path: '/ratings');
      service.failure = DioException(
        requestOptions: options,
        response: status == null
            ? null
            : Response(requestOptions: options, statusCode: status),
      );
      await vm.load();
      expect(vm.status, MyRatingsLoadStatus.error);
      expect(
        vm.message,
        contains(
          status == 400
              ? 'memberId'
              : status == 404
              ? '존재하지'
              : '잠시 후',
        ),
      );
    }
    vm.dispose();
  });
  test(
    'older load and disposed view model cannot publish delayed data',
    () async {
      final service = RatingsFixtureService()
        ..pending = Completer<List<RatingDto>>();
      final vm = MyRatingsViewModel(service, DetailFixtureService());
      final first = service.pending!;
      final old = vm.load();
      service.pending = null;
      service.items = [];
      await vm.load();
      first.complete([sampleRating(1, 550)]);
      await old;
      expect(vm.status, MyRatingsLoadStatus.empty);
      service.pending = Completer<List<RatingDto>>();
      final pending = vm.load();
      vm.dispose();
      service.pending!.complete([]);
      await pending;
    },
  );
}
