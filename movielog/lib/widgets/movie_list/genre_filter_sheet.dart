import 'package:flutter/material.dart';

import '../../data/models/tmdb_genre_dto.dart';

class GenreFilterSheet extends StatefulWidget {
  const GenreFilterSheet({
    super.key,
    required this.genres,
    required this.selectedIds,
  });
  final List<TmdbGenreDto> genres;
  final List<int>? selectedIds;
  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  late final Set<int> _draft = {...?widget.selectedIds};
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '장르 선택',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () => setState(_draft.clear),
                child: const Text('초기화'),
              ),
            ],
          ),
          const Text('여러 장르를 고르면 하나라도 해당하는 영화를 찾아요.'),
          const SizedBox(height: 20),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final genre in widget.genres)
                    FilterChip(
                      label: Text(genre.name),
                      selected: _draft.contains(genre.id),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _draft.add(genre.id);
                        } else {
                          _draft.remove(genre.id);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context, _draft.toList()..sort()),
            child: const Text('확인'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    ),
  );
}
