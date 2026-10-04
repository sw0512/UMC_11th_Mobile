import 'package:flutter/material.dart';

import '../../data/mock_movies.dart';
import 'movie_card.dart';

class PopularMoviesHeader extends StatelessWidget {
  const PopularMoviesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      '지금 인기 있는 영화',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    );
  }
}

class PopularMovieList extends StatelessWidget {
  const PopularMovieList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 275,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: mockMovies.length - 1,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            MovieCard(movie: mockMovies[index + 1]),
      ),
    );
  }
}
