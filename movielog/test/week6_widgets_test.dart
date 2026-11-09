import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/main.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/sign_up_screen.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';

import 'helpers/week6_fixture_services.dart';

import 'package:movielog/view_models/learning_member_session.dart';

void main() {
  testWidgets(
    'server duplicate remains Form error and cached duplicate disables the button',
    (tester) async {
      final service = CheckFixtureService()..available = false;
      final vm = SignUpViewModel(service);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: const MaterialApp(home: SignUpScreen()),
        ),
      );
      await tester.enterText(find.byType(TextFormField).first, '영화광');
      await tester.pump();
      await tester.tap(find.text('중복 확인').first);
      await tester.pumpAndSettle();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, '중복 확인').first,
            )
            .onPressed,
        isNull,
      );
      expect(
        Form.of(tester.element(find.byType(TextFormField).first)).validate(),
        false,
      );
      await tester.pump();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '새닉네임');
      await tester.pump();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsNothing);
      await tester.enterText(find.byType(TextFormField).first, '영화광');
      await tester.pump();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
      expect(service.nicknameCalls, 1);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
  testWidgets(
    'button widths differ and loading replaces label while blocking taps',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              child: Column(
                children: [
                  Row(
                    children: [
                      MovieLogButton(
                        key: const Key('intrinsic'),
                        label: '확인',
                        onPressed: () => taps++,
                      ),
                    ],
                  ),
                  MovieLogButton(
                    key: const Key('full'),
                    label: '전체 너비',
                    width: double.infinity,
                    onPressed: () => taps++,
                  ),
                  MovieLogButton(
                    key: const Key('fixed'),
                    label: '고정',
                    width: 150,
                    onPressed: () => taps++,
                  ),
                  MovieLogButton(
                    label: '통신 중',
                    isLoading: true,
                    onPressed: () => taps++,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('full'))).width, 350);
      expect(tester.getSize(find.byKey(const Key('fixed'))).width, 150);
      expect(
        tester.getSize(find.byKey(const Key('intrinsic'))).width,
        lessThan(150),
      );
      expect(find.text('통신 중'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(CircularProgressIndicator));
      expect(taps, 0);
    },
  );
  testWidgets(
    'ratings opens above profile without bottom tabs and back restores profile',
    (tester) async {
      AppRouter.router.go('/my');
      await tester.pumpWidget(
        MyApp(
          movieService: DetailFixtureService(),
          learningSession: LearningMemberSession()..setMemberId(77),
          ratingService: RatingsFixtureService(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('내가 등록한 평점'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('내가 등록한 평점'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('가입한 학습용 회원의 평점입니다.'), findsOneWidget);
      expect(find.text('영화 550'), findsOneWidget);
      expect(find.text('별점 4 / 5'), findsOneWidget);
      await tester.tap(find.byTooltip('마이페이지로 돌아가기'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('내 프로필'), findsOneWidget);
    },
  );
}
