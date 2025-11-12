import 'package:flutter/material.dart';
import 'package:kickabout/theme/futuristic_theme.dart';
import 'package:kickabout/widgets/futuristic/progress_ring.dart';
import 'package:kickabout/widgets/futuristic/futuristic_card.dart';

/// Real-time stats dashboard widget
class StatsDashboard extends StatelessWidget {
  final int gamesPlayed;
  final int wins;
  final double averageRating;
  final int goals;
  final int assists;

  const StatsDashboard({
    super.key,
    required this.gamesPlayed,
    required this.wins,
    required this.averageRating,
    required this.goals,
    required this.assists,
  });

  @override
  Widget build(BuildContext context) {
    final winRate = gamesPlayed > 0 ? wins / gamesPlayed : 0.0;
    
    return FuturisticCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PERFORMANCE',
                style: FuturisticTypography.techHeadline,
              ),
              Icon(
                Icons.analytics,
                color: FuturisticColors.secondary,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Main stats grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Win rate ring
              ProgressRing(
                progress: winRate,
                size: 100,
                label: 'WIN RATE',
                showPercentage: true,
                color: FuturisticColors.secondary,
              ),
              // Rating ring
              ProgressRing(
                progress: averageRating / 10.0,
                size: 100,
                label: 'RATING',
                centerWidget: Text(
                  averageRating.toStringAsFixed(1),
                  style: FuturisticTypography.heading2.copyWith(
                    color: FuturisticColors.secondary,
                  ),
                ),
                color: FuturisticColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Secondary stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'GAMES',
                value: gamesPlayed.toString(),
                icon: Icons.sports_soccer,
              ),
              _StatItem(
                label: 'GOALS',
                value: goals.toString(),
                icon: Icons.emoji_events,
              ),
              _StatItem(
                label: 'ASSISTS',
                value: assists.toString(),
                icon: Icons.handshake,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: FuturisticColors.secondary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: FuturisticTypography.heading3.copyWith(
            color: FuturisticColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: FuturisticTypography.bodySmall.copyWith(
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

