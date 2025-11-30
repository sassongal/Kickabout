import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/utils/game_stopwatch.dart';
import 'package:kattrick/utils/stopwatch_utility.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:kattrick/theme/futuristic_theme.dart';

/// Widget for displaying and controlling game stopwatch
/// 
/// Features:
/// - Large stopwatch display
/// - Start/Pause/Stop controls
/// - Quick goal recording buttons
/// - Event list
/// - Score display
class GameStopwatchWidget extends ConsumerStatefulWidget {
  final GameStopwatch stopwatch;
  final List<User> teamAPlayers;
  final List<User> teamBPlayers;
  final Function(List<GameEvent>)? onEventsRecorded;

  const GameStopwatchWidget({
    super.key,
    required this.stopwatch,
    required this.teamAPlayers,
    required this.teamBPlayers,
    this.onEventsRecorded,
  });

  @override
  ConsumerState<GameStopwatchWidget> createState() =>
      _GameStopwatchWidgetState();
}

class _GameStopwatchWidgetState extends ConsumerState<GameStopwatchWidget> {

  @override
  void initState() {
    super.initState();
    widget.stopwatch.addListener(_onStopwatchUpdate);
  }

  @override
  void dispose() {
    widget.stopwatch.removeListener(_onStopwatchUpdate);
    super.dispose();
  }

  void _onStopwatchUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _recordGoal(String team, String playerId, String playerName) {
    widget.stopwatch.recordGoal(
      playerId: playerId,
      playerName: playerName,
      team: team,
    );
    _notifyEventsRecorded();
  }

  // Assist recording will be added in future update
  // void _recordAssist(String team, String playerId, String playerName) {
  //   // Find the last goal for this team
  //   final lastGoal = widget.stopwatch.goals
  //       .where((g) => g.team == team)
  //       .lastOrNull;
  //
  //   if (lastGoal != null) {
  //     widget.stopwatch.recordAssist(
  //       playerId: playerId,
  //       playerName: playerName,
  //       team: team,
  //       goalPlayerId: lastGoal.playerId,
  //       goalPlayerName: lastGoal.playerName,
  //     );
  //     _notifyEventsRecorded();
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('יש להקליד שער לפני בישול'),
  //       ),
  //     );
  //   }
  // }

  void _notifyEventsRecorded() {
    if (widget.onEventsRecorded != null) {
      widget.onEventsRecorded!(widget.stopwatch.exportAsGameEvents());
    }
  }

  @override
  Widget build(BuildContext context) {
    final stopwatch = widget.stopwatch;
    final teamAScore = stopwatch.getScoreForTeam('A');
    final teamBScore = stopwatch.getScoreForTeam('B');

    return Column(
      children: [
        // Stopwatch Display
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: FuturisticColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Time Display
              Text(
                StopwatchUtility.formatMMSS(stopwatch.elapsed),
                style: FuturisticTypography.heading1.copyWith(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: FuturisticColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              // Score Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildScoreDisplay('A', teamAScore, Colors.orange),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '-',
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                  _buildScoreDisplay('B', teamBScore, Colors.blue),
                ],
              ),
              const SizedBox(height: 16),
              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!stopwatch.isRunning && !stopwatch.isPaused)
                    ElevatedButton.icon(
                      onPressed: () => stopwatch.start(),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('התחל'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FuturisticColors.success,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else if (stopwatch.isRunning)
                    ElevatedButton.icon(
                      onPressed: () => stopwatch.pause(),
                      icon: const Icon(Icons.pause),
                      label: const Text('השהה'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FuturisticColors.warning,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else if (stopwatch.isPaused)
                    ElevatedButton.icon(
                      onPressed: () => stopwatch.resume(),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('המשך'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FuturisticColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('איפוס סטופר'),
                          content: const Text('האם אתה בטוח שברצונך לאפס את הסטופר? כל האירועים יימחקו.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('ביטול'),
                            ),
                            TextButton(
                              onPressed: () {
                                stopwatch.reset();
                                Navigator.pop(context);
                              },
                              child: const Text('איפוס'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('איפוס'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FuturisticColors.error,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Quick Goal Recording
        if (stopwatch.isRunning || stopwatch.isPaused) ...[
          _buildQuickGoalSection('A', widget.teamAPlayers, Colors.orange),
          const SizedBox(height: 8),
          _buildQuickGoalSection('B', widget.teamBPlayers, Colors.blue),
          const SizedBox(height: 16),
        ],

        // Events List
        Expanded(
          child: _buildEventsList(),
        ),
      ],
    );
  }

  Widget _buildScoreDisplay(String team, int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(
            'קבוצה $team',
            style: FuturisticTypography.labelSmall,
          ),
          Text(
            score.toString(),
            style: FuturisticTypography.heading2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickGoalSection(String team, List<User> players, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'קבוצה $team - הקלטת שער',
            style: FuturisticTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: players.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final player = players[index];
                return InkWell(
                  onTap: () => _recordGoal(team, player.uid, player.displayName ?? player.name),
                  child: Container(
                    width: 70,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: FuturisticColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlayerAvatar(user: player, radius: 20),
                        const SizedBox(height: 4),
                        Text(
                          player.displayName ?? player.name,
                          style: FuturisticTypography.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    final events = widget.stopwatch.events;

    if (events.isEmpty) {
      return Center(
        child: Text(
          'אין אירועים עדיין',
          style: FuturisticTypography.bodyMedium,
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[events.length - 1 - index]; // Reverse order
        return _buildEventItem(event);
      },
    );
  }

  Widget _buildEventItem(GameEventRecord event) {
    final teamColor = event.team == 'A' ? Colors.orange : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FuturisticColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: teamColor.withAlpha(100), width: 1),
      ),
      child: Row(
        children: [
          // Time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: teamColor.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              event.formattedTime,
              style: FuturisticTypography.labelSmall.copyWith(
                color: teamColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Event Type Icon
          Icon(
            event.type == EventType.goal
                ? Icons.sports_soccer
                : event.type == EventType.assist
                    ? Icons.assistant
                    : Icons.info,
            color: teamColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          // Player Name
          Expanded(
            child: Text(
              '${event.playerName} - ${event.typeDisplayName}',
              style: FuturisticTypography.bodyMedium,
            ),
          ),
          // Delete Button
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: FuturisticColors.error,
            onPressed: () {
              widget.stopwatch.removeEvent(event);
              _notifyEventsRecorded();
            },
          ),
        ],
      ),
    );
  }
}

