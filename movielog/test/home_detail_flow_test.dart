import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';
import 'package:movielog/router/app_router.dart';

void main() {
  testWidgets('opens a movie detail screen from the home card', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('시작하기'), findsOneWidget);
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();
    expect(AppRouter.router.canPop(), isFalse);

    await tester.enterText(find.byType(TextFormField).at(0), '무비러버');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'movie@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    final submit = find.widgetWithText(ElevatedButton, '가입하기');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(AppRouter.router.canPop(), isFalse);

    expect(find.text('별빛 아래 우리'), findsOneWidget);

    final detailButton = find.widgetWithText(ElevatedButton, '상세보기');
    await tester.ensureVisible(detailButton);
    await tester.tap(detailButton);
    await tester.pumpAndSettle();

    expect(find.text('영화 소개'), findsOneWidget);
    expect(find.byTooltip('뒤로가기'), findsOneWidget);

    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();

    expect(find.text('오늘은 어떤\n영화를 볼까요?'), findsOneWidget);
  });

  testWidgets('direct detail navigation falls back to the movie list', (
    tester,
  ) async {
    AppRouter.router.go('/movies/1');
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(AppRouter.router.canPop(), isFalse);
    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('어떤 영화를 찾고 있나요?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
