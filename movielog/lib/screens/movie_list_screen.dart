import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../widgets/home/movie_card.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  String selectedGenre = '전체';

  static const genres = ['전체', '드라마', '로맨스', 'SF', '스릴러'];

  List<Movie> get filteredMovies {
    if (selectedGenre == '전체') return mockMovies;
    return mockMovies
        .where((movie) => movie.genres.contains(selectedGenre))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final movies = filteredMovies;

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(title: const Text('영화')),
      body: ListView(
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
                    onSelected: (_) => setState(() => selectedGenre = genre),
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
          GridView.builder(
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
          ),
        ],
      ),
    );
  }
}
