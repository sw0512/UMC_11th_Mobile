import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class TermsAndSubmitSection extends StatelessWidget {
  const TermsAndSubmitSection({
    super.key,
    required this.agreedToTerms,
    required this.canSubmit,
    required this.onTermsChanged,
    required this.onSubmit,
  });

  final bool agreedToTerms;
  final bool canSubmit;

  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onSubmit;

  static const Color disabledButtonColor = Color(0xFFCCC2DC);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: Checkbox(
                value: agreedToTerms,
                onChanged: onTermsChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -4,
                ),
              ),
            ),

            const SizedBox(width: 6),

            Expanded(
              child: Text('필수 약관에 동의합니다', style: AppTextStyles.bodyMedium),
            ),
          ],
        ),

        const SizedBox(height: 24),

        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: canSubmit ? onSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.violet,
              disabledBackgroundColor: disabledButtonColor,
              foregroundColor: AppColors.white,
              disabledForegroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '가입하기',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
