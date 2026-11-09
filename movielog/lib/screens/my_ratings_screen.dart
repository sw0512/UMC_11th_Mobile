import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_dto.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/movielog_button.dart';
import '../widgets/tmdb_poster_image.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/delete_rating_dialog.dart';
import '../theme/app_colors.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});
  Future<void> _edit(BuildContext context, RatingDto rating) async {
    final vm = context.read<MyRatingsViewModel>();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        movieId: rating.movieId,
        initialScore: rating.score,
        initialComment: rating.comment,
        onSubmit: (score, comment) => vm.updateRating(
          ratingId: rating.ratingId,
          score: score,
          comment: comment,
        ),
      ),
    );
    if (context.mounted && saved == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('평점을 수정했습니다.')));
    }
  }

  Future<void> _delete(BuildContext context, RatingDto rating) async {
    final vm = context.read<MyRatingsViewModel>();
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          DeleteRatingDialog(onConfirm: () => vm.deleteRating(rating.ratingId)),
    );
    if (context.mounted && deleted == true) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('평점을 삭제했습니다.')));
    }
  }

  Future<void> _deleteSelected(
    BuildContext context,
    MyRatingsViewModel vm,
  ) async {
    final count = vm.selectedRatingIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('선택한 $count개의 평점을 삭제할까요?'),
        content: const Text('삭제한 평점은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    final message = await vm.deleteSelected();
    if (context.mounted && message.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyRatingsViewModel>();
    final loading =
        vm.status == MyRatingsLoadStatus.loading ||
        vm.status == MyRatingsLoadStatus.idle;
    return PopScope(
      canPop: !vm.isWriting,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('내가 등록한 평점'),
          centerTitle: true,
          leading: IconButton(
            tooltip: '마이페이지로 돌아가기',
            icon: const Icon(Icons.arrow_back),
            onPressed: vm.isWriting
                ? null
                : () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/my');
                    }
                  },
          ),
        ),
        bottomNavigationBar: vm.editing
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: MovieLogButton(
                    label: '선택한 ${vm.selectedRatingIds.length}개 삭제',
                    width: double.infinity,
                    onPressed:
                        vm.isWriting || loading || vm.selectedRatingIds.isEmpty
                        ? null
                        : () => _deleteSelected(context, vm),
                  ),
                ),
              )
            : null,
        body: Stack(
          children: [
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text('가입한 학습용 회원의 평점입니다.'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (vm.editing)
                        Text('${vm.selectedRatingIds.length}개 선택됨'),
                      const Spacer(),
                      TextButton(
                        onPressed: vm.isWriting || loading || vm.ratings.isEmpty
                            ? null
                            : vm.toggleEditing,
                        child: Text(vm.editing ? '취소' : '편집'),
                      ),
                    ],
                  ),
                ),
                if (vm.refreshWarning != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(vm.refreshWarning!),
                        TextButton(
                          onPressed: vm.isWriting ? null : vm.load,
                          child: const Text('목록 다시 조회'),
                        ),
                      ],
                    ),
                  ),
                if (loading && vm.ratings.isNotEmpty && !vm.isWriting)
                  const LinearProgressIndicator(),
                Expanded(
                  child: (loading && vm.ratings.isEmpty)
                      ? const Center(child: CircularProgressIndicator())
                      : vm.status == MyRatingsLoadStatus.error &&
                            vm.refreshWarning == null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(vm.message ?? '평점을 불러오지 못했습니다.'),
                                const SizedBox(height: 16),
                                MovieLogButton(
                                  label: '다시 시도',
                                  onPressed: vm.isWriting ? null : vm.load,
                                ),
                              ],
                            ),
                          ),
                        )
                      : vm.ratings.isEmpty
                      ? const Center(child: Text('등록된 평점이 없어요.'))
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            if (vm.message != null &&
                                vm.status == MyRatingsLoadStatus.success)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(vm.message!),
                              ),
                            for (final entry in vm.ratings)
                              Card(
                                key: ValueKey(
                                  'rating-${entry.rating.ratingId}',
                                ),
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(
                                    color: AppColors.outline,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: TmdbPosterImage(
                                          posterPath: entry.movie?.posterPath,
                                          width: 60,
                                          height: 90,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                entry
                                                    .rating
                                                    .comment!
                                                    .isNotEmpty) ...[
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
                                      if (vm.editing)
                                        Checkbox(
                                          key: ValueKey(
                                            'select-${entry.rating.ratingId}',
                                          ),
                                          value: vm.selectedRatingIds.contains(
                                            entry.rating.ratingId,
                                          ),
                                          onChanged: vm.isWriting || loading
                                              ? null
                                              : (_) => vm.toggleSelected(
                                                  entry.rating.ratingId,
                                                ),
                                        )
                                      else
                                        Column(
                                          children: [
                                            IconButton(
                                              tooltip: '평점 수정',
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                              ),
                                              onPressed: vm.isWriting || loading
                                                  ? null
                                                  : () => _edit(
                                                      context,
                                                      entry.rating,
                                                    ),
                                            ),
                                            IconButton(
                                              tooltip: '평점 삭제',
                                              icon: const Icon(
                                                Icons.delete_outline,
                                              ),
                                              onPressed: vm.isWriting || loading
                                                  ? null
                                                  : () => _delete(
                                                      context,
                                                      entry.rating,
                                                    ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
            if (vm.isWriting)
              const Positioned.fill(
                child: Stack(
                  children: [
                    ModalBarrier(dismissible: false, color: Colors.black38),
                    Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('평점을 처리하고 있어요.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
