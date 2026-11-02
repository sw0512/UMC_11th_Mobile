import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';

import 'package:provider/provider.dart';

import '../data/services/tmdb_movie_service.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../models/movie.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sign_up_screen.dart';
import '../main.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) =>
              MovieHomeViewModel(context.read<TmdbMovieService>())
                ..loadPopular(),
          child: const MainScreen(currentIndex: 0, child: HomeScreen()),
        ),
      ),
      GoRoute(
        path: '/movies',
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) =>
              MovieListViewModel(context.read<TmdbMovieService>())
                ..loadInitial(),
          child: const MainScreen(currentIndex: 1, child: MovieListScreen()),
        ),
      ),
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) {
          final movieId = int.tryParse(state.pathParameters['movieId'] ?? '');
          final extra = state.extra;
          final movie = extra is Movie && extra.id == movieId
              ? extra
              : (movieId == null ? null : findMovieById(movieId));

          if (movie == null) return const _MovieNotFoundScreen();

          return MovieDetailScreen(movie: movie);
        },
      ),
      GoRoute(
        path: '/my',
        builder: (context, state) =>
            const MainScreen(currentIndex: 2, child: ProfileScreen()),
      ),
    ],
  );
}

class _MovieNotFoundScreen extends StatelessWidget {
  const _MovieNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('영화를 찾을 수 없어요.')));
  }
}
