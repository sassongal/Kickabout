import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:kickadoor/widgets/futuristic/stats_ring.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_card.dart';

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
    return FuturisticCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading - matching Figma design
          Text(
            'PERFORMANCE',
            style: GoogleFonts.orbitron(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              color: const Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 24),
          // Stats grid - 2x2 layout matching Figma
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: 1.1,
            children: [
              StatsRing(
                value: gamesPlayed,
                maxValue: 100,
                label: 'Games Played',
                color: const Color(0xFF1976D2), // Primary blue
              ),
              StatsRing(
                value: wins,
                maxValue: gamesPlayed > 0 ? gamesPlayed : 1,
                label: 'Wins',
                color: const Color(0xFF4CAF50), // Secondary green
              ),
              StatsRing(
                value: goals,
                maxValue: 50,
                label: 'Goals',
                color: const Color(0xFF9C27B0), // Accent purple
              ),
              StatsRing(
                value: averageRating.toInt(),
                maxValue: 10,
                label: 'Avg Rating',
                color: const Color(0xFFFF9800), // Orange
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

