import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SignUpField extends StatelessWidget {
  const SignUpField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.validator,
    required this.touched,
    required this.onChanged,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.obscureText = false,
  });

  final String label;
  final String hintText;

  final TextEditingController controller;
  final FocusNode? focusNode;

  final String? Function(String?) validator;

  final bool touched;
  final bool obscureText;

  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final errorMessage = validator(controller.text);

    final hasError = touched && errorMessage != null;

    final isValid =
        touched && controller.text.isNotEmpty && errorMessage == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.titleMedium),

        const SizedBox(height: 4),

        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.hint),
            isDense: true,
            filled: true,
            fillColor: hasError
                ? AppColors.errorContainer
                : AppColors.cardBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 17,
              vertical: 10,
            ),

            suffixIcon: hasError
                ? const Icon(Icons.error_outline, color: AppColors.error)
                : isValid
                ? const Icon(Icons.check_circle, color: AppColors.violet)
                : null,

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.outline,
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.violet, width: 2),
            ),

            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error),
            ),

            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),

            errorStyle: AppTextStyles.bodySmall.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}
