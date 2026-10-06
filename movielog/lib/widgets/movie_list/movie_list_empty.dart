import 'package:flutter/material.dart';

class MovieListEmpty extends StatelessWidget {
  const MovieListEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: Text('조건에 맞는 영화가 없습니다.')),
    );
  }
}
