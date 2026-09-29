import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../widgets/movie_rating_input.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movie});

  final Movie movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool isFavorite = false;
  double? myRating;

  void toggleFavorite() {
    setState(() => isFavorite = !isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isFavorite ? '즐겨찾기에 추가했어요.' : '즐겨찾기에서 삭제했어요.')),
    );
  }

  void showRatingDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => MovieRatingInput(
        onSaved: (rating) {
          setState(() => myRating = rating);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${rating.toStringAsFixed(1)}점을 남겼어요.')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: toggleFavorite,
                  icon: Icon(
                    isFavorite ? Icons.bookmark : Icons.bookmark_outline,
                  ),
                  label: Text(isFavorite ? '즐겨찾기 됨' : '즐겨찾기'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: showRatingDialog,
                  icon: const Icon(Icons.rate_review_outlined),
                  label: Text(
                    myRating == null
                        ? '평점 남기기'
                        : '내 평점 ${myRating!.toStringAsFixed(1)}점',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.warmWhite,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              tooltip: '뒤로가기',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: const Text('Cinema Archive'),
            actions: [
              IconButton(
                tooltip: '공유',
                icon: const Icon(Icons.share_outlined),
                onPressed: () {},
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: Image.asset(
                        movie.posterAssetPath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    movie.title,
                    style: const TextStyle(
                      color: AppColors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${movie.genreLabel} · ${movie.year} · ${movie.runningTime}분',
                    style: const TextStyle(color: AppColors.gray, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: movie.averageRating,
                        itemBuilder: (_, _) => const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFB800),
                        ),
                        itemCount: 5,
                        itemSize: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${movie.averageRating.toStringAsFixed(1)} / 5.0',
                        style: const TextStyle(
                          color: AppColors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    '영화 소개',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    movie.synopsis,
                    style: const TextStyle(
                      color: AppColors.gray,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
