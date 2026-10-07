import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/services/genre_preference.dart';
import 'package:movielog/widgets/movie_list/movie_grid.dart';
import 'package:movielog/widgets/movie_list/movie_list_empty.dart';
import 'package:movielog/widgets/movie_list/movie_list_error.dart';

import 'helpers/preference_test_store.dart';

Future<void> finishLoading(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

Future<void> showMode(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('학습용 상태 전환'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pump();
}

void main() {
  setUp(resetPreferenceStore);

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
    expect(find.byType(MovieGrid), findsOneWidget);
  });

  testWidgets('filters and saves genre without starting another load', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));
    await finishLoading(tester);
    expect(find.text('심연을 걷는 자'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'SF'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('공허의 메아리'), findsOneWidget);
    expect(find.text('심연을 걷는 자'), findsNothing);
    expect(await GenrePreference().read(), 'SF');
  });

  testWidgets('restores saved genre in a newly created screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));
    await finishLoading(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'SF'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));
    await finishLoading(tester);

    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'SF'),
    );
    expect(chip.selected, isTrue);
    expect(find.text('1개의 영화'), findsOneWidget);
    expect(find.text('공허의 메아리'), findsOneWidget);
  });

  testWidgets('ignores an unknown stored genre', (tester) async {
    resetPreferenceStore({'selected_genre': '없는 장르'});
    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));
    await finishLoading(tester);
    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '전체'),
    );
    expect(chip.selected, isTrue);
    expect(find.text('5개의 영화'), findsOneWidget);
  });

  testWidgets('shows empty guidance instead of a grid', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));
    await finishLoading(tester);
    await showMode(tester, '빈 목록');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await finishLoading(tester);
    expect(find.byType(MovieListEmpty), findsOneWidget);
    expect(find.text('조건에 맞는 영화가 없습니다.'), findsOneWidget);
    expect(find.byType(MovieGrid), findsNothing);
  });

  testWidgets('retries an error through loading to success', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));
    await finishLoading(tester);
    await showMode(tester, '오류 발생');
    await finishLoading(tester);
    expect(find.byType(MovieListError), findsOneWidget);
    expect(find.byType(MovieListEmpty), findsNothing);
    expect(find.text('영화를 불러오지 못했습니다.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '다시 시도'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await finishLoading(tester);
    expect(find.byType(MovieListError), findsNothing);
    expect(find.byType(MovieGrid), findsOneWidget);
    expect(find.text('5개의 영화'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parent rebuild does not restart loading', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));
    await finishLoading(tester);
    await tester.pumpWidget(
      MaterialApp(theme: ThemeData.dark(), home: const MovieListScreen()),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(MovieGrid), findsOneWidget);
  });

  testWidgets('disposing while loading does not update removed state', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MovieListScreen()));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
