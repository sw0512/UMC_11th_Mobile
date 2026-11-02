import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/core/network/tmdb_logging_interceptor.dart';

void main() {
  test('Discover serializes OR genres and omits empty/all genres', () async {
    final dio = Dio();
    final requests = <RequestOptions>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'page': 1,
                'results': [],
                'total_pages': 0,
                'total_results': 0,
              },
            ),
          );
        },
      ),
    );
    final service = TmdbMovieService(dio);
    await service.discoverMovies(page: 1, genreIds: [28, 35]);
    await service.discoverMovies(page: 1, genreIds: []);
    await service.discoverMovies(page: 1);
    expect(requests[0].queryParameters['with_genres'], '28|35');
    expect(requests[1].queryParameters.containsKey('with_genres'), false);
    expect(requests[2].queryParameters.containsKey('with_genres'), false);
    expect(requests.every((r) => r.path == '/discover/movie'), true);
    dio.close();
  });
  test(
    'request and error logging masks authorization regardless of case',
    () async {
      final lines = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) lines.add(message);
      };
      addTearDown(() => debugPrint = original);
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://example.invalid',
          headers: {'authorization': 'Bearer secret-test-token'},
        ),
      );
      dio.interceptors.add(TmdbLoggingInterceptor());
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                message: 'Rejected Bearer secret-test-token',
              ),
              true,
            );
          },
        ),
      );
      await expectLater(
        dio.get('/movie/popular'),
        throwsA(isA<DioException>()),
      );
      final log = lines.join('\n');
      expect(log, contains('Bearer ***'));
      expect(log, contains('/movie/popular'));
      expect(log, contains('Rejected'));
      expect(log, isNot(contains('secret-test-token')));
      dio.close();
    },
  );
}
