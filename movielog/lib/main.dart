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
          children: [
            Icon(Icons.movie_outlined),
            Text('영화의 순간을 기록하세요'),
            Text('보고 싶은 영화부터 나만의 평점까지 한곳에서 관리해요'),
            ElevatedButton(onPressed: () {}, child: Text('시작하기')),
          ],
        ),
      ),
    );
  }
}
