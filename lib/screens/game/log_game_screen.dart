import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_card.dart';
import 'package:kickadoor/widgets/player_avatar.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Log Game Screen - "The Session Dashboard" (Manager only)
///
/// This screen supports TWO modes:
/// 1. **Session Mode** (Multi-Match): If event has teams with colors
///    - Shows aggregate wins scoreboard (Blue: 6, Red: 4, Green: 2)
///    - "Log Match Result" button to record individual matches
///    - Attendance list
/// 2. **Single Game Mode**: If no teams or teams without colors
///    - Traditional Team A vs Team B score input
///    - Attendance and highlights
///
/// When "Finish & Log" is clicked, it calls GamesRepository.convertEventToGame()
/// which creates a Game document and triggers the Cloud Function to update stats.
class LogGameScreen extends ConsumerStatefulWidget {
  final String hubId;
  final String eventId;

  const LogGameScreen({
    super.key,
    required this.hubId,
    required this.eventId,
  });

  @override
  ConsumerState<LogGameScreen> createState() => _LogGameScreenState();
}

class _LogGameScreenState extends ConsumerState<LogGameScreen> {
  int _teamAScore = 0;
  int _teamBScore = 0;
  final Map<String, bool> _presentPlayers = {}; // playerId -> isPresent
  final Map<String, Set<String>> _playerHighlights =
      {}; // playerId -> {goal, assist, mvp}
  final Map<String, bool> _paidPlayers =
      {}; // playerId -> isPaid (for payment tracking)
  bool _isLoading = false;
  bool _isSubmitting = false;
  HubEvent? _event;
  List<User> _registeredPlayers = [];
  Hub? _hub; // For payment link

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() => _isLoading = true);
    try {
      final hubEventsRepo = ref.read(hubEventsRepositoryProvider);
      final usersRepo = ref.read(usersRepositoryProvider);

      final event =
          await hubEventsRepo.getHubEvent(widget.hubId, widget.eventId);
      if (event == null) {
        if (mounted) {
          SnackbarHelper.showError(context, 'אירוע לא נמצא');
          context.pop();
        }
        return;
      }

      // Check if event already has a game
      if (event.gameId != null && event.gameId!.isNotEmpty) {
        if (mounted) {
          SnackbarHelper.showError(context, 'המשחק כבר נרשם');
          context.pop();
        }
        return;
      }

      // Load registered players
      final players = await usersRepo.getUsers(event.registeredPlayerIds);

      // Load hub for payment link
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final hub = await hubsRepo.getHub(widget.hubId);

      // Initialize present players (default: all checked)
      final presentMap = <String, bool>{};
      final paidMap = <String, bool>{};
      for (final player in players) {
        presentMap[player.uid] = true; // Default: all present
        paidMap[player.uid] = false; // Default: not paid
      }

      if (mounted) {
        setState(() {
          _event = event;
          _hub = hub;
          _registeredPlayers = players;
          _presentPlayers.addAll(presentMap);
          _paidPlayers.addAll(paidMap);
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

  void _togglePlayerPresence(String playerId) {
    setState(() {
      _presentPlayers[playerId] = !(_presentPlayers[playerId] ?? false);
    });
  }

  void _toggleHighlight(String playerId, String highlight) {
    setState(() {
      _playerHighlights.putIfAbsent(playerId, () => <String>{});
      if (_playerHighlights[playerId]!.contains(highlight)) {
        _playerHighlights[playerId]!.remove(highlight);
      } else {
        _playerHighlights[playerId]!.add(highlight);
      }
    });
  }

  bool _hasHighlight(String playerId, String highlight) {
    return _playerHighlights[playerId]?.contains(highlight) ?? false;
  }

  Future<void> _submitGame() async {
    if (_event == null) return;

    // Validate: at least one team must have players
    final presentPlayerIds = _presentPlayers.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (presentPlayerIds.isEmpty) {
      SnackbarHelper.showError(context, 'יש לבחור לפחות שחקן אחד נוכח');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);

      // Extract goal scorers and MVP
      final goalScorerIds = _playerHighlights.entries
          .where((e) =>
              e.value.contains('goal') && presentPlayerIds.contains(e.key))
          .map((e) => e.key)
          .toList();

      final mvpPlayerId = _playerHighlights.entries
          .where((e) =>
              e.value.contains('mvp') && presentPlayerIds.contains(e.key))
          .map((e) => e.key)
          .firstOrNull;

      // Convert event to game
      // In Session Mode, we need to pass aggregateWins and matches
      if (_isSessionMode) {
        // For Session Mode, we'll need to update convertEventToGame to accept these
        // For now, we'll use a workaround: update the game after creation
        final gameId = await gamesRepo.convertEventToGame(
          eventId: widget.eventId,
          hubId: widget.hubId,
          teamAScore:
              _teamAScore, // Final score (can be 0-0 if using aggregateWins)
          teamBScore: _teamBScore,
          presentPlayerIds: presentPlayerIds,
          goalScorerIds: goalScorerIds.isNotEmpty ? goalScorerIds : null,
          mvpPlayerId: mvpPlayerId,
        );

        // Update game with session data
        await gamesRepo.updateGame(gameId, {
          'aggregateWins': _event!.aggregateWins,
          'matches': _event!.matches.map((m) => m.toJson()).toList(),
        });
      } else {
        // Single Game Mode - normal flow
        await gamesRepo.convertEventToGame(
          eventId: widget.eventId,
          hubId: widget.hubId,
          teamAScore: _teamAScore,
          teamBScore: _teamBScore,
          presentPlayerIds: presentPlayerIds,
          goalScorerIds: goalScorerIds.isNotEmpty ? goalScorerIds : null,
          mvpPlayerId: mvpPlayerId,
        );
      }

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'המשחק נרשם בהצלחה!');
        context.pop(); // Return to events tab
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
        setState(() => _isSubmitting = false);
      }
    }
  }

  // Check if event has teams with colors (Session Mode)
  bool get _isSessionMode {
    if (_event == null) return false;
    return _event!.teams.isNotEmpty &&
        _event!.teams
            .any((team) => team.color != null && team.color!.isNotEmpty);
  }

  Future<void> _logMatchResult() async {
    if (_event == null || _event!.teams.isEmpty) {
      SnackbarHelper.showError(context, 'אין קבוצות מוגדרות לאירוע');
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _LogMatchDialog(event: _event!),
    );

    if (result == null) return;

    setState(() => _isSubmitting = true);

    try {
      final hubEventsRepo = ref.read(hubEventsRepositoryProvider);
      final firestore = FirebaseFirestore.instance;
      final currentUserId = ref.read(currentUserIdProvider);

      if (currentUserId == null) {
        throw Exception('משתמש לא מחובר');
      }

      final teamAColor = result['teamAColor'] as String;
      final teamBColor = result['teamBColor'] as String;
      final scoreA = result['scoreA'] as int;
      final scoreB = result['scoreB'] as int;

      // Determine winner
      String? winnerColor;
      if (scoreA > scoreB) {
        winnerColor = teamAColor;
      } else if (scoreB > scoreA) {
        winnerColor = teamBColor;
      }

      // Create match result
      final matchId = firestore.collection('temp').doc().id;
      final matchResult = MatchResult(
        matchId: matchId,
        teamAColor: teamAColor,
        teamBColor: teamBColor,
        scoreA: scoreA,
        scoreB: scoreB,
        createdAt: DateTime.now(),
        loggedBy: currentUserId,
      );

      // Update aggregate wins
      final currentWins = Map<String, int>.from(_event!.aggregateWins);
      if (winnerColor != null) {
        currentWins[winnerColor] = (currentWins[winnerColor] ?? 0) + 1;
      }

      // Add match to list
      final updatedMatches = List<MatchResult>.from(_event!.matches)
        ..add(matchResult);

      // Update event
      await hubEventsRepo.updateHubEvent(
        widget.hubId,
        widget.eventId,
        {
          'matches': updatedMatches.map((m) => m.toJson()).toList(),
          'aggregateWins': currentWins,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Reload event
      await _loadEvent();

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'תוצאה נרשמה בהצלחה!');
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
        title: 'רישום משחק',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return AppScaffold(
        title: 'רישום משחק',
        body: const Center(child: Text('אירוע לא נמצא')),
      );
    }

    // If Session Mode, show Session Dashboard
    if (_isSessionMode) {
      return _buildSessionDashboard(context);
    }

    // Otherwise, show Single Game Mode
    return _buildSingleGameMode(context);
  }

  Widget _buildSessionDashboard(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'he');

    return AppScaffold(
      title: _event!.title,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event info
            FuturisticCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _event!.title,
                            style: FuturisticTypography.techHeadline.copyWith(
                              fontSize: 20,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'מפגש פעיל',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: FuturisticColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(_event!.eventDate),
                          style: FuturisticTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

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
                    if (_event!.aggregateWins.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('עדיין לא נרשמו תוצאות'),
                        ),
                      )
                    else
                      ..._event!.teams.map((team) {
                        final wins =
                            _event!.aggregateWins[team.color ?? ''] ?? 0;
                        final colorValue = team.colorValue ?? 0xFF2196F3;
                        final maxWins = _event!.aggregateWins.values.isEmpty
                            ? 1
                            : _event!.aggregateWins.values
                                .reduce((a, b) => a > b ? a : b);
                        final percentage = maxWins > 0 ? (wins / maxWins) : 0.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                              color: Colors.white, width: 2),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          team.color ?? team.name,
                                          style: FuturisticTypography.bodyLarge
                                              .copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
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
                                      Color(colorValue)),
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

            // Log Match Result Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _logMatchResult,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_isSubmitting ? 'שומר...' : 'רישום תוצאה'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: FuturisticColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recent Matches
            if (_event!.matches.isNotEmpty) ...[
              FuturisticCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'משחקים אחרונים',
                        style: FuturisticTypography.techHeadline.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._event!.matches.reversed.take(10).map((match) {
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
                                      color: _getColorForTeam(match.teamAColor),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      match.teamAColor,
                                      style: FuturisticTypography.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
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
                                  Flexible(
                                    child: Text(
                                      match.teamBColor,
                                      style: FuturisticTypography.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _getColorForTeam(match.teamBColor),
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
              const SizedBox(height: 24),
            ],

            // Attendance
            FuturisticCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'נוכחות',
                      style: FuturisticTypography.techHeadline.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._registeredPlayers.map((player) {
                      final isPresent = _presentPlayers[player.uid] ?? false;
                      final isPaid = _paidPlayers[player.uid] ?? false;
                      return CheckboxListTile(
                        value: isPresent,
                        onChanged: (value) => _togglePlayerPresence(player.uid),
                        title: Row(
                          children: [
                            PlayerAvatar(
                              user: player,
                              radius: 16,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                player.displayName ?? '',
                                style: FuturisticTypography.bodyLarge,
                              ),
                            ),
                            // Payment toggle (only if hub has payment link)
                            if (_hub?.paymentLink != null &&
                                _hub!.paymentLink!.isNotEmpty)
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _paidPlayers[player.uid] = !isPaid;
                                  });
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isPaid ? Colors.green : Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: Icon(
                                    isPaid ? Icons.check : Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        activeColor: FuturisticColors.primary,
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Finish Session Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitGame,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(_isSubmitting ? 'שומר...' : 'סיים מפגש'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForTeam(String? colorName) {
    if (colorName == null) return Colors.grey;

    final team = _event?.teams.firstWhere(
      (t) => t.color == colorName,
      orElse: () => Team(teamId: '', name: '', colorValue: 0xFF2196F3),
    );

    return Color(team?.colorValue ?? 0xFF2196F3);
  }

  Widget _buildSingleGameMode(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'he');

    return AppScaffold(
      title: 'רישום משחק',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event info card
            FuturisticCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _event!.title,
                      style: FuturisticTypography.techHeadline.copyWith(
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: FuturisticColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(_event!.eventDate),
                          style: FuturisticTypography.bodyMedium,
                        ),
                      ],
                    ),
                    if (_event!.location != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: FuturisticColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _event!.location!,
                              style: FuturisticTypography.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Score input
            FuturisticCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'תוצאה',
                      style: FuturisticTypography.techHeadline.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Team A
                        Column(
                          children: [
                            Text(
                              'קבוצה א',
                              style: FuturisticTypography.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: _teamAScore > 0
                                      ? () => setState(() => _teamAScore--)
                                      : null,
                                  color: FuturisticColors.primary,
                                ),
                                Container(
                                  width: 60,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: FuturisticColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$_teamAScore',
                                    textAlign: TextAlign.center,
                                    style: FuturisticTypography.heading2,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () =>
                                      setState(() => _teamAScore++),
                                  color: FuturisticColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                        // VS
                        Text(
                          'VS',
                          style: FuturisticTypography.heading2.copyWith(
                            color: FuturisticColors.textSecondary,
                          ),
                        ),
                        // Team B
                        Column(
                          children: [
                            Text(
                              'קבוצה ב',
                              style: FuturisticTypography.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: _teamBScore > 0
                                      ? () => setState(() => _teamBScore--)
                                      : null,
                                  color: FuturisticColors.primary,
                                ),
                                Container(
                                  width: 60,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: FuturisticColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$_teamBScore',
                                    textAlign: TextAlign.center,
                                    style: FuturisticTypography.heading2,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () =>
                                      setState(() => _teamBScore++),
                                  color: FuturisticColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Attendance
            FuturisticCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'נוכחות',
                      style: FuturisticTypography.techHeadline.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._registeredPlayers.map((player) {
                      final isPresent = _presentPlayers[player.uid] ?? false;
                      final isPaid = _paidPlayers[player.uid] ?? false;
                      return CheckboxListTile(
                        value: isPresent,
                        onChanged: (value) => _togglePlayerPresence(player.uid),
                        title: Row(
                          children: [
                            PlayerAvatar(
                              user: player,
                              radius: 16,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                player.displayName ?? '',
                                style: FuturisticTypography.bodyLarge,
                              ),
                            ),
                            // Payment toggle (only if hub has payment link)
                            if (_hub?.paymentLink != null &&
                                _hub!.paymentLink!.isNotEmpty)
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _paidPlayers[player.uid] = !isPaid;
                                  });
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isPaid ? Colors.green : Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: Icon(
                                    isPaid ? Icons.check : Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        activeColor: FuturisticColors.primary,
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Highlights (optional)
            FuturisticCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'הישגים (אופציונלי)',
                      style: FuturisticTypography.techHeadline.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._registeredPlayers
                        .where((p) => _presentPlayers[p.uid] == true)
                        .map((player) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            PlayerAvatar(
                              user: player,
                              radius: 16,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                player.displayName ?? '',
                                style: FuturisticTypography.bodyMedium,
                              ),
                            ),
                            // Goal tag
                            FilterChip(
                              label: const Text('שער'),
                              selected: _hasHighlight(player.uid, 'goal'),
                              onSelected: (selected) =>
                                  _toggleHighlight(player.uid, 'goal'),
                              selectedColor: FuturisticColors.primary
                                  .withValues(alpha: 0.2),
                            ),
                            const SizedBox(width: 8),
                            // Assist tag
                            FilterChip(
                              label: const Text('אסיסט'),
                              selected: _hasHighlight(player.uid, 'assist'),
                              onSelected: (selected) =>
                                  _toggleHighlight(player.uid, 'assist'),
                              selectedColor: FuturisticColors.primary
                                  .withValues(alpha: 0.2),
                            ),
                            const SizedBox(width: 8),
                            // MVP tag
                            FilterChip(
                              label: const Text('MVP'),
                              selected: _hasHighlight(player.uid, 'mvp'),
                              onSelected: (selected) =>
                                  _toggleHighlight(player.uid, 'mvp'),
                              selectedColor:
                                  Colors.amber.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitGame,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(_isSubmitting ? 'שומר...' : 'סיים ורשום משחק'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: FuturisticColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Dialog for logging a match result (used in Session Mode)
class _LogMatchDialog extends StatefulWidget {
  final HubEvent event;

  const _LogMatchDialog({required this.event});

  @override
  State<_LogMatchDialog> createState() => _LogMatchDialogState();
}

class _LogMatchDialogState extends State<_LogMatchDialog> {
  String? _selectedTeamA;
  String? _selectedTeamB;
  int _scoreA = 0;
  int _scoreB = 0;

  @override
  void initState() {
    super.initState();
    if (widget.event.teams.isNotEmpty) {
      _selectedTeamA =
          widget.event.teams[0].color ?? widget.event.teams[0].name;
      if (widget.event.teams.length > 1) {
        _selectedTeamB =
            widget.event.teams[1].color ?? widget.event.teams[1].name;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('רישום תוצאה'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Team A selection
            DropdownButtonFormField<String>(
              initialValue: _selectedTeamA,
              decoration: const InputDecoration(
                labelText: 'קבוצה א',
                border: OutlineInputBorder(),
              ),
              items: widget.event.teams.map((team) {
                final colorName = team.color ?? team.name;
                return DropdownMenuItem(
                  value: colorName,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Color(team.colorValue ?? 0xFF2196F3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(colorName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedTeamA = value),
            ),
            const SizedBox(height: 16),
            // Team B selection
            DropdownButtonFormField<String>(
              initialValue: _selectedTeamB,
              decoration: const InputDecoration(
                labelText: 'קבוצה ב',
                border: OutlineInputBorder(),
              ),
              items: widget.event.teams.where((team) {
                final colorName = team.color ?? team.name;
                return colorName != _selectedTeamA;
              }).map((team) {
                final colorName = team.color ?? team.name;
                return DropdownMenuItem(
                  value: colorName,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Color(team.colorValue ?? 0xFF2196F3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(colorName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedTeamB = value),
            ),
            const SizedBox(height: 24),
            // Score input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Score A
                Column(
                  children: [
                    const Text('קבוצה א'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _scoreA > 0
                              ? () => setState(() => _scoreA--)
                              : null,
                        ),
                        Container(
                          width: 60,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_scoreA',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => _scoreA++),
                        ),
                      ],
                    ),
                  ],
                ),
                const Text('VS'),
                // Score B
                Column(
                  children: [
                    const Text('קבוצה ב'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _scoreB > 0
                              ? () => setState(() => _scoreB--)
                              : null,
                        ),
                        Container(
                          width: 60,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_scoreB',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => _scoreB++),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ביטול'),
        ),
        ElevatedButton(
          onPressed: _selectedTeamA != null && _selectedTeamB != null
              ? () => Navigator.pop(
                    context,
                    {
                      'teamAColor': _selectedTeamA,
                      'teamBColor': _selectedTeamB,
                      'scoreA': _scoreA,
                      'scoreB': _scoreB,
                    },
                  )
              : null,
          child: const Text('שמור'),
        ),
      ],
    );
  }
}
