import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

import 'helpers/tmdb_fixture_service.dart';

void main() {
  testWidgets('loads API genres and requests a new genre from page one', (
    tester,
  ) async {
    final service = TmdbFixtureService();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MovieListViewModel(service)..loadInitial(),
        child: const MaterialApp(home: MovieListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2개의 영화'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '액션'));
    await tester.pumpAndSettle();
    expect(service.requests.last.$1, 1);
    expect(service.requests.last.$2, [28]);
    await tester.tap(find.widgetWithText(ChoiceChip, '전체'));
    await tester.pumpAndSettle();
    expect(service.requests.last, (1, null));
    expect(tester.takeException(), isNull);
  });
  testWidgets('error retries and renders missing posters', (tester) async {
    final service = TmdbFixtureService()..fail = true;
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MovieListViewModel(service)..loadInitial(),
        child: const MaterialApp(home: MovieListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('다시 시도'), findsOneWidget);
    service.fail = false;
    await tester.tap(find.text('재시도'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.image_not_supported_outlined), findsNWidgets(2));
  });
}
