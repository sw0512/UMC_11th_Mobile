import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../widgets/movielog_button.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.message, this.onRetry});
  final String? message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Text('FLUTTER 8주차', textAlign: TextAlign.center),
            const Spacer(),
            SvgPicture.asset(
              'assets/logos/movielog_logo.svg',
              width: 84,
              height: 84,
            ),
            const SizedBox(height: 32),
            Text(
              '영화의 순간을\n기록하세요',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            if (onRetry == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              Text(
                message ?? '로그인 상태를 확인하지 못했어요.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              MovieLogButton(label: '다시 시도', onPressed: onRetry),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}
