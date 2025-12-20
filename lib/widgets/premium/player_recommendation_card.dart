import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
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
    return PremiumCard(
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
                      color: PremiumColors.background,
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
                      color: PremiumColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'המלצת AI',
                      style: PremiumTypography.labelSmall.copyWith(
                        color: PremiumColors.secondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  player.name,
                  style: PremiumTypography.heading3,
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
                        color: PremiumColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        player.preferredPosition,
                        style: PremiumTypography.bodySmall,
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (player.city != null && player.city!.isNotEmpty) ...[
                      Icon(
                        Icons.location_city,
                        size: 14,
                        color: PremiumColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        player.city!,
                        style: PremiumTypography.bodySmall,
                      ),
                    ],
                  ],
                ),
                if (reason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    reason!,
                    style: PremiumTypography.bodySmall.copyWith(
                      color: PremiumColors.textSecondary,
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
                        color: PremiumColors.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distanceKm!.toStringAsFixed(1)} ק"מ',
                        style: PremiumTypography.bodySmall.copyWith(
                          color: PremiumColors.secondary,
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
                  gradient: PremiumColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  player.currentRankScore.toStringAsFixed(1),
                  style: PremiumTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'דירוג',
                style: PremiumTypography.bodySmall,
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

