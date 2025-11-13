import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/whatsapp_share_button.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/utils/recap_generator.dart';
import 'package:kickadoor/core/constants.dart';

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

  @override
  void initState() {
    super.initState();
    _loadRecap();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
      await gamesRepo.updateGameStatus(widget.gameId, GameStatus.completed);
      _pauseTimer();
      
      // Load recap first
      await _loadRecap();
      
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('המשחק הסתיים והסיכום פורסם בפיד')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')),
        );
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
    final gamesRepo = ref.watch(gamesRepositoryProvider);
    final teamsRepo = ref.watch(teamsRepositoryProvider);
    final usersRepo = ref.watch(usersRepositoryProvider);

    final gameStream = gamesRepo.watchGame(widget.gameId);
    final teamsStream = teamsRepo.watchTeams(widget.gameId);

    return AppScaffold(
      title: 'רישום סטטיסטיקות',
      body: StreamBuilder<Game?>(
        stream: gameStream,
        builder: (context, gameSnapshot) {
          if (gameSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final game = gameSnapshot.data;
          if (game == null) {
            return const Center(child: Text('משחק לא נמצא'));
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
              ? ClipOval(
                  child: Image.network(
                    user.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person,
                      color: teamColor,
                    ),
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
