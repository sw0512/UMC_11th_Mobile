import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_colors.dart';

class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.enabled = true,
    this.movieId,
  });
  final double rating;
  final ValueChanged<double> onChanged;
  final bool enabled;
  final int? movieId;
  @override
  Widget build(BuildContext context) => RatingBar.builder(
    initialRating: rating,
    minRating: 1,
    allowHalfRating: false,
    ignoreGestures: !enabled,
    itemCount: 5,
    itemSize: 36,
    itemBuilder: (_, index) =>
        const Icon(Icons.star_rounded, color: AppColors.violet),
    onRatingUpdate: onChanged,
  );
}
