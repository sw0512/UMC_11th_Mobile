import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../models/movie_list_initial_data.dart';
import '../services/fake_movie_service.dart';
import '../services/genre_preference.dart';
import '../theme/app_colors.dart';
import '../widgets/movie_list/movie_grid.dart';
import '../widgets/movie_list/movie_list_empty.dart';
import '../widgets/movie_list/movie_list_error.dart';
import '../widgets/movie_list/movie_list_loading.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const genres = ['전체', '드라마', '로맨스', 'SF', '스릴러'];

  final movieService = const FakeMovieService();
  late final GenrePreference _genrePreference;
  late Future<MovieListInitialData> _moviesFuture;
  Future<void> _saveQueue = Future<void>.value();
  String? _selectedGenre;

  @override
  void initState() {
    super.initState();
    _genrePreference = GenrePreference();
    _moviesFuture = _loadInitialData();
  }

  Future<MovieListInitialData> _loadInitialData({
    MovieLoadMode mode = MovieLoadMode.success,
  }) async {
    try {
      final results = await Future.wait<Object>([
        movieService.fetchMovies(mode: mode),
        _genrePreference.read(),
      ]);
      final savedGenre = results[1] as String;
      return MovieListInitialData(
        movies: results[0] as List<Movie>,
        selectedGenre: genres.contains(savedGenre) ? savedGenre : '전체',
      );
    } catch (error, stackTrace) {
      debugPrint('영화 목록 초기화 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } finally {
      debugPrint('영화 목록 로드 시도 종료');
    }
  }

  void _retry() {
    setState(() {
      _moviesFuture = _loadInitialData();
    });
  }

  // 개발 모드에서만 네 상태를 재현합니다. 재시도는 성공 모드로 요청합니다.
  void _previewMode(MovieLoadMode mode) {
    setState(() {
      _moviesFuture = _loadInitialData(mode: mode);
    });
  }

  void _selectGenre(String genre) {
    setState(() => _selectedGenre = genre);
    // 빠르게 여러 Chip을 눌러도 마지막 선택값이 마지막에 저장되도록 순서를 지킵니다.
    _saveQueue = _saveQueue.then((_) async {
      try {
        await _genrePreference.save(genre);
      } catch (error, stackTrace) {
        debugPrint('장르 저장 실패: $error');
        debugPrintStack(stackTrace: stackTrace);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('장르를 저장하지 못했어요. 다시 선택해 주세요.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        title: const Text('영화'),
        actions: [
          if (kDebugMode)
            PopupMenuButton<MovieLoadMode>(
              tooltip: '학습용 상태 전환',
              onSelected: _previewMode,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: MovieLoadMode.success,
                  child: Text('성공 목록'),
                ),
                PopupMenuItem(value: MovieLoadMode.empty, child: Text('빈 목록')),
                PopupMenuItem(
                  value: MovieLoadMode.failure,
                  child: Text('오류 발생'),
                ),
              ],
            ),
        ],
      ),
      body: FutureBuilder<MovieListInitialData>(
        future: _moviesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const MovieListLoading();
          }
          // 오류를 빈 목록으로 처리하지 않도록 데이터보다 먼저 확인합니다.
          if (snapshot.hasError) {
            return MovieListError(onRetry: _retry);
          }

          final data = snapshot.data;
          final selectedGenre = _selectedGenre ?? data?.selectedGenre ?? '전체';
          final allMovies = data?.movies ?? const <Movie>[];
          final movies = selectedGenre == '전체'
              ? allMovies
              : allMovies
                    .where((movie) => movie.genres.contains(selectedGenre))
                    .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const Text(
                '어떤 영화를 찾고 있나요?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final genre in genres) ...[
                      ChoiceChip(
                        label: Text(genre),
                        selected: selectedGenre == genre,
                        onSelected: (_) => _selectGenre(genre),
                        selectedColor: AppColors.chipBackground,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${movies.length}개의 영화',
                style: const TextStyle(color: AppColors.gray, fontSize: 14),
              ),
              const SizedBox(height: 12),
              if (movies.isEmpty)
                const MovieListEmpty()
              else
                MovieGrid(movies: movies),
            ],
          );
        },
      ),
    );
  }
}
