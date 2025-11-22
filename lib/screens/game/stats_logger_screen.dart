import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/widgets/whatsapp_share_button.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/models/hub_role.dart';
import 'package:kickadoor/utils/recap_generator.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
// Removed: import 'package:kickadoor/services/gamification_service.dart';
// Gamification is now handled by Cloud Function onGameCompleted
import 'package:kickadoor/core/constants.dart';
import 'package:kickadoor/widgets/optimized_image.dart';

/// Stats logger screen for gameday events
class StatsLoggerScreen extends ConsumerStatefulWidget {
  final String gameId;

  const StatsLoggerScreen({super.key, required this.gameId});

  @override
  ConsumerState<StatsLoggerScreen> createState() => _StatsLoggerScreenState();
}

class _StatsLoggerScreenState extends ConsumerState<StatsLoggerScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  DateTime? _gameStartTime;
  bool _isPaused = true;
  String? _recapText;
  final _teamAScoreController = TextEditingController();
  final _teamBScoreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecap();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _teamAScoreController.dispose();
    _teamBScoreController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _gameStartTime ??= DateTime.now();
    _isPaused = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(_gameStartTime!);
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _isPaused = true;
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _elapsed = Duration.zero;
      _gameStartTime = null;
      _isPaused = true;
    });
  }

  int _getCurrentMinute() {
    if (_gameStartTime == null) return 0;
    return _elapsed.inMinutes;
  }

  Future<void> _addEvent(EventType eventType, String playerId) async {
    try {
      final eventsRepo = ref.read(eventsRepositoryProvider);
      final event = GameEvent(
        eventId: '',
        type: eventType,
        playerId: playerId,
        timestamp: DateTime.now(),
        metadata: {
          'minute': _getCurrentMinute(),
        },
      );

      await eventsRepo.addEvent(widget.gameId, event);
      _loadRecap(); // Refresh recap
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בהוספת אירוע: $e')),
        );
      }
    }
  }

  Future<void> _loadRecap() async {
    try {
      final eventsRepo = ref.read(eventsRepositoryProvider);
      final usersRepo = ref.read(usersRepositoryProvider);
      final teamsRepo = ref.read(teamsRepositoryProvider);
      final gamesRepo = ref.read(gamesRepositoryProvider);
      
      final recap = await RecapGenerator.generateNarrativeRecap(
        widget.gameId,
        eventsRepo,
        usersRepo,
        teamsRepo,
        gamesRepo,
      );
      if (mounted) {
        setState(() {
          _recapText = recap;
        });
      }
    } catch (e) {
      // Fallback to simple recap if narrative fails
      try {
        final eventsRepo = ref.read(eventsRepositoryProvider);
        final usersRepo = ref.read(usersRepositoryProvider);
        final recap = await RecapGenerator.generateRecap(
          widget.gameId,
          eventsRepo,
          usersRepo,
        );
        if (mounted) {
          setState(() {
            _recapText = recap;
          });
        }
      } catch (e2) {
        // Ignore errors in recap loading
      }
    }
  }

  Future<void> _endGame() async {
    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);
      final eventsRepo = ref.read(eventsRepositoryProvider);
      final teamsRepo = ref.read(teamsRepositoryProvider);
      final usersRepo = ref.read(usersRepositoryProvider);
      // Removed: gamificationRepo - gamification is now handled by Cloud Function
      
      // Get scores from text fields
      final teamAScore = int.tryParse(_teamAScoreController.text.trim()) ?? 0;
      final teamBScore = int.tryParse(_teamBScoreController.text.trim()) ?? 0;
      
      _pauseTimer();
      
      // Load recap first to get events
      await _loadRecap();
      
      // Get game, teams, and events for denormalized data
      final game = await gamesRepo.getGame(widget.gameId);
      final teams = game != null ? await teamsRepo.getTeams(widget.gameId) : [];
      final events = await eventsRepo.getEvents(widget.gameId);
      
      // Calculate denormalized data
      final goalScorerIds = events
          .where((e) => e.type == EventType.goal)
          .map((e) => e.playerId)
          .toSet()
          .toList();
      
      final goalScorers = await usersRepo.getUsers(goalScorerIds);
      final goalScorerNames = goalScorers.map((u) => u.name).toList();
      
      // Get MVP
      String? mvpPlayerId;
      String? mvpPlayerName;
      try {
        final mvpEvent = events.firstWhere((e) => e.type == EventType.mvpVote);
        mvpPlayerId = mvpEvent.playerId;
        final mvp = await usersRepo.getUser(mvpPlayerId);
        mvpPlayerName = mvp?.name;
      } catch (e) {
        // No MVP found
      }
      
      // Get venue name
      String? venueName;
      if (game?.venueId != null) {
        final venuesRepo = ref.read(venuesRepositoryProvider);
        final venue = await venuesRepo.getVenue(game!.venueId!);
        venueName = venue?.name;
      } else if (game?.eventId != null && game?.hubId != null) {
        final eventsRepo2 = ref.read(hubEventsRepositoryProvider);
        final hubEvents = await eventsRepo2.getHubEvents(game!.hubId);
        try {
          final hubEvent = hubEvents.firstWhere((e) => e.eventId == game.eventId);
          venueName = hubEvent.location;
        } catch (e) {
          // Event not found
        }
      }
      
      // Update game with scores, status, and denormalized data
      await gamesRepo.updateGame(widget.gameId, {
        'teamAScore': teamAScore,
        'teamBScore': teamBScore,
        'status': GameStatus.completed.toFirestore(),
        'goalScorerIds': goalScorerIds,
        'goalScorerNames': goalScorerNames,
        'mvpPlayerId': mvpPlayerId,
        'mvpPlayerName': mvpPlayerName,
        'venueName': venueName,
      });
      
      // NOTE: Gamification is now handled by Cloud Function onGameCompleted
      // When game status changes to 'completed', the backend automatically:
      // 1. Calculates points for all players (base + goals + assists + saves + win bonus + MVP bonus)
      // 2. Updates gamification stats (gamesPlayed, gamesWon, goals, assists, saves)
      // 3. Awards badges and achievements
      // 4. Updates denormalized data
      // This ensures security and prevents cheating
      debugPrint('✅ Game completed. Gamification will be updated by Cloud Function onGameCompleted.');
      
      // Auto-post recap to feed if available
      if (_recapText != null && _recapText!.isNotEmpty) {
        try {
          final game = await gamesRepo.getGame(widget.gameId);
          if (game != null) {
            final feedRepo = ref.read(feedRepositoryProvider);
            final currentUserId = ref.read(currentUserIdProvider);
            
            if (currentUserId != null) {
              final feedPost = FeedPost(
                postId: '',
                hubId: game.hubId,
                authorId: currentUserId,
                type: 'game',
                content: _recapText,
                gameId: widget.gameId,
                createdAt: DateTime.now(),
              );
              
              await feedRepo.createPost(feedPost);
            }
          }
        } catch (e) {
          debugPrint('Failed to auto-post recap to feed: $e');
          // Don't fail game ending if feed post fails
        }
      }
      
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'המשחק הסתיים! נקודות גיימיפיקציה עודכנו');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Use ref.read for repositories - they don't change, so no need to watch
    final gamesRepo = ref.read(gamesRepositoryProvider);
    final teamsRepo = ref.read(teamsRepositoryProvider);
    final usersRepo = ref.read(usersRepositoryProvider);

    final gameStream = gamesRepo.watchGame(widget.gameId);
    final teamsStream = teamsRepo.watchTeams(widget.gameId);

    return AppScaffold(
      title: 'רישום סטטיסטיקות',
      body: StreamBuilder<Game?>(
        stream: gameStream,
        builder: (context, gameSnapshot) {
          if (gameSnapshot.connectionState == ConnectionState.waiting) {
            return const FuturisticLoadingState(message: 'טוען משחק...');
          }

          final game = gameSnapshot.data;
          if (game == null) {
            return const Center(child: Text('משחק לא נמצא'));
          }

          // Check admin permissions
          final roleAsync = ref.watch(hubRoleProvider(game.hubId));
          return roleAsync.when(
            data: (role) {
              if (role != UserRole.admin) {
                return Scaffold(
                  appBar: AppBar(
                    title: const Text('רישום סטטיסטיקות'),
                  ),
                  body: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 64, color: Colors.orange),
                        SizedBox(height: 16),
                        Text(
                          'אין לך הרשאת ניהול למסך זה',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'רק מנהלי Hub יכולים לרשום סטטיסטיקות',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

          return StreamBuilder<List<Team>>(
            stream: teamsStream,
            builder: (context, teamsSnapshot) {
              final teams = teamsSnapshot.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Score section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'תוצאות המשחק',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _teamAScoreController,
                                    decoration: InputDecoration(
                                      labelText: teams.isNotEmpty ? teams[0].name : 'תוצאת קבוצה א\'',
                                      border: const OutlineInputBorder(),
                                      prefixIcon: const Icon(Icons.sports_soccer),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  ':',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _teamBScoreController,
                                    decoration: InputDecoration(
                                      labelText: teams.length > 1 ? teams[1].name : 'תוצאת קבוצה ב\'',
                                      border: const OutlineInputBorder(),
                                      prefixIcon: const Icon(Icons.sports_soccer),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Timer section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              _formatDuration(_elapsed),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFeatures: [const FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isPaused)
                                  ElevatedButton.icon(
                                    onPressed: _startTimer,
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('התחל'),
                                  )
                                else
                                  ElevatedButton.icon(
                                    onPressed: _pauseTimer,
                                    icon: const Icon(Icons.pause),
                                    label: const Text('השהה'),
                                  ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: _resetTimer,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('איפוס'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Teams and players
                    ...teams.asMap().entries.map((entry) {
                      final teamIndex = entry.key;
                      final team = entry.value;
                      final teamColors = [
                        Colors.blue,
                        Colors.red,
                        Colors.green,
                        Colors.orange,
                      ];

                      return FutureBuilder<List<User>>(
                        future: usersRepo.getUsers(team.playerIds),
                        builder: (context, usersSnapshot) {
                          final users = usersSnapshot.data ?? [];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    team.name,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: teamColors[teamIndex % teamColors.length],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: users.map((user) {
                                      return _buildPlayerButton(
                                        context,
                                        user,
                                        teamColors[teamIndex % teamColors.length],
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),

                    // End game button
                    if (game.status == GameStatus.inProgress)
                      ElevatedButton.icon(
                        onPressed: _endGame,
                        icon: const Icon(Icons.stop),
                        label: const Text('סיים משחק'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),

                    // Recap section
                    if (_recapText != null && _recapText!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'סיכום משחק',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _recapText!,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 16),
                              WhatsAppShareButton(text: _recapText!),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
            },
            loading: () => const FuturisticLoadingState(message: 'בודק הרשאות...'),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('שגיאה בבדיקת הרשאות: $error'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerButton(BuildContext context, User user, Color teamColor) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: teamColor.withValues(alpha: 0.2),
          child: user.photoUrl != null
              ? OptimizedImage(
                  imageUrl: user.photoUrl!,
                  fit: BoxFit.cover,
                  width: 60,
                  height: 60,
                  borderRadius: BorderRadius.circular(30),
                  errorWidget: Icon(
                    Icons.person,
                    color: teamColor,
                  ),
                )
              : Icon(
                  Icons.person,
                  color: teamColor,
                ),
        ),
        const SizedBox(height: 4),
        Text(
          user.name,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            _buildEventButton(
              context,
              'שער',
              Icons.sports_soccer,
              Colors.green,
              () => _addEvent(EventType.goal, user.uid),
            ),
            _buildEventButton(
              context,
              'בישול',
              Icons.assistant,
              Colors.blue,
              () => _addEvent(EventType.assist, user.uid),
            ),
            _buildEventButton(
              context,
              'הצלה',
              Icons.sports_handball,
              Colors.orange,
              () => _addEvent(EventType.save, user.uid),
            ),
            _buildEventButton(
              context,
              'כרטיס',
              Icons.credit_card,
              Colors.red,
              () => _addEvent(EventType.card, user.uid),
            ),
            _buildEventButton(
              context,
              'MVP',
              Icons.star,
              Colors.purple,
              () => _addEvent(EventType.mvpVote, user.uid),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(60, 40),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
