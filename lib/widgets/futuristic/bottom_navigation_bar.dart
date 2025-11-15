import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:kickadoor/data/repositories_providers.dart';
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
    final currentUserId = ref.watch(currentUserIdProvider);

    return Container(
      decoration: BoxDecoration(
        color: FuturisticColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                icon: Icons.sports_soccer_rounded,
                label: 'משחקים',
                route: '/games',
                currentRoute: currentRoute,
                onTap: () => context.go('/games'),
              ),
              _NavItem(
                icon: Icons.location_on_rounded,
                label: 'מפה',
                route: '/map',
                currentRoute: currentRoute,
                onTap: () => context.go('/map'),
              ),
              _NavItem(
                icon: Icons.group_rounded,
                label: 'קהילות',
                route: '/hubs-board',
                currentRoute: currentRoute,
                onTap: () => context.go('/hubs-board'),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'פרופיל',
                route: '/profile',
                currentRoute: currentRoute,
                onTap: () {
                  if (currentUserId != null) {
                    context.go('/profile/$currentUserId');
                  }
                },
              ),
            ],
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive
                      ? FuturisticColors.primary
                      : FuturisticColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

