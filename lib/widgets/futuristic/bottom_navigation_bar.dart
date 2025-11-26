import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Futuristic Bottom Navigation Bar
class FuturisticBottomNavBar extends ConsumerWidget {
  final String currentRoute;

  const FuturisticBottomNavBar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Figma design: White bottom nav with border-top, icons with labels
    return Container(
      decoration: BoxDecoration(
        color: FuturisticColors.surface,
        border: Border(
          top: BorderSide(
            color: FuturisticColors.surfaceVariant,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  icon: Icons.favorite, // Heartbeat/vital signs icon
                  label: 'פעילות',
                  route: '/activity',
                  currentRoute: currentRoute,
                  onTap: () => context.go('/activity'),
                ),
                _NavItem(
                  icon: Icons.message_rounded,
                  label: 'קהילה',
                  route: '/feed',
                  currentRoute: currentRoute,
                  onTap: () => context.go('/feed'),
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
    // For profile, check if route starts with /profile/
    if (route == '/profile') {
      return currentRoute.startsWith('/profile/');
    }
    // For activity feed
    if (route == '/activity') {
      return currentRoute == '/activity' || currentRoute.startsWith('/activity');
    }
    // For other routes, check if it starts with the route
    return currentRoute.startsWith(route);
  }

  @override
  Widget build(BuildContext context) {
    final isActive = this.isActive;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive
                    ? FuturisticColors.primary
                    : FuturisticColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                  color: isActive
                      ? FuturisticColors.primary
                      : FuturisticColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
