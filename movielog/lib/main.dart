import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/network/movie_log_client.dart';
import 'core/network/tmdb_client.dart';
import 'core/storage/token_storage.dart';
import 'data/services/sign_up_service.dart';
import 'data/services/rating_api_service.dart';
import 'data/services/tmdb_movie_service.dart';
import 'data/services/auth_api_service.dart';
import 'data/services/member_api_service.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/session_ratings.dart';
import 'services/email_preference.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.movieService,
    this.signUpService,
    this.ratingService,
    this.authViewModel,
    this.memberApiService,
    this.tokenStorage,
    this.emailPreference,
    this.initialLocation = '/start',
    this.restoreOnStart = true,
  });
  final TmdbMovieService? movieService;
  final SignUpService? signUpService;
  final RatingApiService? ratingService;
  final AuthViewModel? authViewModel;
  final MemberApiService? memberApiService;
  final TokenStorage? tokenStorage;
  final EmailPreference? emailPreference;
  final String initialLocation;
  final bool restoreOnStart;
  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider<TokenStorage>(
        create: (_) =>
            tokenStorage ?? SecureTokenStorage(const FlutterSecureStorage()),
      ),
      Provider<EmailPreference>(
        create: (_) => emailPreference ?? EmailPreference(),
      ),
      Provider<_Services>(
        create: (c) => _Services(c.read<TokenStorage>(), authViewModel),
        dispose: (_, s) => s.close(),
      ),
      Provider<SignUpService>(
        create: (c) =>
            signUpService ?? SignUpService(c.read<_Services>().publicClient),
      ),
      Provider<MemberApiService>(
        create: (c) => memberApiService ?? c.read<_Services>().member,
      ),
      Provider<RatingApiService>(
        create: (c) =>
            ratingService ??
            RatingApiService(
              c.read<_Services>().publicClient,
              c.read<_Services>().authClient,
              sessionVersion: () => c.read<AuthViewModel>().sessionVersion,
            ),
      ),
      Provider<TmdbMovieService>(
        create: (_) => movieService ?? TmdbMovieService(createTmdbClient()),
      ),
      ChangeNotifierProvider<AuthViewModel>(
        create: (c) => c.read<_Services>().auth,
      ),
      ChangeNotifierProvider<SessionRatings>(
        create: (c) => SessionRatings(c.read<AuthViewModel>()),
      ),
    ],
    child: _RouterApp(
      initialLocation: initialLocation,
      restoreOnStart: restoreOnStart,
    ),
  );
}

class _Services {
  _Services(TokenStorage storage, AuthViewModel? injected) {
    authClient = createAuthMovieLogClient(
      storage,
      sessionVersion: () => auth.sessionVersion,
      onExpired: (v) => auth.expireSession(expectedVersion: v),
    );
    member = MemberApiService(
      authClient,
      sessionVersion: () => auth.sessionVersion,
    );
    auth =
        injected ??
        AuthViewModel(AuthApiService(publicClient), member, storage);
  }
  final publicClient = createMovieLogClient();
  late final Dio authClient;
  late final MemberApiService member;
  late final AuthViewModel auth;
  void close() {
    publicClient.close(force: true);
    authClient.close(force: true);
  }
}

class _RouterApp extends StatefulWidget {
  const _RouterApp({
    required this.initialLocation,
    required this.restoreOnStart,
  });
  final String initialLocation;
  final bool restoreOnStart;
  @override
  State<_RouterApp> createState() => _RouterAppState();
}

class _RouterAppState extends State<_RouterApp> {
  late final GoRouter _router;
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthViewModel>();
    _router = AppRouter.createRouter(
      auth,
      initialLocation: widget.initialLocation,
    );
    if (widget.restoreOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) auth.restoreSession();
      });
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    title: 'MovieLog',
    routerConfig: _router,
    theme: AppTheme.light,
  );
  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }
}
