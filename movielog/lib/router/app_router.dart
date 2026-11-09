import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../screens/movie_detail_loader.dart';
import '../view_models/learning_member_session.dart';

import 'package:provider/provider.dart';

import '../data/services/tmdb_movie_service.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sign_up_screen.dart';
import '../main.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/rating_api_service.dart';
import '../view_models/sign_up_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../screens/my_ratings_screen.dart';

class AppRouter {
  AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => ChangeNotifierProvider(
          create: (context) => SignUpViewModel(context.read<SignUpService>()),
          child: const SignUpScreen(),
        ),
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
          final id = int.tryParse(state.pathParameters['movieId'] ?? '');
          if (id == null || id < 1) {
            return const Scaffold(
              body: Center(child: Text('영화 ID가 올바르지 않습니다.')),
            );
          }
          final extra = state.extra;
          return MovieDetailLoader(
            movieId: id,
            initialMovie: extra is TmdbMovieDto && extra.id == id
                ? extra
                : null,
          );
        },
      ),
      GoRoute(
        path: '/my',
        builder: (context, state) =>
            const MainScreen(currentIndex: 2, child: ProfileScreen()),
        routes: [
          GoRoute(
            path: 'ratings',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final id = context.read<LearningMemberSession>().memberId;
              if (id == null) {
                return Scaffold(
                  appBar: AppBar(
                    title: const Text('내가 등록한 평점'),
                    centerTitle: true,
                  ),
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('학습용 회원가입이 필요합니다.'),
                        TextButton(
                          onPressed: () => context.go('/sign-up'),
                          child: const Text('회원가입'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ChangeNotifierProvider(
                create: (context) => MyRatingsViewModel(
                  context.read<RatingApiService>(),
                  context.read<TmdbMovieService>(),
                  id,
                )..load(),
                child: const MyRatingsScreen(),
              );
            },
          ),
        ],
      ),
    ],
  );
}
