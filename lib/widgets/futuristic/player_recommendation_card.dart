import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/theme/futuristic_theme.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/widgets/futuristic/futuristic_card.dart';
import 'package:kattrick/widgets/player_avatar.dart';

/// Player recommendation card with profile photo and details
class PlayerRecommendationCard extends StatelessWidget {
  final User player;
  final String? reason; // Why this player is recommended
  final double? distanceKm; // Distance in km (if available)

  const PlayerRecommendationCard({
    super.key,
    required this.player,
    this.reason,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return FuturisticCard(
      onTap: () => context.push('/profile/${player.uid}'),
      showGlow: true,
      child: Row(
        children: [
          // Profile photo
          Stack(
            children: [
              PlayerAvatar(
                user: player,
                radius: 32,
              ),
              // Availability indicator
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getAvailabilityColor(),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: FuturisticColors.background,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: FuturisticColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'המלצת AI',
                      style: FuturisticTypography.labelSmall.copyWith(
                        color: FuturisticColors.secondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  player.name,
                  style: FuturisticTypography.heading3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (player.preferredPosition.isNotEmpty) ...[
                      Icon(
                        Icons.sports_soccer,
                        size: 14,
                        color: FuturisticColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        player.preferredPosition,
                        style: FuturisticTypography.bodySmall,
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (player.city != null && player.city!.isNotEmpty) ...[
                      Icon(
                        Icons.location_city,
                        size: 14,
                        color: FuturisticColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        player.city!,
                        style: FuturisticTypography.bodySmall,
                      ),
                    ],
                  ],
                ),
                if (reason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    reason!,
                    style: FuturisticTypography.bodySmall.copyWith(
                      color: FuturisticColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (distanceKm != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: FuturisticColors.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distanceKm!.toStringAsFixed(1)} ק"מ',
                        style: FuturisticTypography.bodySmall.copyWith(
                          color: FuturisticColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Rating/Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: FuturisticColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  player.currentRankScore.toStringAsFixed(1),
                  style: FuturisticTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'דירוג',
                style: FuturisticTypography.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getAvailabilityColor() {
    switch (player.availabilityStatus) {
      case 'available':
        return Colors.green;
      case 'busy':
        return Colors.orange;
      case 'notAvailable':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

