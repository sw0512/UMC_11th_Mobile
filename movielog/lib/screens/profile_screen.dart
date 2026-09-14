import 'package:flutter/material.dart';

import '../widgets/common_app_bar.dart';
import '../widgets/profile_body.dart';

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
