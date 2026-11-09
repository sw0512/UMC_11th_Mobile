import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../widgets/tmdb_poster_image.dart';
import '../theme/app_colors.dart';
import '../widgets/rating_dialog.dart';

import 'package:provider/provider.dart';

import '../view_models/movie_detail_view_model.dart';
import '../view_models/submit_status.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movie});

  final Movie movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool isFavorite = false;

  void toggleFavorite() {
    setState(() => isFavorite = !isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isFavorite ? '즐겨찾기에 추가했어요.' : '즐겨찾기에서 삭제했어요.')),
    );
  }

  Future<void> showRatingDialog() async {
    final vm = context.read<MovieDetailViewModel>();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        movieId: vm.movie.id,
        onSubmit: (score, comment) =>
            vm.createRating(score: score, comment: comment),
      ),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final vm = context.watch<MovieDetailViewModel>();
    final busy = vm.submitStatus == SubmitStatus.submitting;

    return PopScope(
      canPop: !busy,
      child: Scaffold(
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
                    onPressed: vm.memberId == null || busy
                        ? null
                        : showRatingDialog,
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('평점 남기기'),
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
                onPressed: () {
                  if (busy) return;
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/movies');
                  }
                },
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
                        child: movie.posterAssetPath.isEmpty
                            ? TmdbPosterImage(
                                posterPath: movie.posterPath,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Image.asset(
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
                      [
                        movie.genreLabel,
                        if (movie.year > 0) '${movie.year}',
                        if (movie.runningTime > 0) '${movie.runningTime}분',
                      ].where((v) => v.isNotEmpty).join(' · '),
                      style: const TextStyle(
                        color: AppColors.gray,
                        fontSize: 16,
                      ),
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
                    if (vm.memberId == null)
                      TextButton(
                        onPressed: () => context.go('/sign-up'),
                        child: const Text('학습용 회원가입 후 평점을 남길 수 있어요.'),
                      ),
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
      ),
    );
  }
}
