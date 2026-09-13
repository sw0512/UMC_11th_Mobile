import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: StartScreen());
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined),
            SizedBox(height: 16),
            Text('영화의 순간을 기록하세요'),
            SizedBox(height: 8),
            Text('보고 싶은 영화부터 나만의 평점까지 한곳에서 관리해요', textAlign: TextAlign.center),
            SizedBox(height: 24),
            ElevatedButton(onPressed: () {}, child: Text('시작하기')),
          ],
        ),
      ),
    );
  }
}
