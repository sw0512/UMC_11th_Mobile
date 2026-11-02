import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/models/tmdb_genre_dto.dart';
import '../models/movie.dart';
import 'tmdb_poster_image.dart';

class TmdbMovieCard extends StatelessWidget {
  const TmdbMovieCard({super.key, required this.movie, this.genres = const []});
  final TmdbMovieDto movie;
  final List<TmdbGenreDto> genres;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push(
      '/movies/${movie.id}',
      extra: Movie(
        id: movie.id,
        title: movie.title,
        genres: genres
            .where((g) => movie.genreIds.contains(g.id))
            .map((g) => g.name)
            .toList(),
        year: int.tryParse((movie.releaseDate ?? '').split('-').first) ?? 0,
        runningTime: 0,
        posterAssetPath: '',
        posterPath: movie.posterPath,
        synopsis: movie.overview.isEmpty ? '줄거리 정보가 없어요.' : movie.overview,
        averageRating: movie.voteAverage / 2,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: TmdbPosterImage(
              posterPath: movie.posterPath,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          movie.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
