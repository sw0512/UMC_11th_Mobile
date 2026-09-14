import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

void main() {
  for (final movie in movies) {
    debugPrint(movie.title);
  }

  final displayNickname = nickname ?? '이름 없음';
  debugPrint(displayNickname);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: AppTheme.light, home: const StartScreen());
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF593C98);
    const background = Color(0xFFFAF8F4);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 0),

              const Text(
                'FLUTTER 0주차',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF55515D),
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 45),

              const Icon(
                Icons.movie_outlined,
                size: 64,
                color: purple,
                semanticLabel: '영화 아이콘',
              ),

              const SizedBox(height: 55),

              const Text(
                '영화의 순간을\n기록하세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1D1D1B),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.5,
                  color: Color(0xFF55515D),
                ),
              ),

              const Spacer(),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    debugPrint('시작하기 버튼을 눌렀습니다.');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('시작하기', style: TextStyle(fontSize: 18)),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class Movie {
  const Movie({required this.id, required this.title});

  final int id;
  final String title;
}

final movies = <Movie>[
  Movie(id: 1, title: '인셉션'),
  Movie(id: 2, title: '인터스텔라'),
  Movie(id: 3, title: '테넷'),
];

String? nickname;
