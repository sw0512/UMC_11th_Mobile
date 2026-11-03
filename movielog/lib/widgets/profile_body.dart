import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'edit_profile_button.dart';
import 'profile_header.dart';
import 'stat_item.dart';
import 'favorite_genres.dart';

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ListView(
          children: [
            ProfileHeader(),

            SizedBox(height: 16),

            Align(alignment: Alignment.center, child: EditProfileButton()),

            SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: StatItem(
                    label: '본 영화',
                    value: '342',
                    margin: EdgeInsets.only(right: 4),
                  ),
                ),
                Expanded(
                  child: StatItem(
                    label: '평점',
                    value: '4.2',
                    margin: EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
                Expanded(
                  child: StatItem(
                    label: '즐겨찾기',
                    value: '58',
                    margin: EdgeInsets.only(left: 4),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
            const FavoriteGenres(),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.star_outline),
              title: const Text('내가 등록한 평점'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/my/ratings'),
            ),
          ],
        ),
      ),
    );
  }
}
