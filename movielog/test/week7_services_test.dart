import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/api_failure.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';

void main() {
  test('request JSON trims profile values but preserves the password; score rejects fractions and non-finite values', () {
    final body = const CreateMemberRequest(
      email: ' demo@example.com ',
      password: ' MockPass123! ',
      nickname: ' 무비 ',
    ).toJson();
    expect(body['email'], 'demo@example.com');
    expect(body['nickname'], '무비');
    expect(body['password'], ' MockPass123! ');
    for (final v in [0.0, 0.5, 2.5, 6.0, double.nan, double.infinity]) {
      expect(() => validateServerScore(v), throwsArgumentError);
    }
    expect(validateServerScore(5), 5);
    expect(
      const CreateRatingRequest(movieId: 550, score: 5, comment: '  ').toJson(),
      {'movieId': 550, 'score': 5},
    );
    expect(
      () => CreateRatingRequest(
        movieId: 550,
        score: 5,
        comment: 'x' * 501,
      ).toJson(),
      throwsArgumentError,
    );
  });
  test('common result supports null and scalars without forced casts', () {
    expect(
      CommonResponse<Object?>.fromJson({
        'isSuccess': true,
        'code': 'COMMON201',
        'message': 'ok',
        'result': null,
      }, (v) => v).result,
      isNull,
    );
    expect(
      CommonResponse<Object?>.fromJson({
        'isSuccess': true,
        'code': 'COMMON201',
        'message': 'ok',
        'result': 42,
      }, (v) => v).result,
      42,
    );
  });
  test('signup consumes v6 wrapper and requires an actual member id', () async {
    final dio = Dio();
    bool missing = false;
    RequestOptions? sent;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          sent = o;
          h.resolve(
            Response(
              requestOptions: o,
              statusCode: 201,
              data: {
                'isSuccess': true,
                'code': 'COMMON201',
                'message': '가입 완료',
                'result': missing
                    ? null
                    : {
                        'memberId': 77,
                        'email': 'demo@example.com',
                        'nickname': '무비',
                      },
              },
            ),
          );
        },
      ),
    );
    final service = SignUpService(dio);
    final response = await service.signUp(
      const CreateMemberRequest(
        email: 'demo@example.com',
        password: 'MockPass123!',
        nickname: '무비',
      ),
    );
    expect(response.result!.memberId, 77);
    expect(sent!.path, '/v6/members');
    expect(sent!.method, 'POST');
    missing = true;
    await expectLater(
      service.signUp(
        const CreateMemberRequest(
          email: 'demo@example.com',
          password: 'MockPass123!',
          nickname: '무비',
        ),
      ),
      throwsA(isA<ApiFailure>()),
    );
    dio.close();
  });
  test(
    'rating writes honor 201 wrapper, PATCH explicit comment and empty 204',
    () async {
      final dio = Dio();
      final sent = <RequestOptions>[];
      bool numeric = false;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            sent.add(o);
            h.resolve(
              Response(
                requestOptions: o,
                statusCode: o.method == 'POST'
                    ? 201
                    : o.method == 'DELETE'
                    ? 204
                    : 200,
                data: o.method == 'DELETE'
                    ? null
                    : {
                        'isSuccess': true,
                        'code': 'COMMON200',
                        'message': 'ok',
                        'result': numeric ? 7 : null,
                      },
              ),
            );
          },
        ),
      );
      final service = RatingApiService(dio);
      await service.createRating(
        memberId: 77,
        request: const CreateRatingRequest(movieId: 550, score: 5),
      );
      numeric = true;
      await service.createRating(
        memberId: 77,
        request: const CreateRatingRequest(
          movieId: 680,
          score: 4,
          comment: ' 후기 ',
        ),
      );
      await service.updateRating(
        memberId: 77,
        ratingId: 12,
        score: 3,
        comment: ' 기존 후기 ',
      );
      await service.updateRating(
        memberId: 77,
        ratingId: 12,
        score: 3,
        comment: ' ',
      );
      await service.deleteRating(memberId: 77, ratingId: 12);
      expect(sent.first.path, '/v6/members/77/ratings');
      expect(sent.first.data, {'movieId': 550, 'score': 5});
      expect(sent[1].data['comment'], '후기');
      expect(sent[2].data, {'score': 3, 'comment': '기존 후기'});
      expect(sent[3].data.containsKey('comment'), true);
      expect(sent[3].data['comment'], isNull);
      expect(sent.last.method, 'DELETE');
      dio.close();
    },
  );
  test(
    '400 403 404 409 keep server messages and drive distinct refresh decisions',
    () async {
      final dio = Dio();
      int status = 400;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) => h.reject(
            DioException(
              requestOptions: o,
              response: Response(
                requestOptions: o,
                statusCode: status,
                data: {
                  'isSuccess': false,
                  'code': 'COMMON$status',
                  'message': '서버 안내 $status',
                  'result': null,
                },
              ),
            ),
          ),
        ),
      );
      for (final code in [400, 403, 404, 409]) {
        status = code;
        try {
          await RatingApiService(dio).deleteRating(memberId: 77, ratingId: 12);
          fail('must fail');
        } on ApiFailure catch (e) {
          expect(e.status, code);
          expect(e.code, 'COMMON$code');
          expect(e.message, '서버 안내 $code');
          expect(e.shouldRefresh, [403, 404].contains(code));
        }
      }
      dio.close();
    },
  );
}
