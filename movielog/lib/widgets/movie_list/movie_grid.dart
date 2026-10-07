import 'package:flutter/material.dart';

import '../../models/movie.dart';
import '../home/movie_card.dart';

class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: movies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 12,
        childAspectRatio: .53,
      ),
      itemBuilder: (context, index) =>
          MovieCard(movie: movies[index], expandToGridWidth: true),
    );
  }
}
