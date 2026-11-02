import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/movie_list_view_model.dart';
import '../theme/app_colors.dart';
import '../widgets/tmdb_movie_card.dart';
import '../widgets/movie_list/genre_filter_sheet.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});
  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  MovieListViewModel? _vm;
  int _shownError = 0;
  bool _dialogOpen = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = context.read<MovieListViewModel>();
    if (_vm == vm) return;
    _vm?.removeListener(_onState);
    _vm = vm;
    _vm!.addListener(_onState);
    _onState();
  }

  void _onState() {
    final vm = _vm!;
    if (vm.status != MovieListLoadStatus.error ||
        vm.errorVersion <= _shownError ||
        _dialogOpen) {
      return;
    }
    _shownError = vm.errorVersion;
    _dialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final retry = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('영화 목록을 불러오지 못했어요'),
          content: Text(
            '${vm.message}${vm.showingPreviousResults ? '\n최근에 불러온 목록은 그대로 유지했어요.' : ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('재시도'),
            ),
          ],
        ),
      );
      _dialogOpen = false;
      if (!mounted) return;
      if (retry == true) {
        await vm.retry();
      } else {
        vm.dismissError();
      }
    });
  }

  Future<void> _openGenres(MovieListViewModel vm) async {
    final ids = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          GenreFilterSheet(genres: vm.genres, selectedIds: vm.selectedGenreIds),
    );
    if (ids != null && mounted) await vm.selectGenres(ids);
  }

  @override
  void dispose() {
    _vm?.removeListener(_onState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.warmWhite,
    appBar: AppBar(title: const Text('영화')),
    body: Consumer<MovieListViewModel>(
      builder: (context, vm, child) {
        final loading = vm.isLoading || vm.status == MovieListLoadStatus.idle;
        return RefreshIndicator(
          onRefresh: vm.refresh,
          notificationPredicate: (notification) =>
              !loading && notification.depth == 0,
          child: ListView(
            key: const PageStorageKey('movie-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                '어떤 영화를 찾고 있나요?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: loading || vm.genres.isEmpty
                          ? null
                          : () => _openGenres(vm),
                      icon: const Icon(Icons.tune),
                      label: Text(
                        vm.selectedGenreIds == null
                            ? '장르 선택'
                            : '장르 ${vm.selectedGenreIds!.length}개',
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('전체'),
                      selected: vm.selectedGenreIds == null,
                      onSelected: loading ? null : (_) => vm.selectGenres(null),
                    ),
                    for (final genre in vm.genres)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(genre.name),
                          selected:
                              vm.selectedGenreIds?.contains(genre.id) ?? false,
                          onSelected: loading
                              ? null
                              : (_) => vm.selectGenre(genre.id),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (loading && !vm.isRefreshing)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                if (vm.showingPreviousResults)
                  const Text('이전에 성공한 장르의 목록을 표시하고 있어요.'),
                if (vm.status == MovieListLoadStatus.error && vm.movies.isEmpty)
                  Column(
                    children: [
                      Text(vm.message),
                      TextButton(
                        onPressed: vm.retry,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  )
                else if (vm.movies.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('조건에 맞는 영화가 없어요.')),
                  )
                else ...[
                  Row(
                    children: [
                      Text('${vm.movies.length}개의 영화'),
                      const Spacer(),
                      if (vm.isRefreshing) const Text('새로고침 중…'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.57,
                        ),
                    itemCount: vm.movies.length,
                    itemBuilder: (_, index) => TmdbMovieCard(
                      movie: vm.movies[index],
                      genres: vm.genres,
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    ),
  );
}
