import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading - compact version
          Text(
            'PERFORMANCE',
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: const Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          // Compact horizontal list of stats
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                StatsRing(
                  value: gamesPlayed,
                  maxValue: 100,
                  label: 'Games',
                  color: const Color(0xFF1976D2),
                ),
                const SizedBox(width: 12),
                StatsRing(
                  value: wins,
                  maxValue: gamesPlayed > 0 ? gamesPlayed : 1,
                  label: 'Wins',
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 12),
                StatsRing(
                  value: goals,
                  maxValue: 50,
                  label: 'Goals',
                  color: const Color(0xFF9C27B0),
                ),
                const SizedBox(width: 12),
                StatsRing(
                  value: averageRating.toInt(),
                  maxValue: 10,
                  label: 'Rating',
                  color: const Color(0xFFFF9800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

