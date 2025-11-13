import 'package:flutter/material.dart';
import 'package:kickadoor/widgets/kicka_ball_logo.dart';
import 'package:kickadoor/widgets/futuristic/offline_indicator.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';

/// AppBar with KICKA BALL logo
class AppBarWithLogo extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showLogo;

  const AppBarWithLogo({
    super.key,
    this.title,
    this.actions,
    this.showBackButton = true,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: showLogo
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                KickaBallLogo(
                  size: 32,
                  showText: false,
                ),
                if (title != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    title!,
                    style: FuturisticTypography.techHeadline.copyWith(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            )
          : title != null
              ? Text(
                  title!,
                  style: FuturisticTypography.techHeadline.copyWith(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                )
              : null,
      actions: [
        const OfflineIndicatorIcon(),
        if (actions != null) ...actions!,
      ],
      automaticallyImplyLeading: showBackButton,
      backgroundColor: FuturisticColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

