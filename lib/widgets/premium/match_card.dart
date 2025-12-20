import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/models/models.dart';

/// Premium match card with animated elements
class MatchCard extends StatelessWidget {
  final Game game;
  final VoidCallback? onTap;
  final bool showStatus;

  const MatchCard({
    super.key,
    required this.game,
    this.onTap,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return PremiumCard(
      onTap: onTap,
      showGlow: game.status == GameStatus.inProgress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: PremiumColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dateFormat.format(game.gameDate),
                      style: PremiumTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeFormat.format(game.gameDate),
                    style: PremiumTypography.labelMedium,
                  ),
                ],
              ),
              if (showStatus)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(game.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _getStatusColor(game.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusText(game.status).toUpperCase(),
                    style: PremiumTypography.labelSmall.copyWith(
                      color: _getStatusColor(game.status),
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Location
          if (game.location != null || game.locationPoint != null)
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: PremiumColors.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    game.location ?? 'Location TBD',
                    style: PremiumTypography.bodyMedium,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          // Teams info
          Row(
            children: [
              Icon(
                Icons.group,
                size: 16,
                color: PremiumColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '${game.teamCount} TEAMS',
                style: PremiumTypography.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(GameStatus status) {
    switch (status) {
      case GameStatus.draft:
        return PremiumColors.textSecondary;
      case GameStatus.scheduled:
        return PremiumColors.info;
      case GameStatus.recruiting:
        return PremiumColors.accent;
      case GameStatus.fullyBooked:
        return PremiumColors.success;
      case GameStatus.cancelled:
        return PremiumColors.textSecondary;
      case GameStatus.teamSelection:
        return PremiumColors.warning;
      case GameStatus.teamsFormed:
        return PremiumColors.info;
      case GameStatus.inProgress:
        return PremiumColors.success;
      case GameStatus.completed:
        return PremiumColors.textSecondary;
      case GameStatus.statsInput:
        return PremiumColors.accent;
      case GameStatus.archivedNotPlayed:
        return PremiumColors.textSecondary;
    }
  }

  String _getStatusText(GameStatus status) {
    switch (status) {
      case GameStatus.draft:
        return 'DRAFT';
      case GameStatus.scheduled:
        return 'SCHEDULED';
      case GameStatus.recruiting:
        return 'RECRUITING';
      case GameStatus.fullyBooked:
        return 'FULL';
      case GameStatus.cancelled:
        return 'CANCELLED';
      case GameStatus.teamSelection:
        return 'TEAM SELECTION';
      case GameStatus.teamsFormed:
        return 'READY';
      case GameStatus.inProgress:
        return 'LIVE';
      case GameStatus.completed:
        return 'COMPLETED';
      case GameStatus.statsInput:
        return 'STATS INPUT';
      case GameStatus.archivedNotPlayed:
        return 'ARCHIVED';
    }
  }
}
