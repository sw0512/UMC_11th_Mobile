import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../view_models/session_ratings.dart';
import '../widgets/profile_header.dart';
import '../widgets/favorite_genres.dart';
import '../widgets/movielog_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: auth.storageCleanupInProgress ? null : auth.logout,
            child: const Text('로그아웃'),
          ),
        ],
      ),
      body:
          auth.memberStatus == MemberLoadStatus.loading ||
              auth.memberStatus == MemberLoadStatus.idle
          ? const Center(child: CircularProgressIndicator())
          : auth.memberStatus == MemberLoadStatus.error
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(auth.message ?? '내 정보를 불러오지 못했어요.'),
                  const SizedBox(height: 16),
                  MovieLogButton(
                    label: '다시 시도',
                    onPressed: () => auth.loadMember(force: true),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              children: [
                const ProfileHeader(),
                const SizedBox(height: 16),
                MovieLogButton(
                  label: '프로필 수정',
                  onPressed: auth.member == null
                      ? null
                      : () => context.push('/my/profile/edit'),
                ),
                const SizedBox(height: 32),
                const FavoriteGenres(),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.star_outline),
                  title: const Text('내가 등록한 평점'),
                  subtitle: Text(
                    '현재 세션 ${context.watch<SessionRatings>().items.length}개',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/my/ratings'),
                ),
              ],
            ),
    );
  }
}
