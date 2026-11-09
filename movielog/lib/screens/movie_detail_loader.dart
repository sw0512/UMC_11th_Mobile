import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../data/services/rating_api_service.dart';
import '../models/movie.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/movie_detail_view_model.dart';
import 'movie_detail_screen.dart';

class MovieDetailLoader extends StatefulWidget {
  const MovieDetailLoader({
    super.key,
    required this.movieId,
    this.initialMovie,
  });
  final int movieId;
  final TmdbMovieDto? initialMovie;
  @override
  State<MovieDetailLoader> createState() => _MovieDetailLoaderState();
}

class _MovieDetailLoaderState extends State<MovieDetailLoader> {
  late Future<TmdbMovieDto> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.initialMovie != null
        ? Future.value(widget.initialMovie!)
        : context.read<TmdbMovieService>().fetchMovieDetail(widget.movieId);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<TmdbMovieDto>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError || snapshot.data == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('영화 상세')),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('영화를 불러오지 못했습니다.'),
                TextButton(
                  onPressed: () => setState(
                    () => _future = context
                        .read<TmdbMovieService>()
                        .fetchMovieDetail(widget.movieId),
                  ),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        );
      }
      final dto = snapshot.data!;
      return ChangeNotifierProvider(
        create: (_) => MovieDetailViewModel(
          context.read<RatingApiService>(),
          context.read<LearningMemberSession>().memberId,
          dto,
        ),
        child: MovieDetailScreen(
          movie: Movie(
            id: dto.id,
            title: dto.title,
            genres: const [],
            year: int.tryParse((dto.releaseDate ?? '').split('-').first) ?? 0,
            runningTime: 0,
            posterAssetPath: '',
            posterPath: dto.posterPath,
            synopsis: dto.overview.isEmpty ? '줄거리 정보가 없어요.' : dto.overview,
            averageRating: dto.voteAverage / 2,
          ),
        ),
      );
    },
  );
}
