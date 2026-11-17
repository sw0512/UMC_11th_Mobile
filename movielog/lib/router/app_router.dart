import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/member_api_service.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/session_ratings.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/sign_up_view_model.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/movie_detail_loader.dart';
import '../screens/profile_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/my_ratings_screen.dart';

String? authRedirect(AuthStatus status, String location) {
  final public = const {'/login', '/register', '/sign-up'}.contains(location);
  return switch (status) {
    AuthStatus.initializing ||
    AuthStatus.retryRequired => location == '/start' ? null : '/start',
    AuthStatus.signedOut ||
    AuthStatus.authenticating => public ? null : '/login',
    AuthStatus.signedIn => public || location == '/start' ? '/home' : null,
  };
}

class AppRouter {
  AppRouter._();
  static GoRouter createRouter(
    AuthViewModel auth, {
    String initialLocation = '/start',
  }) {
    final root = GlobalKey<NavigatorState>();
    return GoRouter(
      navigatorKey: root,
      initialLocation: initialLocation,
      refreshListenable: auth,
      redirect: (context, state) => authRedirect(auth.status, state.uri.path),
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) {
            final a = context.watch<AuthViewModel>();
            return SplashScreen(
              message: a.message,
              onRetry: a.status == AuthStatus.retryRequired
                  ? a.restoreSession
                  : null,
            );
          },
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(path: '/sign-up', redirect: (context, state) => '/register'),
        GoRoute(
          path: '/register',
          builder: (context, state) => ChangeNotifierProvider(
            create: (c) => SignUpViewModel(c.read<SignUpService>()),
            child: const SignUpScreen(),
          ),
        ),
        ShellRoute(
          builder: (context, state, child) => MainScreen(
            key: ValueKey(auth.sessionVersion),
            currentIndex: state.uri.path.startsWith('/movies')
                ? 1
                : state.uri.path.startsWith('/my')
                ? 2
                : 0,
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/home',
              builder: (c, s) => ChangeNotifierProvider(
                create: (c) =>
                    MovieHomeViewModel(c.read<TmdbMovieService>())
                      ..loadPopular(),
                child: const HomeScreen(),
              ),
            ),
            GoRoute(
              path: '/movies',
              builder: (c, s) => ChangeNotifierProvider(
                create: (c) =>
                    MovieListViewModel(c.read<TmdbMovieService>())
                      ..loadInitial(),
                child: const MovieListScreen(),
              ),
            ),
            GoRoute(
              path: '/my',
              builder: (c, s) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'ratings',
                  parentNavigatorKey: root,
                  builder: (c, s) => ChangeNotifierProvider(
                    key: ValueKey(auth.sessionVersion),
                    create: (c) => MyRatingsViewModel(
                      c.read<RatingApiService>(),
                      c.read<TmdbMovieService>(),
                      c.read<SessionRatings>(),
                    )..load(),
                    child: const MyRatingsScreen(),
                  ),
                ),
                GoRoute(
                  path: 'profile/edit',
                  parentNavigatorKey: root,
                  builder: (c, s) {
                    final a = c.watch<AuthViewModel>();
                    if (a.member == null) return const ProfileScreen();
                    return ChangeNotifierProvider(
                      key: ValueKey(a.sessionVersion),
                      create: (c) =>
                          EditProfileViewModel(c.read<MemberApiService>(), a),
                      child: const EditProfileScreen(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/movies/:movieId',
          builder: (c, s) {
            final id = int.tryParse(s.pathParameters['movieId'] ?? '');
            if (id == null || id < 1) {
              return const Scaffold(
                body: Center(child: Text('영화 ID가 올바르지 않습니다.')),
              );
            }
            return MovieDetailLoader(
              key: ValueKey('${auth.sessionVersion}:$id'),
              movieId: id,
              initialMovie:
                  s.extra is TmdbMovieDto && (s.extra as TmdbMovieDto).id == id
                  ? s.extra as TmdbMovieDto
                  : null,
            );
          },
        ),
      ],
    );
  }
}
