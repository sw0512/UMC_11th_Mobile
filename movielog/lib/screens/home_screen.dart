import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/movie_home_view_model.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/home_greeting.dart';
import '../widgets/home/popular_movies_header.dart';
import '../widgets/tmdb_movie_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.warmWhite,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HomeHeader(),
          const SizedBox(height: 44),
          const HomeGreeting(),
          const SizedBox(height: 24),
          const PopularMoviesHeader(),
          const SizedBox(height: 16),
          Consumer<MovieHomeViewModel>(
            builder: (context, vm, child) => switch (vm.status) {
              MovieHomeLoadStatus.idle || MovieHomeLoadStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              MovieHomeLoadStatus.empty => const Center(
                child: Text('인기 영화가 없어요.'),
              ),
              MovieHomeLoadStatus.error => Column(
                children: [
                  Text(vm.message),
                  TextButton(
                    onPressed: () =>
                        context.read<MovieHomeViewModel>().loadPopular(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
              MovieHomeLoadStatus.success => SizedBox(
                height: 270,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: vm.movies.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 12),
                  itemBuilder: (_, index) => SizedBox(
                    width: 140,
                    child: TmdbMovieCard(movie: vm.movies[index]),
                  ),
                ),
              ),
            },
          ),
        ],
      ),
    ),
  );
}
