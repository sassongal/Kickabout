import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kattrick/theme/futuristic_theme.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:kattrick/utils/game_stopwatch.dart';
import 'package:kattrick/widgets/game/game_stopwatch_widget.dart';
import 'package:kattrick/utils/snackbar_helper.dart';

class GameRecordingScreen extends ConsumerStatefulWidget {
  final String hubId;
  final HubEvent event;

  const GameRecordingScreen({
    super.key,
    required this.hubId,
    required this.event,
  });

  @override
  ConsumerState<GameRecordingScreen> createState() =>
      _GameRecordingScreenState();
}

class _GameRecordingScreenState extends ConsumerState<GameRecordingScreen> {
  final List<User> _teamA = [];
  final List<User> _teamB = [];
  List<User> _unassignedPlayers = [];
  bool _isLoading = true;
  bool _gameStarted = false;
  late GameStopwatch _gameStopwatch;

  @override
  void initState() {
    super.initState();
    _gameStopwatch = GameStopwatch(
      gameId: widget.event.eventId,
      hubId: widget.hubId,
    );
    _loadPlayers();
  }

  @override
  void dispose() {
    _gameStopwatch.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      final players = <User>[];

      for (final playerId in widget.event.registeredPlayerIds) {
        final user = await usersRepo.getUser(playerId);
        if (user != null) {
          players.add(user);
        }
      }

      if (mounted) {
        setState(() {
          // _allPlayers = players; // removed unused field
          _unassignedPlayers = List.from(players);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת שחקנים: $e')),
        );
      }
    }
  }

  void _movePlayer(User player, List<User> targetList) {
    setState(() {
      _teamA.removeWhere((p) => p.uid == player.uid);
      _teamB.removeWhere((p) => p.uid == player.uid);
      _unassignedPlayers.removeWhere((p) => p.uid == player.uid);

      targetList.add(player);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FuturisticScaffold(
      title: _gameStarted ? 'תיעוד משחק - פעיל' : 'תיעוד משחקים',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _gameStarted
              ? _buildGameActiveView()
              : _buildTeamSetupView(),
    );
  }

  Widget _buildTeamSetupView() {
    return Column(
      children: [
        // Unassigned Players
        Container(
          height: 100,
          padding: const EdgeInsets.all(8),
          color: FuturisticColors.surfaceVariant.withAlpha(127),
          child: _buildPlayerList(_unassignedPlayers, 'שחקנים לא משובצים',
              isHorizontal: true),
        ),

        Expanded(
          child: Row(
            children: [
              // Team A
              Expanded(
                child: _buildTeamDropZone(
                  'קבוצה כתומה',
                  _teamA,
                  Colors.orange,
                  FuturisticColors.surface,
                ),
              ),

              // Team B
              Expanded(
                child: _buildTeamDropZone(
                  'קבוצה כחולה',
                  _teamB,
                  Colors.blue,
                  FuturisticColors.surface,
                ),
              ),
            ],
          ),
        ),

        // Actions
        if (!_gameStarted)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _teamA.isNotEmpty && _teamB.isNotEmpty
                  ? () {
                      setState(() {
                        _gameStarted = true;
                      });
                      _gameStopwatch.start();
                      SnackbarHelper.showSuccess(
                        context,
                        'המשחק התחיל! ניתן כעת להקליט אירועים',
                      );
                    }
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('התחל משחק'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FuturisticColors.success,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGameActiveView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Back to Setup Button
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('סיום משחק'),
                      content:
                          const Text('האם אתה בטוח שברצונך לסיים את המשחק?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('ביטול'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _finishGame();
                          },
                          child: const Text('סיום'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.stop),
                label: const Text('סיום משחק'),
                style: TextButton.styleFrom(
                  foregroundColor: FuturisticColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Stopwatch Widget
          Expanded(
            child: GameStopwatchWidget(
              stopwatch: _gameStopwatch,
              teamAPlayers: _teamA,
              teamBPlayers: _teamB,
              onEventsRecorded: (events) {
                // Events are automatically tracked in stopwatch
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finishGame() async {
    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);
      final eventsRepo = ref.read(eventsRepositoryProvider);

      // Get final score
      final teamAScore = _gameStopwatch.getScoreForTeam('A');
      final teamBScore = _gameStopwatch.getScoreForTeam('B');

      // Get goal scorers
      final goalScorerIds =
          _gameStopwatch.goals.map((g) => g.playerId).toSet().toList();

      // Export events
      final gameEvents = _gameStopwatch.exportAsGameEvents();

      // Create game from event
      final gameId = await gamesRepo.convertEventToGame(
        eventId: widget.event.eventId,
        hubId: widget.hubId,
        teamAScore: teamAScore,
        teamBScore: teamBScore,
        presentPlayerIds: [
          ..._teamA.map((p) => p.uid),
          ..._teamB.map((p) => p.uid)
        ],
        goalScorerIds: goalScorerIds.isNotEmpty ? goalScorerIds : null,
        mvpPlayerId: null, // TODO: Add MVP selection
      );

      // Save events to Firestore
      for (final event in gameEvents) {
        await eventsRepo.addEvent(gameId, event);
      }

      // Stop stopwatch
      _gameStopwatch.stop();

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'המשחק נשמר בהצלחה!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בשמירת המשחק: $e');
      }
    }
  }

  Widget _buildPlayerList(List<User> players, String title,
      {bool isHorizontal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(title, style: FuturisticTypography.bodySmall),
          ),
        Expanded(
          child: isHorizontal
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: players.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) =>
                      _buildDraggablePlayer(players[index]),
                )
              : ListView.separated(
                  itemCount: players.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _buildDraggablePlayer(players[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildTeamDropZone(String title, List<User> players, Color teamColor,
      Color backgroundColor) {
    return DragTarget<User>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) => _movePlayer(details.data, players),
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: candidateData.isNotEmpty ? teamColor : Colors.transparent,
              width: 2,
            ),
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: teamColor.withAlpha(25),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Text(
                  '$title (${players.length})',
                  style:
                      FuturisticTypography.heading3.copyWith(color: teamColor),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: _buildPlayerList(players, '', isHorizontal: false),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggablePlayer(User player) {
    return Draggable<User>(
      data: player,
      feedback: Material(
        color: Colors.transparent,
        child: PlayerAvatar(
          user: player,
          radius: 24,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildPlayerChip(player),
      ),
      child: _buildPlayerChip(player),
    );
  }

  Widget _buildPlayerChip(User player) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerAvatar(
            user: player,
            radius: 20,
          ),
          const SizedBox(height: 4),
          Text(
            player.displayName ?? player.firstName ?? player.name,
            style: FuturisticTypography.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
