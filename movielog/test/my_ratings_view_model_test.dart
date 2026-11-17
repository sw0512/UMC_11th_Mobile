import 'package:movielog/data/models/api_failure.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';

import 'helpers/week6_fixture_services.dart';
import 'helpers/auth_fixture.dart';

void main() {
  test(
    'session ratings preserve unknown movies and share cached movie metadata',
    () async {
      final service = RatingsFixtureService()
        ..items = [
          sampleRating(1, 550),
          sampleRating(2, 550),
          sampleRating(3, 999),
        ];
      final movies = DetailFixtureService()..missing.add(999);
      final store = seededRatings(service.items);
      final vm = MyRatingsViewModel(service, movies, store);
      await vm.load();
      expect(service.members, isEmpty);
      expect(movies.detailCalls, [550, 999]);
      expect(vm.ratings.length, 3);
      expect(vm.ratings.last.movie, isNull);
      await vm.load();
      expect(movies.detailCalls.length, 2);
      await store.auth.logout();
      expect(vm.ratings, isEmpty);
      expect(store.items, isEmpty);
      vm.dispose();
      store.dispose();
      store.auth.dispose();
    },
  );
  test(
    'partial delete retains failed selection and retries only failures',
    () async {
      final service = RatingsFixtureService()
        ..items = [sampleRating(1, 550), sampleRating(2, 680)]
        ..deleteFailures.add(2);
      final store = seededRatings(service.items);
      final vm = MyRatingsViewModel(service, DetailFixtureService(), store);
      await vm.load();
      vm.toggleEditing();
      vm.toggleSelected(1);
      vm.toggleSelected(2);
      await vm.deleteSelected();
      expect(vm.selectedRatingIds, {2});
      expect(store.items.single.ratingId, 2);
      service.deleteFailures.clear();
      await vm.deleteSelected();
      expect(service.deletes, [1, 2, 2]);
      expect(vm.ratings, isEmpty);
      vm.dispose();
      store.dispose();
      store.auth.dispose();
    },
  );
  test('server RATING404 removes the vanished current-session card without guessing a memberId', () async {
    final service = RatingsFixtureService()
      ..writeFailure = const ApiFailure(
        '없는 평점',
        code: 'RATING404_1',
        status: 404,
      );
    final store = seededRatings(service.items);
    final vm = MyRatingsViewModel(service, DetailFixtureService(), store);
    await vm.load();
    await expectLater(
      vm.updateRating(ratingId: 1, score: 5),
      throwsA(isA<ApiFailure>()),
    );
    expect(store.items, isEmpty);
    expect(vm.ratings, isEmpty);
    expect(service.members, isEmpty);
    expect(store.auth.status, AuthStatus.signedIn);
    vm.dispose();
    store.dispose();
    store.auth.dispose();
  });
}
