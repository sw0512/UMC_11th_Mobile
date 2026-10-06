import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/screens/movie_list_screen.dart';

void main() {
  testWidgets('shows loading for one second before displaying movies', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('5개의 영화'), findsNothing);

    await tester.pump(const Duration(milliseconds: 999));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('5개의 영화'), findsOneWidget);
  });

  testWidgets('filters mock movies by selected genre', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('심연을 걷는 자'), findsOneWidget);
    expect(find.text('공허의 메아리'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'SF'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpAndSettle();

    expect(find.text('공허의 메아리'), findsOneWidget);
    expect(find.text('심연을 걷는 자'), findsNothing);
  });
}
