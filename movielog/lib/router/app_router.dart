import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sign_up_screen.dart';
import '../main.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) =>
            const MainScreen(currentIndex: 0, child: HomeScreen()),
      ),
      GoRoute(
        path: '/movies',
        builder: (context, state) =>
            const MainScreen(currentIndex: 1, child: MovieListScreen()),
      ),
      GoRoute(
        path: '/my',
        builder: (context, state) =>
            const MainScreen(currentIndex: 2, child: ProfileScreen()),
      ),
    ],
  );
}
