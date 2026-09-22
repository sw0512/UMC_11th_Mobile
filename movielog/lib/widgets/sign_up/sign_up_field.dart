import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class MovieLogTextFormField extends StatefulWidget {
  const MovieLogTextFormField({
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
    this.enableObscureTextToggle = false,
  });

  final String label;
  final String hintText;

  final TextEditingController controller;
  final FocusNode? focusNode;

  final String? Function(String?) validator;

  final bool touched;
  final bool obscureText;
  final bool enableObscureTextToggle;

  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  State<MovieLogTextFormField> createState() => _MovieLogTextFormFieldState();
}

class _MovieLogTextFormFieldState extends State<MovieLogTextFormField> {
  late bool isObscured = widget.obscureText;

  void toggleObscureText() {
    setState(() {
      isObscured = !isObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = widget.validator(widget.controller.text);

    final hasError = widget.touched && errorMessage != null;

    final isValid =
        widget.touched &&
        widget.controller.text.isNotEmpty &&
        errorMessage == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.titleMedium),

        const SizedBox(height: 4),

        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: widget.enableObscureTextToggle
              ? isObscured
              : widget.obscureText,
          validator: widget.validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          decoration: InputDecoration(
            hintText: widget.hintText,
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

            suffixIcon: widget.enableObscureTextToggle
                ? IconButton(
                    onPressed: toggleObscureText,
                    tooltip: isObscured ? '비밀번호 표시' : '비밀번호 숨기기',
                    icon: SvgPicture.asset(
                      isObscured
                          ? 'assets/icons/visibility.svg'
                          : 'assets/icons/visibility_off.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        AppColors.hint,
                        BlendMode.srcIn,
                      ),
                    ),
                  )
                : hasError
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
