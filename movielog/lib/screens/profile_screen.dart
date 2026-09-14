import 'package:flutter/material.dart';

import '../widgets/common_app_bar.dart';
import '../widgets/profile_header.dart';
import '../widgets/stat_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CommonAppBar(title: '내 프로필'),
      body: ProfileBody(),
    );
  }
}

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileHeader(),
            SizedBox(height: 24),
            StatItem(label: '본 영화', value: '24'),
          ],
        ),
      ),
    );
  }
}
