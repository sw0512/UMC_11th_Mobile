import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/my_ratings_view_model.dart';
import '../widgets/movielog_button.dart';
import '../widgets/tmdb_poster_image.dart';
import '../theme/app_colors.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('내가 등록한 평점'),
      centerTitle: true,
      leading: IconButton(
        tooltip: '마이페이지로 돌아가기',
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/my');
          }
        },
      ),
    ),
    body: Consumer<MyRatingsViewModel>(
      builder: (context, vm, child) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text('학습용 회원 1번의 공개 평점입니다.'),
          ),
          Expanded(
            child: switch (vm.status) {
              MyRatingsLoadStatus.idle || MyRatingsLoadStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              MyRatingsLoadStatus.empty => const Center(
                child: Text('등록된 평점이 없어요.'),
              ),
              MyRatingsLoadStatus.error => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(vm.message ?? '평점을 불러오지 못했습니다.'),
                      const SizedBox(height: 16),
                      MovieLogButton(label: '다시 시도', onPressed: vm.load),
                    ],
                  ),
                ),
              ),
              MyRatingsLoadStatus.success => ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (vm.message != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(vm.message!),
                    ),
                  for (final entry in vm.ratings)
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.outline),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: TmdbPosterImage(
                                posterPath: entry.movie?.posterPath,
                                width: 70,
                                height: 105,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.movie?.title ??
                                        '영화 #${entry.rating.movieId}',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '별점 ${entry.rating.score} / 5',
                                    style: const TextStyle(
                                      color: AppColors.violet,
                                    ),
                                  ),
                                  if (entry.rating.comment != null &&
                                      entry.rating.comment!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(entry.rating.comment!),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    '등록일 ${entry.rating.createdAt.toLocal().toIso8601String().substring(0, 10)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.gray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            },
          ),
        ],
      ),
    ),
  );
}
