import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

void main() {
  test('v5 services parse direct bodies and URI encode path values without adding TMDB authorization', () async {
    final dio = Dio();
    final requests = <RequestOptions>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          requests.add(o);
          h.resolve(
            Response(
              requestOptions: o,
              statusCode: 200,
              data: o.path.endsWith('/ratings') ? [] : {'available': false},
            ),
          );
        },
      ),
    );
    final check = SignUpService(dio);
    expect(await check.checkNickname(' 영화/광 '), false);
    expect(await check.checkEmail(' name+tag@example.com '), false);
    expect(await RatingApiService(dio).fetchMyRatings(1), isEmpty);
    expect(requests[0].uri.pathSegments.last, '영화/광');
    expect(requests[1].uri.pathSegments.last, 'name+tag@example.com');
    expect(requests[2].path, '/v6/members/1/ratings');
    expect(
      requests.every(
        (r) => r.method == 'GET' && !r.headers.containsKey('Authorization'),
      ),
      true,
    );
    dio.close();
  });
  test('TMDB detail maps genres and only 404 becomes null', () async {
    final dio = Dio();
    int status = 200;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          if (status != 200) {
            h.reject(
              DioException(
                requestOptions: o,
                response: Response(requestOptions: o, statusCode: status),
              ),
            );
            return;
          }
          h.resolve(
            Response(
              requestOptions: o,
              statusCode: 200,
              data: {
                'id': 550,
                'title': '영화',
                'genres': [
                  {'id': 18, 'name': '드라마'},
                ],
              },
            ),
          );
        },
      ),
    );
    final service = TmdbMovieService(dio);
    expect((await service.fetchMovieDetail(550)).genreIds, [18]);
    status = 404;
    expect(await service.findMovieById(550), isNull);
    status = 500;
    await expectLater(service.findMovieById(550), throwsA(isA<DioException>()));
    dio.close();
  });
}
