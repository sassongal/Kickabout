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

/// Log Game Screen - Convert Event to Game (Manager only)
/// 
/// This screen allows managers to log a completed game from an event.
/// It shows:
/// - Score input (Team A vs Team B)
/// - Attendance checkboxes (default: all registered players checked)
/// - Optional highlights (Goal, Assist, MVP tags)
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
  final Map<String, Set<String>> _playerHighlights = {}; // playerId -> {goal, assist, mvp}
  bool _isLoading = false;
  bool _isSubmitting = false;
  HubEvent? _event;
  List<User> _registeredPlayers = [];

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
      
      final event = await hubEventsRepo.getHubEvent(widget.hubId, widget.eventId);
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
      
      // Initialize present players (default: all checked)
      final presentMap = <String, bool>{};
      for (final player in players) {
        presentMap[player.uid] = true; // Default: all present
      }

      if (mounted) {
        setState(() {
          _event = event;
          _registeredPlayers = players;
          _presentPlayers.addAll(presentMap);
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
          .where((e) => e.value.contains('goal') && presentPlayerIds.contains(e.key))
          .map((e) => e.key)
          .toList();
      
      final mvpPlayerId = _playerHighlights.entries
          .where((e) => e.value.contains('mvp') && presentPlayerIds.contains(e.key))
          .map((e) => e.key)
          .firstOrNull;

      // Convert event to game
      await gamesRepo.convertEventToGame(
        eventId: widget.eventId,
        hubId: widget.hubId,
        teamAScore: _teamAScore,
        teamBScore: _teamBScore,
        presentPlayerIds: presentPlayerIds,
        goalScorerIds: goalScorerIds.isNotEmpty ? goalScorerIds : null,
        mvpPlayerId: mvpPlayerId,
      );

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
                                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                                  onPressed: () => setState(() => _teamAScore++),
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
                                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                                  onPressed: () => setState(() => _teamBScore++),
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
                                player.displayName,
                                style: FuturisticTypography.bodyLarge,
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
                    ..._registeredPlayers.where((p) => _presentPlayers[p.uid] == true).map((player) {
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
                                player.displayName,
                                style: FuturisticTypography.bodyMedium,
                              ),
                            ),
                            // Goal tag
                            FilterChip(
                              label: const Text('שער'),
                              selected: _hasHighlight(player.uid, 'goal'),
                              onSelected: (selected) => _toggleHighlight(player.uid, 'goal'),
                              selectedColor: FuturisticColors.primary.withValues(alpha: 0.2),
                            ),
                            const SizedBox(width: 8),
                            // Assist tag
                            FilterChip(
                              label: const Text('אסיסט'),
                              selected: _hasHighlight(player.uid, 'assist'),
                              onSelected: (selected) => _toggleHighlight(player.uid, 'assist'),
                              selectedColor: FuturisticColors.primary.withValues(alpha: 0.2),
                            ),
                            const SizedBox(width: 8),
                            // MVP tag
                            FilterChip(
                              label: const Text('MVP'),
                              selected: _hasHighlight(player.uid, 'mvp'),
                              onSelected: (selected) => _toggleHighlight(player.uid, 'mvp'),
                              selectedColor: Colors.amber.withValues(alpha: 0.3),
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

