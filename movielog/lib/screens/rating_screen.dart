import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common_app_bar.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double rating = 0;

  void saveRating() {
    debugPrint('저장한 평점: ${rating.toStringAsFixed(1)}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${rating.toStringAsFixed(1)}점을 저장했어요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '평점 남기기',
        centerTitle: true,
        onBack: () => Navigator.of(context).pop(),
        titleStyle: AppTextStyles.titleLarge.copyWith(color: AppColors.violet),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('이 영화는 어땠나요?', style: AppTextStyles.titleMedium),

                  const SizedBox(height: 8),

                  Text(
                    rating == 0
                        ? '별점을 선택해주세요.'
                        : '${rating.toStringAsFixed(1)} / 5.0',
                    style: AppTextStyles.bodyMedium,
                  ),

                  const SizedBox(height: 32),

                  Center(
                    child: RatingBar.builder(
                      initialRating: rating,
                      minRating: 1,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 40,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                      itemBuilder: (context, _) => const Icon(
                        Icons.star_rounded,
                        color: AppColors.violet,
                      ),
                      onRatingUpdate: (value) {
                        setState(() {
                          rating = value;
                        });
                      },
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: rating > 0 ? saveRating : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.violet,
                        disabledBackgroundColor: const Color(0xFFCCC2DC),
                        foregroundColor: AppColors.white,
                        disabledForegroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '평점 저장',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
