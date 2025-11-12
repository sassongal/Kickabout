import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kickabout/theme/futuristic_theme.dart';
import 'package:kickabout/widgets/futuristic/futuristic_card.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/models/enums/game_status.dart';

/// Futuristic match card with animated elements
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
    
    return FuturisticCard(
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: FuturisticColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dateFormat.format(game.gameDate),
                      style: FuturisticTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeFormat.format(game.gameDate),
                    style: FuturisticTypography.labelMedium,
                  ),
                ],
              ),
              if (showStatus)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(game.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _getStatusColor(game.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusText(game.status).toUpperCase(),
                    style: FuturisticTypography.labelSmall.copyWith(
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
                  color: FuturisticColors.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    game.location ?? 'Location TBD',
                    style: FuturisticTypography.bodyMedium,
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
                color: FuturisticColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '${game.teamCount} TEAMS',
                style: FuturisticTypography.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(GameStatus status) {
    switch (status) {
      case GameStatus.teamSelection:
        return FuturisticColors.warning;
      case GameStatus.teamsFormed:
        return FuturisticColors.info;
      case GameStatus.inProgress:
        return FuturisticColors.success;
      case GameStatus.completed:
        return FuturisticColors.textSecondary;
      case GameStatus.statsInput:
        return FuturisticColors.accent;
    }
  }

  String _getStatusText(GameStatus status) {
    switch (status) {
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
    }
  }
}

