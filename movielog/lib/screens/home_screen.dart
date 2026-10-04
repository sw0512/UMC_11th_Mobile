import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../data/mock_movies.dart';
import '../widgets/home/featured_movie_card.dart';
import '../widgets/home/home_greeting.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/popular_movies_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeHeader(),

                const SizedBox(height: 44),

                const HomeGreeting(),

                const SizedBox(height: 24),

                FeaturedMovieCard(movie: mockMovies.first),

                const SizedBox(height: 28),

                const PopularMoviesHeader(),

                const SizedBox(height: 16),

                const PopularMovieList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
