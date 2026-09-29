import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'MovieLog',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.violet,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.search, size: 32, color: AppColors.violet),
        ),
      ],
    );
  }
}
