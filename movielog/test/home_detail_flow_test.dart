import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';

void main() {
  testWidgets('opens a movie detail screen from the home card', (tester) async {
    await tester.pumpWidget(const MyApp());

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
}
