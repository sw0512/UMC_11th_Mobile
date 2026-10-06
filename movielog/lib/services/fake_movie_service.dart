import '../data/mock_movies.dart';
import '../models/movie.dart';

class FakeMovieService {
  const FakeMovieService();

  Future<List<Movie>> fetchMovies() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return mockMovies;
  }
}
