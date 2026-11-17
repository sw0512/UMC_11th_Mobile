import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/api_failure.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/services/sign_up_service.dart';

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
  test(
    'signup consumes signup wrapper and requires an actual member id',
    () async {
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
      expect(sent!.path, '/v7/members');
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
    },
  );
}
