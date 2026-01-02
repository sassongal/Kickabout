import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/widgets/premium/offline_indicator.dart';
import 'package:kattrick/widgets/notifications_badge_button.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppBar with KICKA BALL logo
/// Refactored: Large animated Logo triggers the Menu.
class AppBarWithLogo extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool
      showLogo; // Kept for API compatibility, but usually true for top-level

  const AppBarWithLogo({
    super.key,
    this.title,
    this.actions,
    this.showBackButton = true,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the leading widget: Back Button OR Menu Logo
    Widget? leading;

    if (showBackButton && context.canPop()) {
      leading = IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: () => context.pop(),
        tooltip: 'חזור',
        color: PremiumColors.textPrimary,
      );
    } else {
      // Show Menu Trigger Logo
      leading = const _AnimatedMenuLogo();
    }

    return Container(
      decoration: BoxDecoration(
        color: PremiumColors.surface.withValues(alpha: 0.2), // Glass effect
        border: Border(
          bottom: BorderSide(
            color: PremiumColors.surfaceVariant.withValues(alpha: 0.5),
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
                  color: PremiumColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        leading: leading,
        // Increase leading width significantly for the large logo
        leadingWidth:
            (showBackButton && context.canPop()) ? kToolbarHeight : 100,
        actions: [
          const OfflineIndicatorIcon(),
          const NotificationsBadgeButton(),
          if (actions != null) ...actions!,
        ],
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        foregroundColor: PremiumColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(
      kToolbarHeight + 10); // Slightly taller if needed, or keep standard
}

class _AnimatedMenuLogo extends StatefulWidget {
  const _AnimatedMenuLogo();

  @override
  State<_AnimatedMenuLogo> createState() => _AnimatedMenuLogoState();
}

class _AnimatedMenuLogoState extends State<_AnimatedMenuLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
      Scaffold.of(context).openDrawer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 90, // Approx 3x larger than standard 24/32px icon
          height: 90,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(4.0),
          child: Image.asset(
            'assets/logo/KattruckLOGOFULL.png', // Using Full Logo as requested
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.menu, size: 32),
          ),
        ),
      ),
    );
  }
}
