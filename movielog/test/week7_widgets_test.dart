import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/models/api_failure.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/main.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/widgets/rating_dialog.dart';
import 'package:movielog/widgets/delete_rating_dialog.dart';

import 'helpers/week6_fixture_services.dart';
import 'helpers/tmdb_fixture_service.dart';

void main() {
  testWidgets(
    'rating dialog preserves comment and integer score after failure, blocks back and outside taps while saving',
    (tester) async {
      final pending = Completer<void>();
      int calls = 0;
      int? selected;
      String? comment;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => RatingDialog(
                    onSubmit: (score, text) {
                      calls++;
                      selected = score;
                      comment = text;
                      return pending.future;
                    },
                  ),
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MovieLogButton>(find.widgetWithText(MovieLogButton, '확인'))
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byKey(const Key('rating-comment')), '입력한 후기');
      await tester.pump();
      expect(
        tester
            .widget<MovieLogButton>(find.widgetWithText(MovieLogButton, '확인'))
            .onPressed,
        isNull,
      );
      await tester.tapAt(tester.getCenter(find.byType(RatingBar)));
      await tester.pump();
      expect(find.text('입력한 후기'), findsOneWidget);
      await tester.tap(find.text('확인'));
      await tester.pump();
      expect(calls, 1);
      expect(selected, inInclusiveRange(1, 5));
      expect(comment, '입력한 후기');
      await tester.binding.handlePopRoute();
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      expect(find.byType(RatingDialog), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('rating-comment')))
            .enabled,
        false,
      );
      expect(
        tester
            .widget<MovieLogButton>(find.widgetWithText(MovieLogButton, '취소'))
            .onPressed,
        isNull,
      );
      pending.completeError(
        const ApiFailure(
          '이미 이 영화에 평점을 남기셨습니다.',
          code: 'COMMON409',
          status: 409,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('입력한 후기'), findsOneWidget);
      expect(find.text('이미 이 영화에 평점을 남기셨습니다.'), findsOneWidget);
      expect(
        tester
            .widget<MovieLogButton>(find.widgetWithText(MovieLogButton, '확인'))
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(calls, 1);
    },
  );
  testWidgets(
    'edit dialog preloads score and nullable comment and cancellation makes no request',
    (tester) async {
      int calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => RatingDialog(
                    initialScore: 4,
                    initialComment: null,
                    onSubmit: (score, comment) async {
                      calls++;
                    },
                  ),
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      expect(find.text('4점을 선택했어요.'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('rating-comment')))
            .controller!
            .text,
        isEmpty,
      );
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(calls, 0);
    },
  );
  testWidgets(
    'single delete confirmation stays open while deleting; cancel sends no DELETE',
    (tester) async {
      final service = RatingsFixtureService()..writeGate = Completer<void>();
      final vm = MyRatingsViewModel(service, DetailFixtureService(), 77);
      await vm.load();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: const MaterialApp(home: MyRatingsScreen()),
        ),
      );
      await tester.tap(find.byTooltip('평점 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(service.deletes, isEmpty);
      await tester.tap(find.byTooltip('평점 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pump();
      expect(find.byType(DeleteRatingDialog), findsOneWidget);
      expect(vm.isWriting, true);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(DeleteRatingDialog), findsOneWidget);
      service.writeGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(DeleteRatingDialog), findsNothing);
      expect(find.text('등록된 평점이 없어요.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
  testWidgets(
    'bulk delete closes confirmation immediately and uses overlay until all requests finish',
    (tester) async {
      final service = RatingsFixtureService()
        ..items = [sampleRating(1, 550), sampleRating(2, 680)]
        ..writeGate = Completer<void>();
      final vm = MyRatingsViewModel(service, DetailFixtureService(), 77);
      await vm.load();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: const MaterialApp(home: MyRatingsScreen()),
        ),
      );
      await tester.tap(find.text('편집'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('select-1')));
      await tester.tap(find.byKey(const ValueKey('select-2')));
      await tester.pump();
      await tester.tap(find.text('선택한 2개 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.descendant(
          of: find.byType(MyRatingsScreen),
          matching: find.byType(ModalBarrier),
        ),
        findsOneWidget,
      );
      expect(find.text('평점을 처리하고 있어요.'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(vm.isWriting, true);
      expect(service.deletes, [1]);
      service.writeGate!.complete();
      await tester.pumpAndSettle();
      expect(service.deletes, [1, 2]);
      expect(find.text('등록된 평점이 없어요.'), findsOneWidget);
      expect(vm.editing, false);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
  testWidgets(
    'signup pending blocks back and publishes new member session before movies',
    (tester) async {
      final service = CheckFixtureService()
        ..signupPending = Completer<CommonResponse<SignUpResult>>();
      final session = LearningMemberSession();
      AppRouter.router.go('/sign-up');
      await tester.pumpWidget(
        MyApp(
          signUpService: service,
          learningSession: session,
          movieService: TmdbFixtureService(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '무비');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'demo@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'MockPass123!');
      await tester.pump();
      await tester.tap(find.text('중복 확인').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('중복 확인').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.ensureVisible(find.text('가입하기'));
      await tester.tap(find.text('가입하기'));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('회원가입'), findsOneWidget);
      expect(service.signups, 1);
      expect(session.memberId, isNull);
      service.signupPending!.complete(
        const CommonResponse(
          isSuccess: true,
          code: 'COMMON201',
          message: 'ok',
          result: SignUpResult(
            memberId: 77,
            email: 'demo@example.com',
            nickname: '무비',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(session.memberId, 77);
      expect(find.text('어떤 영화를 찾고 있나요?'), findsOneWidget);
    },
  );
  testWidgets('signup final error replaces an older snackbar immediately', (
    tester,
  ) async {
    final service = CheckFixtureService()
      ..signupPending = Completer<CommonResponse<SignUpResult>>();
    final session = LearningMemberSession();
    AppRouter.router.go('/sign-up');
    await tester.pumpWidget(
      MyApp(
        signUpService: service,
        learningSession: session,
        movieService: TmdbFixtureService(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '무비');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'demo@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'MockPass123!');
    await tester.pump();
    await tester.tap(find.text('중복 확인').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('중복 확인').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.ensureVisible(find.text('가입하기'));
    await tester.tap(find.text('가입하기'));
    await tester.pump();
    ScaffoldMessenger.of(tester.element(find.byType(Checkbox))).showSnackBar(
      const SnackBar(content: Text('이전 삭제 알림'), duration: Duration(minutes: 1)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('이전 삭제 알림'), findsOneWidget);
    service.signupPending!.completeError(
      const ApiFailure('이미 사용 중인 이메일입니다.', code: 'COMMON409', status: 409),
    );
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 이메일입니다.'), findsOneWidget);
    expect(find.text('이전 삭제 알림'), findsNothing);
    expect(session.memberId, isNull);
  });
  testWidgets(
    'missing session never loads member 1 and detail deep link remains read-only',
    (tester) async {
      final service = RatingsFixtureService();
      AppRouter.router.go('/my/ratings');
      await tester.pumpWidget(
        MyApp(ratingService: service, movieService: TmdbFixtureService()),
      );
      await tester.pumpAndSettle();
      expect(find.text('학습용 회원가입이 필요합니다.'), findsOneWidget);
      expect(service.members, isEmpty);
      AppRouter.router.go('/movies/550');
      await tester.pumpAndSettle();
      expect(find.text('영화 소개'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '평점 남기기'))
            .onPressed,
        isNull,
      );
      expect(service.creates, 0);
    },
  );
}
