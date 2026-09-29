import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_colors.dart';

class MovieRatingInput extends StatefulWidget {
  const MovieRatingInput({super.key, required this.onSaved});

  final ValueChanged<double> onSaved;

  @override
  State<MovieRatingInput> createState() => _MovieRatingInputState();
}

class _MovieRatingInputState extends State<MovieRatingInput> {
  double rating = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('평점 남기기'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rating == 0
                ? '별점을 선택해주세요.'
                : '${rating.toStringAsFixed(1)}점을 선택했어요.',
            style: const TextStyle(color: AppColors.gray),
          ),
          const SizedBox(height: 20),
          RatingBar.builder(
            initialRating: rating,
            minRating: .5,
            allowHalfRating: true,
            itemCount: 5,
            itemSize: 34,
            itemBuilder: (_, _) =>
                const Icon(Icons.star_rounded, color: Color(0xFFFFB800)),
            onRatingUpdate: (value) => setState(() => rating = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: rating == 0
              ? null
              : () {
                  widget.onSaved(rating);
                  Navigator.of(context).pop();
                },
          child: const Text('저장'),
        ),
      ],
    );
  }
}
