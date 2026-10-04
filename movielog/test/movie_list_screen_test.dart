import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/screens/movie_list_screen.dart';

void main() {
  testWidgets('filters mock movies by selected genre', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));

    expect(find.text('심연을 걷는 자'), findsOneWidget);
    expect(find.text('공허의 메아리'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'SF'));
    await tester.pumpAndSettle();

    expect(find.text('공허의 메아리'), findsOneWidget);
    expect(find.text('심연을 걷는 자'), findsNothing);
  });
}
