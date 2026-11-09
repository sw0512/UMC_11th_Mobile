import 'package:flutter/material.dart';

import '../movielog_button.dart';
import '../../theme/app_text_styles.dart';

class TermsAndSubmitSection extends StatelessWidget {
  const TermsAndSubmitSection({
    super.key,
    required this.agreedToTerms,
    required this.canSubmit,
    this.isSubmitting = false,
    required this.onTermsChanged,
    required this.onSubmit,
  });

  final bool agreedToTerms;
  final bool canSubmit;
  final bool isSubmitting;

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

        MovieLogButton(
          label: '가입하기',
          width: double.infinity,
          isLoading: isSubmitting,
          onPressed: canSubmit ? onSubmit : null,
        ),
      ],
    );
  }
}
