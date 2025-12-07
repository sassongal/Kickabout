import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/theme/futuristic_theme.dart';

class GameFeedCard extends StatelessWidget {
  final Game game;
  final bool isLocked;
  final bool isMyHub;
  final bool isPublic;
  final double? distanceKm; // Optional distance from user in kilometers

  const GameFeedCard({
    super.key,
    required this.game,
    required this.isLocked,
    required this.isMyHub,
    required this.isPublic,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine colors based on state
    final Color primaryColor;
    final Color secondaryColor;
    final IconData icon;
    final String label;

    if (isLocked) {
      primaryColor = Colors.grey.shade700;
      secondaryColor = Colors.grey.shade500;
      icon = Icons.lock;
      label = 'משחק Hub פרטי';
    } else if (isPublic) {
      primaryColor = Colors.teal;
      secondaryColor = Colors.tealAccent.shade700;
      icon = Icons.public;
      label = 'משחק ציבורי';
    } else {
      // My Hub
      primaryColor = FuturisticColors.primary;
      secondaryColor = FuturisticColors.secondary;
      icon = Icons.group;
      label = game.denormalized.hubName ?? 'ה-Hub שלי';
    }

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          _showLockedDialog(context);
        } else {
          context.push('/games/${game.gameId}');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLocked
                ? Colors.grey.withValues(alpha: 0.3)
                : primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Left accent strip
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 6,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [primaryColor, secondaryColor],
                    ),
                  ),
                ),
              ),

              // Content with opacity for locked cards
              Opacity(
                opacity: isLocked ? 0.7 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 16, 16, 16), // Extra padding on left for strip
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Label + Time
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 12, color: primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  label,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Multi-match session badge
                          if (game.session.matches.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.purple.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timer,
                                      size: 10, color: Colors.purple),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${game.session.matches.length} משחקים',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // Distance badge (if available and not locked)
                          if (distanceKm != null && !isLocked) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.near_me,
                                      size: 10, color: Colors.green),
                                  const SizedBox(width: 3),
                                  Text(
                                    distanceKm! < 1
                                        ? '${(distanceKm! * 1000).round()}m'
                                        : '${distanceKm!.toStringAsFixed(1)} ק"מ',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            DateFormat('HH:mm').format(game.gameDate),
                            style: GoogleFonts.orbitron(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Date
                      Text(
                        DateFormat('EEEE, d MMMM', 'he').format(game.gameDate),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Location & Players (Privacy-Masked if Locked)
                      if (isLocked) ...[
                        // Locked: Show generic region only
                        Row(
                          children: [
                            Icon(Icons.lock_outline,
                                size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              game.region ?? 'מיקום פרטי',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Locked: Hide exact player count
                        Row(
                          children: [
                            Icon(Icons.group_outlined,
                                size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'חברי Hub בלבד',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Unlocked: Show full details
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                game.denormalized.venueName ??
                                    game.location ??
                                    'מיקום לא נקבע',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.people,
                                size: 16, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              '${game.denormalized.confirmedPlayerCount} / ${game.denormalized.maxParticipants ?? '?'} שחקנים',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ), // Close Opacity
            ],
          ),
        ),
      ),
    );
  }

  void _showLockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('משחק פרטי'),
        content: Text(
          'משחק זה שייך ל-Hub "${game.denormalized.hubName ?? 'פרטי'}".\n'
          'עליך להצטרף ל-Hub כדי לצפות בפרטים ולהירשם.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('סגור'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (game.hubId != null) {
                context.push('/hubs/${game.hubId}');
              }
            },
            child: const Text('צפה ב-Hub'),
          ),
        ],
      ),
    );
  }
}
