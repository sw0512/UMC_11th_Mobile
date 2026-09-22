import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/screens/rating_screen.dart';

void main() {
  testWidgets('enables rating save after a star is selected', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RatingScreen()));

    final saveButton = find.widgetWithText(ElevatedButton, '평점 저장');
    expect(tester.widget<ElevatedButton>(saveButton).onPressed, isNull);

    await tester.tapAt(tester.getCenter(find.byType(RatingBar)));
    await tester.pump();

    expect(tester.widget<ElevatedButton>(saveButton).onPressed, isNotNull);
  });
}
