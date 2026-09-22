import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.centerTitle = false,
    this.titleStyle,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      leadingWidth: 56,
      leading: onBack == null
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: onBack,
            ),
      title: Text(title, style: titleStyle ?? AppTextStyles.titleLarge),
      actions: actions,
      centerTitle: centerTitle,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
