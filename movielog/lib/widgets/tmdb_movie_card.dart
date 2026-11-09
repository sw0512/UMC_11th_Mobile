import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/models/tmdb_genre_dto.dart';
import 'tmdb_poster_image.dart';

class TmdbMovieCard extends StatelessWidget {
  const TmdbMovieCard({super.key, required this.movie, this.genres = const []});
  final TmdbMovieDto movie;
  final List<TmdbGenreDto> genres;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/movies/${movie.id}', extra: movie),
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
