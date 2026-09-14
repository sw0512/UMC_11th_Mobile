import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class EditProfileButton extends StatelessWidget {
  const EditProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          foregroundColor: AppColors.violet,
          backgroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.violet, width: 1.5),
          ),
        ),
        child: const Text('프로필 수정'),
      ),
    );
  }
}
