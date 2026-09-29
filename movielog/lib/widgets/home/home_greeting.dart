import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      '오늘은 어떤\n영화를 볼까요?',
      style: TextStyle(
        fontSize: 34,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: AppColors.black,
      ),
    );
  }
}
