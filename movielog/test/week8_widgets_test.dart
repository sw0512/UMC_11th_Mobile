import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movielog/main.dart';
import 'package:movielog/data/models/api_failure.dart';
import 'package:movielog/screens/login_screen.dart';
import 'package:movielog/view_models/auth_view_model.dart';

import 'helpers/auth_fixture.dart';
import 'helpers/tmdb_fixture_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'login form remembers email only and displays credential error without expiry',
    (tester) async {
      final storage = MemoryTokenStorage();
      final api = AuthFixtureService()
        ..failure = const ApiFailure('wrong', code: 'AUTH401_1', status: 401);
      final auth = AuthViewModel(api, MemberFixtureService(), storage)
        ..status = AuthStatus.signedOut;
      await tester.pumpWidget(
        MyApp(
          authViewModel: auth,
          tokenStorage: storage,
          restoreOnStart: false,
          initialLocation: '/login',
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'demo@example.com',
      );
      await tester.enterText(find.byKey(const Key('login-password')), 'pw');
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      final login = find.widgetWithText(ElevatedButton, '로그인');
      await tester.ensureVisible(login);
      await tester.tap(login);
      await tester.pumpAndSettle();
      expect(find.text('이메일 또는 비밀번호를 확인해 주세요.'), findsOneWidget);
      expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'movielog.remembered_email'});
      expect(prefs.getString('movielog.remembered_email'), 'demo@example.com');
      expect(storage.writes, 0);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(login);
      await tester.pumpAndSettle();
      expect(prefs.getKeys(), isEmpty);
    },
  );
  testWidgets(
    'expired notice is consumed once; direct logout shows no expiry',
    (tester) async {
      final auth =
          AuthViewModel(
              AuthFixtureService(),
              MemberFixtureService(),
              MemoryTokenStorage(),
            )
            ..status = AuthStatus.signedOut
            ..sessionExpired = true;
      await tester.pumpWidget(
        MyApp(
          authViewModel: auth,
          restoreOnStart: false,
          initialLocation: '/login',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsOneWidget);
      expect(auth.sessionExpired, false);
      ScaffoldMessenger.of(tester.element(find.byType(LoginScreen)))
          .clearSnackBars();
      await tester.pumpAndSettle();
      await auth.logout();
      await tester.pumpAndSettle();
      expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsNothing);
    },
  );
  testWidgets(
    'profile shows server fields and unsaved nickname back confirmation',
    (tester) async {
      final auth = signedInAuth();
      final member = MemberFixtureService()
        ..failure = const ApiFailure(
          '이미 사용 중인 닉네임입니다.',
          code: 'MEMBER409_1',
          status: 409,
        );
      await tester.pumpWidget(
        MyApp(
          authViewModel: auth,
          memberApiService: member,
          movieService: TmdbFixtureService(),
          restoreOnStart: false,
          initialLocation: '/my',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2026.10.10 가입'), findsOneWidget);
      expect(find.text('demo@example.com'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, '프로필 수정'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('profile-nickname')),
        '바꾼 이름',
      );
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('변경 내용을 버릴까요?'), findsOneWidget);
      await tester.tap(find.text('계속 수정'));
      await tester.pumpAndSettle();
      expect(find.text('바꾼 이름'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, '저장'));
      await tester.pumpAndSettle();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
      expect(find.text('바꾼 이름'), findsOneWidget);
      expect(auth.status, AuthStatus.signedIn);
      member.failure = null;
      await tester.tap(find.widgetWithText(ElevatedButton, '저장'));
      await tester.pumpAndSettle();
      expect(find.text('바꾼 이름'), findsOneWidget);
      expect(auth.member!.nickname, '바꾼 이름');
    },
  );
}
