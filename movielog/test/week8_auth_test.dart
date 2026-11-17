import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/data/models/api_failure.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/edit_profile_view_model.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/session_ratings.dart';

import 'helpers/auth_fixture.dart';
import 'helpers/tmdb_fixture_service.dart';
import 'helpers/week6_fixture_services.dart';

class Adapter implements HttpClientAdapter {
  Adapter(this.respond);
  final FutureOr<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody body(int status, Object? data) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);
Map<String, dynamic> wrapper(Object? result) => {
  'isSuccess': true,
  'code': 'COMMON200',
  'message': 'ok',
  'result': result,
};
void main() {
  test(
    'restore waits for GET me; network errors retain token and retry',
    () async {
      final storage = MemoryTokenStorage()..token = 'existing';
      final member = MemberFixtureService()..gate = Completer<MemberInfo>();
      final auth = AuthViewModel(AuthFixtureService(), member, storage);
      final pending = auth.restoreSession();
      await Future<void>.delayed(Duration.zero);
      expect(auth.status, AuthStatus.initializing);
      expect(auth.member, isNull);
      member.gate!.complete(fixtureMember());
      await pending;
      expect(auth.status, AuthStatus.signedIn);
      expect(member.gets, 1);
      member.gate = null;
      member.failure = const ApiFailure('offline');
      await auth.restoreSession();
      expect(auth.status, AuthStatus.retryRequired);
      expect(storage.token, 'existing');
      expect(storage.deletes, 0);
      member.failure = null;
      await auth.restoreSession();
      expect(auth.status, AuthStatus.signedIn);
      auth.dispose();
    },
  );
  test(
    'login failure 401 is a form error; login does not issue GET me',
    () async {
      final api = AuthFixtureService()
        ..failure = const ApiFailure('잘못된 입력', code: 'AUTH401_1', status: 401);
      final storage = MemoryTokenStorage();
      final member = MemberFixtureService();
      final auth = AuthViewModel(api, member, storage);
      await auth.login(' demo@example.com ', ' short ');
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, false);
      expect(storage.deletes, 0);
      expect(auth.message, contains('비밀번호'));
      api.failure = null;
      await auth.login(' demo@example.com ', ' short ');
      expect(auth.status, AuthStatus.signedIn);
      expect(api.request!.toJson()['password'], ' short ');
      expect(member.gets, 0);
      await auth.loadMember();
      await auth.loadMember();
      expect(member.gets, 1);
      auth.dispose();
    },
  );
  test('storage read/save failures differ from expiry; delete failure blocks login until cleanup', () async {
    final storage = MemoryTokenStorage()..readFailure = StateError('read');
    final api = AuthFixtureService();
    final auth = AuthViewModel(api, MemberFixtureService(), storage);
    await auth.restoreSession();
    expect(auth.status, AuthStatus.retryRequired);
    expect(storage.deletes, 0);
    storage.readFailure = null;
    storage.writeFailure = StateError('save');
    await auth.login('demo@example.com', 'password');
    expect(auth.status, AuthStatus.signedOut);
    expect(auth.message, contains('저장'));
    expect(auth.sessionExpired, false);
    storage.writeFailure = null;
    await auth.login('demo@example.com', 'password');
    storage.deleteFailure = StateError('delete');
    await auth.logout();
    expect(auth.storageCleanupFailed, true);
    final calls = api.calls;
    await auth.login('demo@example.com', 'password');
    expect(api.calls, calls);
    storage.deleteFailure = null;
    await auth.retryStorageCleanup();
    expect(auth.storageCleanupFailed, false);
    expect(storage.token, isNull);
    auth.dispose();
  });
  test(
    'logout waits for in-flight token write; new login blocked during cleanup',
    () async {
      final storage = MemoryTokenStorage()..writeGate = Completer<void>();
      final api = AuthFixtureService();
      final auth = AuthViewModel(api, MemberFixtureService(), storage);
      final logging = auth.login('demo@example.com', 'pw');
      await Future<void>.delayed(Duration.zero);
      expect(storage.writes, 1);
      final logout = auth.logout();
      await auth.login('new@example.com', 'pw');
      expect(api.calls, 1);
      expect(auth.storageCleanupInProgress, true);
      storage.writeGate!.complete();
      await logging;
      await logout;
      expect(storage.token, isNull);
      expect(auth.status, AuthStatus.signedOut);
      auth.dispose();
    },
  );
  test(
    'concurrent expiry clears once, old session expiry cannot clear new login',
    () async {
      final storage = MemoryTokenStorage()..token = 'test';
      final auth = AuthViewModel(
        AuthFixtureService(),
        MemberFixtureService(),
        storage,
      )..status = AuthStatus.signedIn;
      final old = auth.sessionVersion;
      await Future.wait([
        auth.expireSession(expectedVersion: old),
        auth.expireSession(expectedVersion: old),
        auth.expireSession(expectedVersion: old),
      ]);
      expect(storage.deletes, 1);
      expect(auth.sessionExpired, true);
      auth.consumeSessionExpired();
      await auth.login('demo@example.com', 'pw');
      await auth.expireSession(expectedVersion: old);
      expect(auth.status, AuthStatus.signedIn);
      expect(storage.deletes, 1);
      auth.dispose();
    },
  );
  test(
    'late GET me and profile PATCH cannot overwrite a different session',
    () async {
      final member = MemberFixtureService()..gate = Completer<MemberInfo>();
      final auth = AuthViewModel(
        AuthFixtureService(),
        member,
        MemoryTokenStorage(),
      )..status = AuthStatus.signedIn;
      final pending = auth.loadMember();
      await auth.logout();
      await auth.login('other@example.com', 'pw');
      member.gate!.complete(fixtureMember(nickname: '이전 계정'));
      await pending;
      expect(auth.member, isNull);
      auth.member = fixtureMember();
      member.gate = Completer<MemberInfo>();
      final vm = EditProfileViewModel(member, auth);
      final patch = vm.save('새 닉네임');
      await auth.logout();
      await auth.login('third@example.com', 'pw');
      member.gate!.complete(fixtureMember(nickname: '이전 수정'));
      expect(await patch, false);
      expect(auth.member, isNull);
      vm.dispose();
      auth.dispose();
    },
  );
  test('profile validates, skips unchanged, preserves duplicate input and replaces member on success', () async {
    final member = MemberFixtureService();
    final auth = signedInAuth();
    final vm = EditProfileViewModel(member, auth);
    expect(await vm.save('x'), false);
    expect(member.patches, 0);
    expect(await vm.save('무비러버'), true);
    expect(member.patches, 0);
    member.failure = const ApiFailure(
      '이미 사용 중인 닉네임이에요.',
      code: 'MEMBER409_1',
      status: 409,
    );
    expect(await vm.save('중복 이름'), false);
    expect(vm.nicknameError, contains('이미'));
    expect(auth.status, AuthStatus.signedIn);
    member.failure = null;
    expect(await vm.save('새 닉네임'), true);
    expect(auth.member!.nickname, '새 닉네임');
    vm.dispose();
    auth.dispose();
  });
  test('protected host/path only gets fresh JWT; public/TMDB requests never inherit JWT', () async {
    final storage = MemoryTokenStorage()..token = 'only-test-value';
    int expired = 0;
    final client = createAuthMovieLogClient(
      storage,
      sessionVersion: () => 1,
      onExpired: (_) async {
        expired++;
      },
    );
    final sent = <RequestOptions>[];
    client.httpClientAdapter = Adapter((o) {
      sent.add(o);
      return body(200, wrapper(null));
    });
    for (final url in [
      '/v7/members/me',
      '/v7/ratings',
      '/v7/ratings/12',
      '/v7/auth/login',
      '/v7/members/1/ratings',
      '/v7/ratings/12/extra',
      'https://api.themoviedb.org/v7/ratings',
      'http://workbook.devnoco.com/v7/ratings',
    ]) {
      await client.get(
        url,
        options: Options(headers: {'Authorization': 'stale'}),
      );
    }
    expect(
      sent
          .take(3)
          .every((o) => o.headers['Authorization'] == 'Bearer only-test-value'),
      true,
    );
    expect(
      sent.skip(3).every((o) => !o.headers.containsKey('Authorization')),
      true,
    );
    expect(expired, 0);
    client.close();
  });
  test(
    'interceptor ignores 403 and old 401 but expires current protected 401',
    () async {
      final storage = MemoryTokenStorage()..token = 'test';
      var version = 1;
      var expired = 0;
      final client = createAuthMovieLogClient(
        storage,
        sessionVersion: () => version,
        onExpired: (v) async {
          expired++;
          version++;
        },
      );
      final pending = Completer<ResponseBody>();
      final started = Completer<void>();
      client.httpClientAdapter = Adapter((_) {
        started.complete();
        return pending.future;
      });
      final old = client.get('/v7/ratings/1');
      final expected = expectLater(old, throwsA(isA<DioException>()));
      await started.future;
      version = 2;
      pending.complete(
        body(401, {
          'isSuccess': false,
          'code': 'AUTH401_3',
          'message': 'invalid',
        }),
      );
      await expected;
      expect(expired, 0);
      client.httpClientAdapter = Adapter(
        (_) => body(403, {
          'isSuccess': false,
          'code': 'RATING403_1',
          'message': 'forbidden',
        }),
      );
      await expectLater(
        client.get('/v7/ratings/1'),
        throwsA(isA<DioException>()),
      );
      expect(expired, 0);
      client.httpClientAdapter = Adapter(
        (_) => body(401, {
          'isSuccess': false,
          'code': 'AUTH401_4',
          'message': 'expired',
        }),
      );
      await expectLater(
        client.get('/v7/ratings/1'),
        throwsA(isA<DioException>()),
      );
      expect(expired, 1);
      client.close();
    },
  );
  test('v7 rating uses object result and DELETE 200 wrapper; no memberId in writes', () async {
    final public = createMovieLogClient(), protected = createMovieLogClient();
    final sent = <RequestOptions>[];
    final rating = {
      'ratingId': 12,
      'movieId': 550,
      'score': 4,
      'comment': null,
      'createdAt': '2026-11-17T00:00:00Z',
    };
    public.httpClientAdapter = Adapter((o) {
      sent.add(o);
      return body(200, [rating]);
    });
    protected.httpClientAdapter = Adapter((o) {
      sent.add(o);
      return body(
        o.method == 'POST' ? 201 : 200,
        wrapper(o.method == 'DELETE' ? null : rating),
      );
    });
    final service = RatingApiService(public, protected);
    expect((await service.fetchMyRatings(25)).single.movieId, 550);
    expect(
      (await service.createRating(
        const CreateRatingRequest(movieId: 550, score: 4),
      )).ratingId,
      12,
    );
    await service.updateRating(ratingId: 12, score: 3, comment: ' ');
    await service.deleteRating(12);
    expect(sent.map((o) => o.path), [
      '/v7/members/25/ratings',
      '/v7/ratings',
      '/v7/ratings/12',
      '/v7/ratings/12',
    ]);
    expect(sent[1].data, {'movieId': 550, 'score': 4});
    expect(sent[2].data, {'score': 3, 'comment': null});
    public.close();
    protected.close();
  });
  test('rating result enters current session, stale create cannot enter next session', () async {
    final auth = signedInAuth();
    final store = SessionRatings(auth);
    final service = RatingsFixtureService()..writeGate = Completer<void>();
    final vm = MovieDetailViewModel(service, auth, store, movie(550));
    final pending = vm.createRating(score: 4);
    await expectLater(vm.createRating(score: 5), throwsA(isA<ApiFailure>()));
    expect(service.creates, 1);
    await auth.logout();
    await auth.login('new@example.com', 'pw');
    service.writeGate!.complete();
    await expectLater(pending, throwsA(isA<ApiFailure>()));
    expect(store.items, isEmpty);
    vm.dispose();
    store.dispose();
    auth.dispose();
  });
  test(
    '403 rating keeps session and registered card while 401 clears both',
    () async {
      final auth = signedInAuth();
      final store = SessionRatings(auth);
      final service = RatingsFixtureService();
      final vm = MovieDetailViewModel(service, auth, store, movie(550));
      await vm.createRating(score: 4);
      expect(store.items.single.movieId, 550);
      service.writeFailure = const ApiFailure(
        '권한 없음',
        code: 'RATING403_1',
        status: 403,
      );
      await expectLater(vm.createRating(score: 4), throwsA(isA<ApiFailure>()));
      expect(auth.status, AuthStatus.signedIn);
      expect(store.items.length, 1);
      service.writeFailure = const ApiFailure(
        '만료',
        code: 'AUTH401_4',
        status: 401,
      );
      await expectLater(vm.createRating(score: 4), throwsA(isA<ApiFailure>()));
      expect(auth.status, AuthStatus.signedOut);
      expect(store.items, isEmpty);
      vm.dispose();
      store.dispose();
      auth.dispose();
    },
  );
  test(
    'redirect covers initializing retry login pending signed out and signed in',
    () {
      for (final s in [AuthStatus.initializing, AuthStatus.retryRequired]) {
        expect(authRedirect(s, '/my'), '/start');
        expect(authRedirect(s, '/start'), isNull);
      }
      for (final s in [AuthStatus.signedOut, AuthStatus.authenticating]) {
        expect(authRedirect(s, '/my/ratings'), '/login');
        expect(authRedirect(s, '/register'), isNull);
      }
      expect(authRedirect(AuthStatus.signedIn, '/login'), '/home');
      expect(authRedirect(AuthStatus.signedIn, '/my'), isNull);
    },
  );
  test('a write queued before account switch never reaches the server with the new token', () async {
    var version = 1;
    final storage = MemoryTokenStorage()..token = 'test-only';
    final client = createAuthMovieLogClient(
      storage,
      sessionVersion: () => version,
      onExpired: (_) async {},
    );
    var requests = 0;
    client.httpClientAdapter = Adapter((o) {
      requests++;
      return body(201, wrapper(null));
    });
    final service = RatingApiService(
      createMovieLogClient(),
      client,
      sessionVersion: () => version,
    );
    final pending = service.createRating(
      const CreateRatingRequest(movieId: 550, score: 4),
    );
    version = 2;
    await expectLater(pending, throwsA(isA<ApiFailure>()));
    expect(requests, 0);
    client.close();
  });
}
