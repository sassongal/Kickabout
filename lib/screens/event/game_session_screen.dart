import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/futuristic/futuristic_card.dart';
import 'package:kattrick/widgets/stopwatch_widget.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/utils/stopwatch_utility.dart';
import 'package:kattrick/theme/futuristic_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Game Session Screen - Winner Stays Format
///
/// Manages a session with 3 teams where:
/// - 2 teams play at a time
/// - Winner stays, loser rotates out with waiting team
/// - Unlimited short matches
/// - Real-time stopwatch and score tracking
class GameSessionScreen extends ConsumerStatefulWidget {
  final String hubId;
  final String eventId;

  const GameSessionScreen({
    super.key,
    required this.hubId,
    required this.eventId,
  });

  @override
  ConsumerState<GameSessionScreen> createState() => _GameSessionScreenState();
}

class _GameSessionScreenState extends ConsumerState<GameSessionScreen> {
  HubEvent? _event;
  Game? _game;
  bool _isLoading = true;

  // Stopwatch state
  late final StopwatchUtility _stopwatch;

  // Current match state
  int? _teamAIndex; // Index into _game.teams (0, 1, or 2)
  int? _teamBIndex;
  int _waitingTeamIndex = 2; // Default: third team waits

  // Match scoring
  int _teamAScore = 0;
  int _teamBScore = 0;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _stopwatch = StopwatchUtility();
    _loadEventAndGame();
  }

  @override
  void dispose() {
    _stopwatch.dispose();
    super.dispose();
  }

  Future<void> _loadEventAndGame() async {
    setState(() => _isLoading = true);

    try {
      final eventsRepo = ref.read(hubEventsRepositoryProvider);
      final event = await eventsRepo.getHubEvent(widget.hubId, widget.eventId);

      if (event == null || event.gameId == null) {
        throw Exception('אירוע או משחק לא נמצא');
      }

      final gamesRepo = ref.read(gamesRepositoryProvider);
      final game = await gamesRepo.getGame(event.gameId!);

      if (mounted) {
        setState(() {
          _event = event;
          _game = game;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _selectTeamsForMatch() async {
    if (_game == null || _game!.teams.length < 3) return;

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _SelectTeamsDialog(teams: _game!.teams),
    );

    if (result != null) {
      setState(() {
        _teamAIndex = result['teamA']!;
        _teamBIndex = result['teamB']!;
        // Find waiting team
        _waitingTeamIndex = [0, 1, 2].firstWhere(
          (i) => i != _teamAIndex && i != _teamBIndex,
        );
        _teamAScore = 0;
        _teamBScore = 0;
        _stopwatch.reset();
      });
    }
  }

  Future<void> _logGoal(int teamIndex) async {
    setState(() {
      if (teamIndex == _teamAIndex) {
        _teamAScore++;
      } else if (teamIndex == _teamBIndex) {
        _teamBScore++;
      }
    });
  }

  Future<void> _finishMatch() async {
    if (_teamAIndex == null || _teamBIndex == null || _game == null) return;

    _stopwatch.stop();

    // Determine winner
    int? winnerIndex;
    if (_teamAScore > _teamBScore) {
      winnerIndex = _teamAIndex;
    } else if (_teamBScore > _teamAScore) {
      winnerIndex = _teamBIndex;
    }

    setState(() => _isSubmitting = true);

    try {
      final teamA = _game!.teams[_teamAIndex!];
      final teamB = _game!.teams[_teamBIndex!];

      // Create match result
      final firestore = FirebaseFirestore.instance;
      final matchId = firestore.collection('temp').doc().id;

      final match = MatchResult(
        matchId: matchId,
        teamAColor: teamA.color ?? teamA.name,
        teamBColor: teamB.color ?? teamB.name,
        scoreA: _teamAScore,
        scoreB: _teamBScore,
        scorerIds: [], // Simplified - can be enhanced later
        assistIds: [],
        createdAt: DateTime.now(),
        loggedBy: ref.read(currentUserIdProvider)!,
      );

      // Submit to game session
      final gamesRepo = ref.read(gamesRepositoryProvider);
      await gamesRepo.addMatchToSession(
        _game!.gameId,
        match,
        ref.read(currentUserIdProvider)!,
      );

      // Reload to get updated aggregate wins
      await _loadEventAndGame();

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'תוצאה נרשמה!');

        // Show Winner Stays rotation
        if (winnerIndex != null) {
          final winnerTeam = _game!.teams[winnerIndex];
          final loserIndex =
              (winnerIndex == _teamAIndex) ? _teamBIndex : _teamAIndex;

          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(winnerTeam.colorValue ?? 0xFF2196F3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${winnerTeam.name} מנצח!')),
                ],
              ),
              content: Text(
                'הקבוצה המנצחת נשארת על המגרש.\n'
                '${_game!.teams[loserIndex!].name} מחליפה את ${_game!.teams[_waitingTeamIndex].name}',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Set up next match: winner + waiting team
                    setState(() {
                      _teamAIndex = winnerIndex;
                      _teamBIndex = _waitingTeamIndex;
                      _waitingTeamIndex = loserIndex;
                      _teamAScore = 0;
                      _teamBScore = 0;
                      _stopwatch.reset();
                      if (_stopwatch.isRunning) {
                        _stopwatch.stop();
                      }
                    });
                  },
                  child: const Text('משחק הבא'),
                ),
              ],
            ),
          );
        } else {
          // Draw - ask which team rotates
          final selectedTeam = await showDialog<int>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('תיקו - בחר קבוצה להחלפה'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(teamA.colorValue ?? 0xFF2196F3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(teamA.name),
                    onTap: () => Navigator.pop(context, _teamAIndex),
                  ),
                  ListTile(
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(teamB.colorValue ?? 0xFF2196F3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(teamB.name),
                    onTap: () => Navigator.pop(context, _teamBIndex),
                  ),
                ],
              ),
            ),
          );

          if (selectedTeam != null) {
            final stayingTeam =
                (selectedTeam == _teamAIndex) ? _teamBIndex : _teamAIndex;
            setState(() {
              _teamAIndex = stayingTeam;
              _teamBIndex = _waitingTeamIndex;
              _waitingTeamIndex = selectedTeam;
              _teamAScore = 0;
              _teamBScore = 0;
              _stopwatch.reset();
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppScaffold(
        title: 'משחק',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null || _game == null) {
      return AppScaffold(
        title: 'משחק',
        body: const Center(child: Text('משחק לא נמצא')),
      );
    }

    return AppScaffold(
      title: _event!.title,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aggregate Wins Scoreboard
            FuturisticCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'תוצאות מצטברות',
                      style: FuturisticTypography.techHeadline.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._game!.teams.map((team) {
                      final wins = _game!
                              .session.aggregateWins[team.color ?? team.name] ??
                          0;
                      final colorValue = team.colorValue ?? 0xFF2196F3;
                      final maxWins =
                          _game!.session.aggregateWins.values.isEmpty
                              ? 1
                              : _game!.session.aggregateWins.values
                                  .reduce((a, b) => a > b ? a : b);
                      final percentage = maxWins > 0 ? (wins / maxWins) : 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
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
                                      team.color ?? team.name,
                                      style: FuturisticTypography.bodyLarge
                                          .copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '$wins ניצחונות',
                                  style: FuturisticTypography.heading2,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: percentage,
                                minHeight: 24,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(colorValue),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stopwatch
            FuturisticCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: StopwatchWidget(
                  stopwatch: _stopwatch,
                  accentColor: FuturisticColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Current Match or Team Selection
            if (_teamAIndex != null && _teamBIndex != null) ...[
              FuturisticCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'משחק נוכחי',
                        style: FuturisticTypography.techHeadline.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Team A
                          _buildTeamScore(_game!.teams[_teamAIndex!],
                              _teamAScore, _teamAIndex!),
                          Text(
                            'VS',
                            style: FuturisticTypography.heading1.copyWith(
                              color: FuturisticColors.textSecondary,
                            ),
                          ),
                          // Team B
                          _buildTeamScore(_game!.teams[_teamBIndex!],
                              _teamBScore, _teamBIndex!),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _finishMatch,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check),
                          label: Text(_isSubmitting ? 'שומר...' : 'סיום משחק'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: FuturisticColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Waiting team indicator
              FuturisticCard(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        color: FuturisticColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ממתין: ${_game!.teams[_waitingTeamIndex].name}',
                        style: FuturisticTypography.bodyMedium.copyWith(
                          color: FuturisticColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectTeamsForMatch,
                  icon: const Icon(Icons.sports_soccer),
                  label: const Text('בחר קבוצות למשחק'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: FuturisticColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Recent matches
            if (_game!.session.matches.isNotEmpty) ...[
              FuturisticCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'משחקים אחרונים (${_game!.session.matches.length})',
                        style: FuturisticTypography.techHeadline.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._game!.session.matches.reversed.take(5).map((match) {
                        final teamAColor = _game!.teams
                            .firstWhere(
                              (t) => (t.color ?? t.name) == match.teamAColor,
                              orElse: () => _game!.teams.first,
                            )
                            .colorValue;
                        final teamBColor = _game!.teams
                            .firstWhere(
                              (t) => (t.color ?? t.name) == match.teamBColor,
                              orElse: () => _game!.teams.first,
                            )
                            .colorValue;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Color(teamAColor ?? 0xFF2196F3),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(match.teamAColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${match.scoreA}',
                                    style: FuturisticTypography.heading2,
                                  ),
                                ],
                              ),
                              Text(
                                'VS',
                                style: FuturisticTypography.bodyMedium.copyWith(
                                  color: FuturisticColors.textSecondary,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${match.scoreB}',
                                    style: FuturisticTypography.heading2,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(match.teamBColor),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Color(teamBColor ?? 0xFF2196F3),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamScore(Team team, int score, int teamIndex) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Color(team.colorValue ?? 0xFF2196F3),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          team.name,
          style: FuturisticTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$score',
          style: FuturisticTypography.heading1.copyWith(fontSize: 48),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _logGoal(teamIndex),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('גול'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(team.colorValue ?? 0xFF2196F3),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SelectTeamsDialog extends StatefulWidget {
  final List<Team> teams;

  const _SelectTeamsDialog({required this.teams});

  @override
  State<_SelectTeamsDialog> createState() => _SelectTeamsDialogState();
}

class _SelectTeamsDialogState extends State<_SelectTeamsDialog> {
  int? _selectedTeamA;
  int? _selectedTeamB;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('בחר 2 קבוצות למשחק'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.teams.asMap().entries.map((entry) {
          final index = entry.key;
          final team = entry.value;
          final isSelected = _selectedTeamA == index || _selectedTeamB == index;

          return CheckboxListTile(
            value: isSelected,
            onChanged: isSelected
                ? (_) {
                    setState(() {
                      if (_selectedTeamA == index) _selectedTeamA = null;
                      if (_selectedTeamB == index) _selectedTeamB = null;
                    });
                  }
                : (_) {
                    setState(() {
                      if (_selectedTeamA == null) {
                        _selectedTeamA = index;
                      } else {
                        _selectedTeamB ??= index;
                      }
                    });
                  },
            title: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(team.colorValue ?? 0xFF2196F3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(team.name),
              ],
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ביטול'),
        ),
        ElevatedButton(
          onPressed: _selectedTeamA != null && _selectedTeamB != null
              ? () => Navigator.pop(context, {
                    'teamA': _selectedTeamA!,
                    'teamB': _selectedTeamB!,
                  })
              : null,
          child: const Text('התחל משחק'),
        ),
      ],
    );
  }
}
