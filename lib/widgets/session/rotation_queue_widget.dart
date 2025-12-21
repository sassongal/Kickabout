import 'package:flutter/material.dart';
import 'package:kattrick/models/rotation_state.dart';
import 'package:kattrick/models/team.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// RotationQueueWidget - Visualizes the current match and waiting queue
///
/// Displays:
/// - Current match: Team A vs Team B (highlighted)
/// - Waiting queue: Teams waiting to play (ordered)
///
/// Supports 2-8 teams dynamically
class RotationQueueWidget extends StatelessWidget {
  final RotationState? currentRotation;
  final List<Team> teams;

  const RotationQueueWidget({
    super.key,
    required this.currentRotation,
    required this.teams,
  });

  @override
  Widget build(BuildContext context) {
    if (currentRotation == null) {
      return const SizedBox.shrink();
    }

    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'סבב נוכחי',
              style: PremiumTypography.techHeadline.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),

            // Current match display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTeamChip(
                  currentRotation!.teamAColor,
                  isPlaying: true,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'VS',
                    style: PremiumTypography.heading2.copyWith(
                      color: PremiumColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildTeamChip(
                  currentRotation!.teamBColor,
                  isPlaying: true,
                ),
              ],
            ),

            // Waiting queue (only show if there are waiting teams)
            if (currentRotation!.waitingTeamColors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 18,
                    color: PremiumColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'בתור:',
                    style: PremiumTypography.bodyMedium.copyWith(
                      color: PremiumColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: currentRotation!.waitingTeamColors
                    .map((color) => _buildTeamChip(color, isPlaying: false))
                    .toList(),
              ),
            ],

            // Match counter
            const SizedBox(height: 12),
            Center(
              child: Text(
                'משחק #${currentRotation!.currentMatchNumber}',
                style: PremiumTypography.bodySmall.copyWith(
                  color: PremiumColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamChip(String teamColor, {required bool isPlaying}) {
    // Find team by color
    final team = teams.firstWhere(
      (t) => (t.color ?? t.name) == teamColor,
      orElse: () => Team(
        teamId: teamColor,
        name: teamColor,
        playerIds: [],
      ),
    );

    final colorValue = team.colorValue ?? 0xFF2196F3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPlaying
            ? Color(colorValue).withValues(alpha: 0.15)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPlaying ? Color(colorValue) : PremiumColors.divider,
          width: isPlaying ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Color(colorValue),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            teamColor,
            style: PremiumTypography.bodyMedium.copyWith(
              fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
              color: isPlaying
                  ? PremiumColors.textPrimary
                  : PremiumColors.textSecondary,
            ),
          ),
          if (isPlaying) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.sports_soccer,
              size: 16,
              color: Color(colorValue),
            ),
          ],
        ],
      ),
    );
  }
}
