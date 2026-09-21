import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class LoginGuide extends StatelessWidget {
  const LoginGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '이미 계정이 있나요?',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray),
        ),

        const SizedBox(width: 4),

        TextButton(
          onPressed: () {
            debugPrint('로그인 버튼 클릭');
          },
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            '로그인',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.violet,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
