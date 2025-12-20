import 'package:flutter/material.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/widgets/game/tactical_pitch_background.dart';
import 'package:kattrick/widgets/game/tactical_player_chip.dart';
import 'package:kattrick/logic/team_maker.dart';
import 'package:kattrick/widgets/animations/scan_in_animation.dart';

class TeamCard extends StatelessWidget {
  final Team team;
  final int teamIndex;
  final Map<String, User> userMap;
  final List<PlayerForTeam> players;
  final Function(String playerId, int toTeamIndex) onPlayerDropped;
  final Function(User user, PlayerForTeam player, int teamIndex) onPlayerTap;

  const TeamCard({
    super.key,
    required this.team,
    required this.teamIndex,
    required this.userMap,
    required this.players,
    required this.onPlayerDropped,
    required this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    final teamColor = team.colorValue != null
        ? Color(team.colorValue!)
        : PremiumColors.primary;
    final avgRating =
        team.playerIds.isEmpty ? 0.0 : team.totalScore / team.playerIds.length;

    return ScanInAnimation(
      delay: Duration(milliseconds: teamIndex * 150),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DragTarget<String>(
          onWillAcceptWithDetails: (details) {
            return !team.playerIds.contains(details.data);
          },
          onAcceptWithDetails: (details) {
            onPlayerDropped(details.data, teamIndex);
          },
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;

            return PremiumCard(
              padding: EdgeInsets.zero,
              borderColor: isHovering ? PremiumColors.primary : null,
              child: Column(
                children: [
                  // Team Header (Compact)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: teamColor.withValues(alpha: 0.1),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: teamColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: teamColor.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              team.name,
                              style: PremiumTypography.heading3,
                            ),
                          ],
                        ),
                        Text(
                          'AVG: ${avgRating.toStringAsFixed(1)}',
                          style: PremiumTypography.labelLarge.copyWith(
                            color: teamColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tactical Pitch Area
                  Container(
                    height: 320,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    child: Stack(
                      children: [
                        // Pitch Background
                        Positioned.fill(
                          child: TacticalPitchBackground(
                            baseColor: teamColor,
                            isHalfPitch: true,
                          ),
                        ),

                        // Player Chips distributed by role
                        ..._buildTacticalPlayers(context),

                        // Drop Target Overlay
                        if (isHovering)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: PremiumColors.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: PremiumColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'העבר לכאן',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildTacticalPlayers(BuildContext context) {
    final widgets = <Widget>[];

    // Group players by role
    final gks = <String>[];
    final defs = <String>[];
    final mids = <String>[];
    final atts = <String>[];

    for (final id in team.playerIds) {
      final player = players.firstWhere(
        (p) => p.uid == id,
        orElse: () =>
            PlayerForTeam(uid: id, rating: 0, role: PlayerRole.midfielder),
      );
      switch (player.role) {
        case PlayerRole.goalkeeper:
          gks.add(id);
        case PlayerRole.defender:
          defs.add(id);
        case PlayerRole.midfielder:
          mids.add(id);
        case PlayerRole.attacker:
          atts.add(id);
      }
    }

    // Position players (relative coordinates 0.0 to 1.0)
    widgets.addAll(_positionGroup(context, gks, 0.15)); // GK
    widgets.addAll(_positionGroup(context, defs, 0.4)); // DEF
    widgets.addAll(_positionGroup(context, mids, 0.65)); // MID
    widgets.addAll(_positionGroup(context, atts, 0.85)); // ATT

    return widgets;
  }

  List<Widget> _positionGroup(
      BuildContext context, List<String> ids, double yFactor) {
    if (ids.isEmpty) return [];

    final widgets = <Widget>[];
    final spacing = 1.0 / (ids.length + 1);

    for (int i = 0; i < ids.length; i++) {
      final id = ids[i];
      final user = userMap[id];
      final player = players.firstWhere(
        (p) => p.uid == id,
        orElse: () =>
            PlayerForTeam(uid: id, rating: 0, role: PlayerRole.midfielder),
      );
      if (user == null) continue;

      final xFactor = spacing * (i + 1);

      widgets.add(
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Positioned(
                    left: constraints.maxWidth * xFactor -
                        40, // Offset for chip size
                    top: constraints.maxHeight * yFactor - 40,
                    child: _buildDraggableChip(context, user, player),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildDraggableChip(
      BuildContext context, User user, PlayerForTeam player) {
    return LongPressDraggable<String>(
      data: user.uid,
      feedback: Transform.scale(
        scale: 1.1,
        child: Material(
          color: Colors.transparent,
          child: TacticalPlayerChip(user: user, player: player),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: TacticalPlayerChip(user: user, player: player),
      ),
      child: TacticalPlayerChip(
        user: user,
        player: player,
        onTap: () => onPlayerTap(user, player, teamIndex),
      ),
    );
  }
}
