import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/services/hub_permissions_service.dart';

class HubAdminSpeedDial extends ConsumerWidget {
  final String hubId;
  final HubPermissions permissions;

  const HubAdminSpeedDial(
      {super.key, required this.hubId, required this.permissions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    // Watch for active sessions in this hub
    final gamesStream = ref.watch(gamesRepositoryProvider).watchGamesByHub(hubId);

    return StreamBuilder(
      stream: gamesStream,
      builder: (context, snapshot) {
        // Find first active session (if any)
        final games = snapshot.data ?? [];
        final activeGame = games.cast().firstWhere(
          (game) => game?.session.isActive == true,
          orElse: () => null,
        );

        return SpeedDial(
          icon: Icons.add,
          activeIcon: Icons.close,
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          spacing: 12,
          spaceBetweenChildren: 8,
          overlayColor: Colors.black,
          overlayOpacity: 0.5,
          children: [
            // Active Session FAB (ONLY when session is active)
            if (activeGame != null && activeGame.eventId != null)
              SpeedDialChild(
                child: const Icon(Icons.sports_soccer, color: Colors.white),
                backgroundColor: const Color(0xFFFF6B35), // Vibrant orange
                foregroundColor: Colors.white,
                label: 'כנס לסשן פעיל',
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                labelBackgroundColor: Colors.black87,
                onTap: () => context.push(
                  '/hubs/$hubId/events/${activeGame.eventId}/game-session',
                ),
              ),
        if (permissions.canCreateGames)
          SpeedDialChild(
            child: const Icon(Icons.event, color: Colors.black),
            backgroundColor: const Color(0xFFFF6B35), // Vibrant orange
            foregroundColor: Colors.black,
            label: 'צור משחק',
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            labelBackgroundColor: Colors.black87,
            onTap: () => context.push('/games/create?hubId=$hubId'),
          ),
        if (permissions.canCreatePosts)
          SpeedDialChild(
            child: const Icon(Icons.group_add, color: Colors.black),
            backgroundColor: const Color(0xFF00D9FF), // Bright cyan
            foregroundColor: Colors.black,
            label: 'מחפש שחקנים',
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            labelBackgroundColor: Colors.black87,
            onTap: () => context.push('/hubs/$hubId/create-recruiting-post'),
          ),
        if (permissions.canInvitePlayers)
          SpeedDialChild(
            child: const Icon(Icons.person_search, color: Colors.black),
            backgroundColor: const Color(0xFF39FF14), // Neon green
            foregroundColor: Colors.black,
            label: 'חפש שחקנים',
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            labelBackgroundColor: Colors.black87,
            onTap: () => context.push('/hubs/$hubId/scouting'),
          ),
          ],
        );
      },
    );
  }
}
