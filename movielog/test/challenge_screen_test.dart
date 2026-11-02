import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

import 'helpers/tmdb_fixture_service.dart';

void main() {
  testWidgets(
    'sheet edits are local until confirmation and cancel leaves selection unchanged',
    (tester) async {
      final service = TmdbFixtureService();
      final vm = MovieListViewModel(service);
      await vm.loadInitial();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: const MaterialApp(home: MovieListScreen()),
        ),
      );
      await tester.tap(find.text('장르 선택'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, '액션'));
      await tester.tap(find.widgetWithText(FilterChip, '코미디'));
      expect(service.requests.length, 1);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(service.requests.last.$1, 1);
      expect(service.requests.last.$2, [28, 35]);
      await tester.tap(find.text('장르 2개'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('초기화'));
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(vm.selectedGenreIds, [28, 35]);
      await tester.tap(find.text('장르 2개'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('초기화'));
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(service.requests.last, (1, null));
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
  testWidgets('refresh failure dialog retains last success; retry recovers', (
    tester,
  ) async {
    final service = TmdbFixtureService();
    final vm = MovieListViewModel(service);
    await vm.loadInitial();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: const MaterialApp(home: MovieListScreen()),
      ),
    );
    service.fail = true;
    await tester.fling(find.byType(ListView).first, const Offset(0, 450), 1000);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(vm.movies.length, 2);
    service.fail = false;
    service.pages = {
      1: [999],
    };
    await tester.tap(find.text('재시도'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('영화 999'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });
}
