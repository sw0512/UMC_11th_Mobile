import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.violet,
          child: Icon(Icons.person, size: 48, color: AppColors.white),
        ),
        const SizedBox(height: 16),
        const Text('무비러버', style: AppTextStyles.titleLarge),
        const SizedBox(height: 8),
        Text(
          '매주 주말엔 영화관으로 출근하는 프로 관람객. 좋은 영화를 보고 기록하는 것을 좋아합니다.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray),
        ),
      ],
    );
  }
}
