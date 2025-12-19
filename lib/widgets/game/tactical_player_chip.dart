import 'package:flutter/material.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:kattrick/logic/team_maker.dart';

import 'package:kattrick/widgets/animations/scan_in_animation.dart';

/// A premium, compact player chip for the tactical scouting view.
class TacticalPlayerChip extends StatelessWidget {
  final User user;
  final PlayerForTeam player;
  final VoidCallback? onTap;

  const TacticalPlayerChip({
    super.key,
    required this.user,
    required this.player,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScanInAnimation(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer Glow
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            _getRoleColor(player.role).withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                // Border Ring
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getRoleColor(player.role),
                      width: 2,
                    ),
                  ),
                ),
                // Avatar
                PlayerAvatar(user: user, size: AvatarSize.sm),
                // Rating Badge
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: _isUnrated(player.rating)
                          ? Colors.orange.shade100
                          : PremiumColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _isUnrated(player.rating)
                            ? Colors.orange
                            : _getRoleColor(player.role),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: _isUnrated(player.rating)
                        ? Icon(
                            Icons.help_outline,
                            size: 12,
                            color: Colors.orange.shade900,
                          )
                        : Text(
                            player.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getRoleColor(player.role),
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user.displayName ?? user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(PlayerRole role) {
    return switch (role) {
      PlayerRole.goalkeeper => Colors.orange,
      PlayerRole.defender => Colors.blue,
      PlayerRole.midfielder => Colors.green,
      PlayerRole.attacker => Colors.red,
    };
  }

  /// Check if player has default/unrated rating (4.0)
  bool _isUnrated(double rating) {
    return rating == 4.0;
  }
}
