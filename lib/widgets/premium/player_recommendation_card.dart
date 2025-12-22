import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:kattrick/data/proteams_repository.dart';

/// Player recommendation card with profile photo and details
class PlayerRecommendationCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return PremiumCard(
      onTap: () => context.push('/profile/${player.uid}'),
      showGlow: true,
      child: Row(
        children: [
          // Profile photo
          PlayerAvatar(
            user: player,
            radius: 32,
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
                Row(
                  children: [
                    // Player name
                    Flexible(
                      child: Text(
                        player.name,
                        style: PremiumTypography.heading3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Favorite team badge
                    if (player.favoriteProTeamId != null) ...[
                      const SizedBox(width: 6),
                      FutureBuilder<ProTeam?>(
                        future: ref.read(proTeamsRepositoryProvider).getTeam(player.favoriteProTeamId!),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: snapshot.data!.logoUrl,
                                width: 20,
                                height: 20,
                                fit: BoxFit.contain,
                                errorWidget: (context, url, error) => const SizedBox.shrink(),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ],
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
}

