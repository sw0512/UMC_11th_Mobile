import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/main.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/home_screen.dart';
import 'package:movielog/screens/login_screen.dart';
import 'package:movielog/screens/profile_screen.dart';
import 'package:movielog/screens/movie_detail_screen.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/session_ratings.dart';
import 'package:movielog/widgets/rating_dialog.dart';
import 'package:movielog/widgets/movie_rating_input.dart';
import 'package:provider/provider.dart';

Object? safe(Object? value) {
  if (value is Map) {
    return {
      for (final e in value.entries)
        if (!{
          'password',
          'accessToken',
          'authorization',
        }.contains(e.key.toString()))
          e.key.toString(): safe(e.value),
    };
  }
  if (value is List) return value.map(safe).toList();
  return value;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android real secure storage and own-account v7 flow', (
    tester,
  ) async {
    await dotenv.load(fileName: '.env');
    final events = <Map<String, dynamic>>[];
    final evidence = <String, dynamic>{'network': events};
    binding.reportData = {'evidence': evidence};
    final storage = SecureTokenStorage(const FlutterSecureStorage());
    // Use a dedicated test application ID so existing user app data is untouched.
    await storage.deleteAccessToken();
    expect(await storage.readAccessToken() == null, true);
    await storage.saveAccessToken('platform-storage-probe');
    final freshStorage = SecureTokenStorage(const FlutterSecureStorage());
    expect(await freshStorage.readAccessToken(), 'platform-storage-probe');
    await freshStorage.deleteAccessToken();
    expect(await storage.readAccessToken() == null, true);
    final public = createMovieLogClient();
    late AuthViewModel auth;
    final protected = createAuthMovieLogClient(
      storage,
      sessionVersion: () => auth.sessionVersion,
      onExpired: (v) => auth.expireSession(expectedVersion: v),
    );
    void audit(Dio dio) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            events.add({
              'event': 'request',
              'method': o.method,
              'path': o.uri.path,
              'body': safe(o.data),
              'bearerPresent': o.headers.containsKey('Authorization'),
            });
            h.next(o);
          },
          onResponse: (r, h) {
            events.add({
              'event': 'response',
              'method': r.requestOptions.method,
              'path': r.requestOptions.uri.path,
              'status': r.statusCode,
              'body': safe(r.data),
            });
            h.next(r);
          },
          onError: (e, h) {
            events.add({
              'event': 'error',
              'method': e.requestOptions.method,
              'path': e.requestOptions.uri.path,
              'status': e.response?.statusCode,
              'body': safe(e.response?.data),
            });
            h.next(e);
          },
        ),
      );
    }

    audit(public);
    audit(protected);
    final member = MemberApiService(
      protected,
      sessionVersion: () => auth.sessionVersion,
    );
    auth = AuthViewModel(AuthApiService(public), member, storage);
    final ratings = RatingApiService(
      public,
      protected,
      sessionVersion: () => auth.sessionVersion,
    );
    final movies = TmdbMovieService(createTmdbClient());
    final random = Random.secure();
    final suffix = DateTime.now().millisecondsSinceEpoch
        .toRadixString(36)
        .substring(3);
    final email = 'movie8.$suffix@example.com';
    final nickname = '무비8$suffix';
    final duplicate = '중복8$suffix';
    final password =
        'Native8!${List.generate(22, (_) => random.nextInt(10)).join()}aZ';
    final signup = SignUpService(public);
    final account = await signup.signUp(
      CreateMemberRequest(email: email, nickname: nickname, password: password),
    );
    await signup.signUp(
      CreateMemberRequest(
        email: 'movie8.other.$suffix@example.com',
        nickname: duplicate,
        password: password,
      ),
    );
    evidence['account'] = {
      'memberId': account.result!.memberId,
      'email': email,
      'nickname': nickname,
    };
    final selected = (await movies.fetchPopular()).results.first;
    await tester.pumpWidget(
      MyApp(
        tokenStorage: storage,
        authViewModel: auth,
        memberApiService: member,
        ratingService: ratings,
        movieService: movies,
      ),
    );
    Future<void> waitFor(bool Function() ready) async {
      final clock = Stopwatch()..start();
      while (!ready()) {
        if (clock.elapsed > const Duration(seconds: 35)) {
          fail('UI/API wait exceeded 35 seconds');
        }
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 400));
    }

    await waitFor(() => auth.status == AuthStatus.signedOut);
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 400));
      await binding.takeScreenshot(name);
    }

    Future<void> login(String pw) async {
      await tester.enterText(find.byKey(const Key('login-email')), email);
      await tester.enterText(find.byKey(const Key('login-password')), pw);
      final button = find.widgetWithText(ElevatedButton, '로그인');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
    }

    await login('wrong-password');
    await waitFor(
      () => auth.status == AuthStatus.signedOut && auth.message != null,
    );
    expect(auth.sessionExpired, false);
    await shot('01-login-failure');
    await login(password);
    await waitFor(
      () =>
          auth.status == AuthStatus.signedIn &&
          auth.memberStatus == MemberLoadStatus.success,
    );
    expect((await freshStorage.readAccessToken())?.isNotEmpty, true);
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    router.go('/my');
    await tester.pumpAndSettle();
    await shot('02-login-me-profile');
    router.push('/my/profile/edit');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('profile-nickname')),
      duplicate,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, '저장'));
    await tester.pump();
    await waitFor(
      () => find.textContaining('이미 사용 중인 닉네임').evaluate().isNotEmpty,
    );
    await shot('03-profile-409');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
    final nicknameField = tester.widget<TextField>(
      find.byKey(const Key('profile-nickname')),
    );
    nicknameField.controller!.text = '수정8$suffix';
    await tester.pump(const Duration(milliseconds: 300));
    expect(nicknameField.controller!.text, '수정8$suffix');
    await tester.tap(find.widgetWithText(ElevatedButton, '저장'));
    await tester.pump();
    await waitFor(
      () =>
          find.byType(ProfileScreen).evaluate().isNotEmpty &&
          auth.member!.nickname.startsWith('수정8'),
    );
    await shot('04-profile-updated');
    router.push('/movies/${selected.id}', extra: selected);
    await tester.pumpAndSettle();
    final store = tester
        .element(find.byType(MovieDetailScreen))
        .read<SessionRatings>();
    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.byType(MovieRatingInput)));
    await tester.enterText(
      find.byKey(const Key('rating-comment')),
      '8주차 JWT 등록',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, '확인'));
    await tester.pump();
    await waitFor(
      () =>
          store.items.length == 1 &&
          find.byType(RatingDialog).evaluate().isEmpty,
    );
    await shot('05-rating-created');
    final created = store.items.single;
    expect(created.movieId, selected.id);
    router.go('/my/ratings');
    await tester.pumpAndSettle();
    await shot('06-session-rating-list');
    await tester.tap(find.byTooltip('평점 수정'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('rating-comment')))
          .controller!
          .text,
      '8주차 JWT 등록',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
    tester
            .widget<TextField>(find.byKey(const Key('rating-comment')))
            .controller!
            .text =
        '8주차 JWT 수정';
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(ElevatedButton, '확인'));
    await tester.pump();
    await waitFor(
      () =>
          store.items.single.comment == '8주차 JWT 수정' &&
          find.byType(RatingDialog).evaluate().isEmpty,
    );
    await shot('07-rating-updated');
    await tester.tap(find.byTooltip('평점 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, '삭제'));
    await tester.pump();
    await waitFor(() => store.items.isEmpty);
    await shot('08-rating-deleted');
    // Actual invalid-token response, only for this newly created account/session.
    await storage.saveAccessToken('invalid-test-session');
    await auth.loadMember(force: true);
    await waitFor(
      () =>
          auth.status == AuthStatus.signedOut && !auth.storageCleanupInProgress,
    );
    expect(await storage.readAccessToken() == null, true);
    await shot('09-invalid-token-login');
    router.go('/my/ratings');
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    await shot('10-protected-route-blocked');
    await login(password);
    await waitFor(
      () =>
          auth.status == AuthStatus.signedIn &&
          auth.memberStatus == MemberLoadStatus.success,
    );
    // Leave a valid token in the dedicated probe app only, to verify a real process restart next.
    router.go('/my');
    await tester.pumpAndSettle();
    await shot('11-before-process-restart');
    expect(
      events
          .where(
            (e) =>
                e['event'] == 'request' &&
                e['path'].toString().contains('/members/') &&
                !e['path'].toString().endsWith('/me'),
          )
          .every((e) => e['bearerPresent'] == false),
      true,
    );
    binding.reportData ??= {};
    binding.reportData!['evidence'] = {
      'account': {
        'memberId': account.result!.memberId,
        'email': email,
        'nickname': nickname,
      },
      'movieId': selected.id,
      'ratingId': created.ratingId,
      'secureStorage': {
        'write': true,
        'freshInstanceRead': true,
        'delete': true,
        'invalidTokenCleanup': true,
      },
      'network': events,
      'note': 'Native Android screenshots. Invalid token is a real API error. A second own account was created only to exercise nickname 409. Password and tokens are never exported.',
    };
    public.close(force: true);
    protected.close(force: true);
  });
}
