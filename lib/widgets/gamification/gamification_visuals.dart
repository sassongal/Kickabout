import 'package:flutter/material.dart';
import 'package:kattrick/theme/premium_theme.dart';

class LevelIcon extends StatelessWidget {
  final int level;
  final double size;

  const LevelIcon({
    super.key,
    required this.level,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    Color levelColor;
    String levelName;

    if (level < 5) {
      levelColor = Colors.grey;
      levelName = 'Novice';
    } else if (level < 15) {
      levelColor = PremiumColors.primary;
      levelName = 'Amateur';
    } else if (level < 30) {
      levelColor = PremiumColors.secondary;
      levelName = 'Pro';
    } else if (level < 50) {
      levelColor = Colors.purple;
      levelName = 'Elite';
    } else {
      levelColor = Colors.amber;
      levelName = 'Legend';
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            levelColor.withValues(alpha: 0.4),
            levelColor.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: levelColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: levelColor.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$level',
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: levelColor,
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
            Text(
              levelName,
              style: TextStyle(
                fontSize: size * 0.15,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AchievementBadge extends StatelessWidget {
  final String badgeId;
  final String label;
  final bool isUnlocked;
  final double size;

  const AchievementBadge({
    super.key,
    required this.badgeId,
    required this.label,
    this.isUnlocked = true,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        _getBadgeColor(badgeId).withValues(alpha: isUnlocked ? 1.0 : 0.3);

    return Container(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background hexagon-ish shape
          Container(
            width: size * 0.9,
            height: size * 0.9,
            decoration: BoxDecoration(
              color: PremiumColors.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 8,
                      )
                    ]
                  : null,
            ),
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getBadgeIcon(badgeId),
                size: size * 0.4,
                color: color,
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: size * 0.12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (!isUnlocked)
            Icon(
              Icons.lock_outline,
              size: size * 0.3,
              color: Colors.white.withValues(alpha: 0.5),
            ),
        ],
      ),
    );
  }

  Color _getBadgeColor(String id) {
    if (id.contains('hundred')) return Colors.amber;
    if (id.contains('fifty')) return Colors.purple;
    if (id.contains('ten')) return PremiumColors.secondary;
    if (id.contains('mvp')) return Colors.amber;
    if (id.contains('Goal')) return Colors.orange;
    return PremiumColors.primary;
  }

  IconData _getBadgeIcon(String id) {
    if (id.contains('Game')) return Icons.sports_soccer;
    if (id.contains('Goal')) return Icons.workspace_premium;
    if (id.contains('mvp')) return Icons.military_tech;
    return Icons.emoji_events;
  }
}
