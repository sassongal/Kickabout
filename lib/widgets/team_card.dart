import 'package:flutter/material.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/logic/team_maker.dart';
import 'package:kattrick/theme/futuristic_theme.dart';
import 'package:kattrick/widgets/futuristic/futuristic_card.dart';
import 'package:kattrick/widgets/player_card.dart';

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
        : FuturisticColors.primary;
    final avgRating =
        team.playerIds.isEmpty ? 0.0 : team.totalScore / team.playerIds.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DragTarget<String>(
        onWillAccept: (playerId) {
          // Don't accept if player is already in this team
          return playerId != null && !team.playerIds.contains(playerId);
        },
        onAccept: (playerId) {
          onPlayerDropped(playerId, teamIndex);
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;

          return FuturisticCard(
            borderColor: isHovering ? FuturisticColors.primary : null,
            child: Column(
              children: [
                // Team Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        teamColor,
                        teamColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Center(
                              child: Text(
                                team.name.isNotEmpty ? team.name[0] : '?',
                                style: TextStyle(
                                  color: teamColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            team.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${team.playerIds.length} שחקנים',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            avgRating.toStringAsFixed(2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Players
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: team.playerIds.map((playerId) {
                      final user = userMap[playerId];
                      // Find player safely
                      final player = players.firstWhere(
                        (p) => p.uid == playerId,
                        orElse: () => PlayerForTeam(
                            uid: playerId,
                            rating: 0,
                            role: PlayerRole.midfielder),
                      );

                      if (user == null) return const SizedBox.shrink();

                      return _buildPlayerCard(context, user, player, teamIndex);
                    }).toList(),
                  ),
                ),

                // Drop target hint when hovering
                if (isHovering)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FuturisticColors.primary.withOpacity(0.1),
                      border: Border(
                          top: BorderSide(
                              color:
                                  FuturisticColors.primary.withOpacity(0.3))),
                    ),
                    child: Center(
                      child: Text(
                        'שחרר להעברה',
                        style: TextStyle(
                          color: FuturisticColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerCard(
      BuildContext context, User user, PlayerForTeam player, int teamIndex) {
    // Construct a Player model on the fly to use with PlayerCard widget
    final fullPlayer = Player(
      id: user.uid,
      name: user.displayName ?? user.name,
      photoUrl: user.photoUrl,
      currentRankScore: player.rating,
      attributes: PlayerAttributes(
        preferredPosition: user.preferredPosition,
      ),
      createdAt: user.createdAt,
      gamesPlayed: user.gamesPlayed,
    );

    // Draggable wrapper around the premium PlayerCard
    return LongPressDraggable<String>(
      data: user.uid,
      feedback: Transform.scale(
        scale: 1.05,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Material(
            color: Colors.transparent,
            child: PlayerCard(
              player: fullPlayer,
              showRadarChart: false,
              onTap: () => onPlayerTap(user, player, teamIndex),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: PlayerCard(
          player: fullPlayer,
          showRadarChart: false,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: PlayerCard(
          player: fullPlayer,
          showRadarChart: false,
          onTap: () => onPlayerTap(user, player, teamIndex),
        ),
      ),
    );
  }
}
