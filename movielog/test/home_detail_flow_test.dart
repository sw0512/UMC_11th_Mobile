import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/main.dart';
import 'package:movielog/screens/home_screen.dart';
import 'package:movielog/widgets/movie_rating_input.dart';

import 'helpers/auth_fixture.dart';
import 'helpers/week6_fixture_services.dart';
import 'helpers/tmdb_fixture_service.dart';
import 'helpers/preference_test_store.dart';

void main() {
  setUp(resetPreferenceStore);
  testWidgets(
    'signed in direct detail loads real DTO id and preserves dialog cancellation',
    (tester) async {
      final service = RatingsFixtureService();
      await tester.pumpWidget(
        MyApp(
          authViewModel: signedInAuth(),
          restoreOnStart: false,
          initialLocation: '/movies/550',
          movieService: TmdbFixtureService(),
          ratingService: service,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('영화 소개'), findsOneWidget);
      await tester.tap(find.text('평점 남기기'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MovieRatingInput>(find.byType(MovieRatingInput)).movieId,
        550,
      );
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(service.creates, 0);
    },
  );
  testWidgets('logout prevents navigating back to protected detail', (
    tester,
  ) async {
    final auth = signedInAuth();
    await tester.pumpWidget(
      MyApp(
        authViewModel: auth,
        restoreOnStart: false,
        initialLocation: '/home',
        movieService: TmdbFixtureService(),
      ),
    );
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
    await auth.logout();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-email')), findsOneWidget);
    router.go('/movies/550');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-email')), findsOneWidget);
    expect(find.text('영화 소개'), findsNothing);
  });
}
