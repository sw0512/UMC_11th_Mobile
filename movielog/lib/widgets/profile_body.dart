import 'package:flutter/material.dart';

import 'edit_profile_button.dart';
import 'profile_header.dart';
import 'stat_item.dart';
import 'favorite_genres.dart';

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

            SizedBox(height: 16),

            Align(alignment: Alignment.center, child: EditProfileButton()),

            SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: StatItem(label: '본 영화', value: '342'),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: StatItem(label: '평점', value: '4.2'),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: StatItem(label: '즐겨찾기', value: '58'),
                ),
              ],
            ),
            SizedBox(height: 32),
            FavoriteGenres(),
          ],
        ),
      ),
    );
  }
}
