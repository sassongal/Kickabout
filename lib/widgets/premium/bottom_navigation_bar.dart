import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kattrick/routing/app_paths.dart';

/// Premium Bottom Navigation Bar - Floating & Glassmorphic
class PremiumBottomNavBar extends ConsumerWidget {
  final String currentRoute;

  const PremiumBottomNavBar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: PremiumColors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: PremiumColors.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'בית',
                    route: '/',
                    currentRoute: currentRoute,
                    onTap: () => context.go('/'),
                  ),
                  _NavItem(
                    icon: Icons.sports_soccer,
                    label: 'משחקים',
                    route: '/games',
                    currentRoute: currentRoute,
                    onTap: () => context.go('/games'),
                  ),
                  _NavItem(
                    icon: Icons.message_rounded,
                    label: 'קהילה',
                    route: AppPaths.community,
                    currentRoute: currentRoute,
                    onTap: () => context.go(AppPaths.community),
                  ),
                  _NavItem(
                    icon: Icons.map_rounded,
                    label: 'מפה',
                    route: '/map',
                    currentRoute: currentRoute,
                    onTap: () => context.go('/map'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    required this.onTap,
  });

  bool get isActive {
    if (route == '/') {
      return currentRoute == '/' ||
          currentRoute == '/home' ||
          currentRoute.isEmpty;
    }
    if (route == '/profile') {
      return currentRoute.startsWith('/profile/');
    }
    if (route == '/games') {
      return currentRoute == '/games' || currentRoute.startsWith('/games');
    }
    if (route == AppPaths.community) {
      return currentRoute == AppPaths.community ||
          currentRoute.startsWith(AppPaths.community);
    }
    return currentRoute.startsWith(route);
  }

  @override
  Widget build(BuildContext context) {
    final active = isActive;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active Indicator (Neon Dot/Line)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: active ? 20 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: PremiumColors.primary,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: PremiumColors.primary.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
              ),
            ),
            Icon(
              icon,
              size: 24,
              color: active
                  ? PremiumColors.primary
                  : PremiumColors.textSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                color: active
                    ? PremiumColors.textPrimary
                    : PremiumColors.textSecondary,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
