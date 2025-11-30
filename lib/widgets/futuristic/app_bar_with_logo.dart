import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/widgets/futuristic/offline_indicator.dart';
import 'package:kattrick/widgets/notifications_badge_button.dart';
import 'package:kattrick/theme/futuristic_theme.dart';
import 'package:google_fonts/google_fonts.dart';

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
    // Figma design: White AppBar with border-bottom, uppercase title
    return Container(
      decoration: BoxDecoration(
        color: FuturisticColors.surface,
        border: Border(
          bottom: BorderSide(
            color: FuturisticColors.surfaceVariant,
            width: 1,
          ),
        ),
      ),
      child: AppBar(
        title: title != null
            ? Text(
                title!.toUpperCase(),
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: FuturisticColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  }
                },
                tooltip: 'חזור',
                color: FuturisticColors.textPrimary,
              )
            : null,
        actions: [
          const OfflineIndicatorIcon(),
          const NotificationsBadgeButton(),
          if (actions != null) ...actions!,
        ],
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        foregroundColor: FuturisticColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

