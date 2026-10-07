import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/mock_movies.dart';
import 'package:movielog/services/fake_movie_service.dart';

void main() {
  const service = FakeMovieService();

  test('success returns the original movie list', () async {
    expect(await service.fetchMovies(), mockMovies);
  });

  test('empty returns a normal empty result', () async {
    expect(await service.fetchMovies(mode: MovieLoadMode.empty), isEmpty);
  });

  test('failure completes with MovieLoadException', () async {
    await expectLater(
      service.fetchMovies(mode: MovieLoadMode.failure),
      throwsA(isA<MovieLoadException>()),
    );
  });
}
