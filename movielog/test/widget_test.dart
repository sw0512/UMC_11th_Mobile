// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/main.dart';

void main() {
  testWidgets('renders the sign-up screen and enables submission', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('회원가입'), findsOneWidget);
    expect(find.text('환영합니다!\n간단한 정보만 입력하고 시작해보세요.'), findsOneWidget);
    expect(find.text('필수 약관에 동의합니다'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '무비로그');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'movie@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '가입하기'),
    );
    expect(button.onPressed, isNotNull);

  });
}
