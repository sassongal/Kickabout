import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kattrick/widgets/futuristic/stats_ring.dart';
import 'package:kattrick/widgets/futuristic/futuristic_card.dart';

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
    // Figma design: PERFORMANCE heading with horizontal stats rings
    return FuturisticCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading - matching Figma
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
          // Horizontal list of stats rings (4 metrics: Games, Wins, Goals, Assists)
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                StatsRing(
                  value: gamesPlayed,
                  maxValue: 100,
                  label: 'משחקים',
                  color: const Color(0xFF1976D2),
                ),
                const SizedBox(width: 16),
                StatsRing(
                  value: wins,
                  maxValue: gamesPlayed > 0 ? gamesPlayed : 1,
                  label: 'נצחונות',
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 16),
                StatsRing(
                  value: goals,
                  maxValue: 50,
                  label: 'שערים',
                  color: const Color(0xFF9C27B0),
                ),
                const SizedBox(width: 16),
                StatsRing(
                  value: assists,
                  maxValue: 50,
                  label: 'בישולים',
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

