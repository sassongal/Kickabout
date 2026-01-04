import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/features/games/domain/services/live_match_permissions.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/utils/stopwatch_utility.dart';
import 'package:kattrick/features/games/presentation/screens/fullscreen_stopwatch_screen.dart';
import 'package:flutter/services.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:kattrick/features/games/domain/models/rotation_state.dart';
import 'package:kattrick/features/games/domain/models/session_rotation.dart';

class LiveMatchScreen extends ConsumerStatefulWidget {
  final String hubId;
  final String eventId;

  const LiveMatchScreen({
    super.key,
    required this.hubId,
    required this.eventId,
  });

  @override
  ConsumerState<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends ConsumerState<LiveMatchScreen> {
  // Stopwatch State - Using StopwatchUtility
  late final StopwatchUtility _stopwatchUtility;
  Timer? _timer;
  DateTime? _startTimestamp;
  int _elapsedOffsetSeconds = 0; // Accumulated time from previous sessions
  bool _isTimeUp = false; // Visual indicator for time limit reached
  Timer? _pulseTimer; // For pulsing animation when time is up

  // Match State
  Team? _selectedTeamA;
  Team? _selectedTeamB;
  int _scoreA = 0;
  int _scoreB = 0;

  // Data
  HubEvent? _event;
  Hub? _hub;
  List<Team> _teams = [];
  List<MatchResult> _matchHistory = [];
  Map<String, User> _playersMap = {}; // Cache for player names

  // Stream subscription for live state
  StreamSubscription<Map<String, dynamic>?>? _liveStateSubscription;

  // New: Rotation state
  RotationState? _rotationState;

  // New: Countdown mode
  bool _isCountdownMode = false;

  @override
  void initState() {
    super.initState();
    _stopwatchUtility = StopwatchUtility();
    _stopwatchUtility.addListener(_onStopwatchUpdate);
    _loadData();
    _subscribeToLiveState();
    _loadPlayers();
  }

  /// Listen to stopwatch updates to check time limit
  void _onStopwatchUpdate() {
    if (_event == null || !_stopwatchUtility.isRunning) return;

    final totalSeconds = _elapsedOffsetSeconds +
        (_stopwatchUtility.isRunning ? _stopwatchUtility.elapsed.inSeconds : 0);
    final durationMinutes = _event!.durationMinutes ?? 12;
    final timeLimitSeconds = durationMinutes * 60;

    if (totalSeconds >= timeLimitSeconds && !_isTimeUp) {
      setState(() {
        _isTimeUp = true;
      });
      _playTimeUpAlert();
      _startPulseAnimation();
    } else if (totalSeconds < timeLimitSeconds && _isTimeUp) {
      setState(() {
        _isTimeUp = false;
      });
      _pulseTimer?.cancel();
    }
  }

  /// Play audio alert when time is up
  void _playTimeUpAlert() {
    // Use system sound for alert (works on all platforms)
    HapticFeedback.heavyImpact();
    // For a more audible sound, you can use a package like audioplayers
    // For now, we use haptic feedback + visual indicator
  }

  /// Start pulsing animation when time is up
  void _startPulseAnimation() {
    _pulseTimer?.cancel();
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          // Trigger rebuild for pulsing effect
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseTimer?.cancel();
    _liveStateSubscription?.cancel();
    _stopwatchUtility.dispose();
    super.dispose();
  }

  /// Load all players from teams for display
  Future<void> _loadPlayers() async {
    if (_teams.isEmpty) return;

    final allPlayerIds = <String>{};
    for (final team in _teams) {
      allPlayerIds.addAll(team.playerIds);
    }

    if (allPlayerIds.isEmpty) return;

    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      final users = await usersRepo.getUsers(allPlayerIds.toList());
      if (mounted) {
        setState(() {
          _playersMap = {for (var user in users) user.uid: user};
        });
      }
    } catch (e) {
      debugPrint('Error loading players: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final eventsRepo = ref.read(hubEventsRepositoryProvider);
      final hubsRepo = ref.read(hubsRepositoryProvider);

      final event = await eventsRepo.getHubEvent(widget.hubId, widget.eventId);
      final hub = await hubsRepo.getHub(widget.hubId);

      if (event == null) {
        throw Exception('Event not found');
      }

      // Load match history from event.matches array
      final matches = event.matches;

      // Load persisted live state
      final liveState =
          await eventsRepo.getLiveState(widget.hubId, widget.eventId);

      if (mounted) {
        setState(() {
          _event = event;
          _hub = hub;
          _teams =
              event.teams.isNotEmpty ? event.teams : []; // Use teams from event
          _matchHistory = matches;

          // Load players after teams are loaded
          _loadPlayers();

          // Restore live state if available
          if (liveState != null) {
            _elapsedOffsetSeconds =
                liveState['elapsedOffsetSeconds'] as int? ?? 0;
            _scoreA = liveState['scoreA'] as int? ?? 0;
            _scoreB = liveState['scoreB'] as int? ?? 0;

            final startTs = liveState['startTimestamp'] as Timestamp?;
            _startTimestamp = startTs?.toDate();

            final isRunning = liveState['isRunning'] as bool? ?? false;

            // Restore selected teams
            final teamAId = liveState['selectedTeamAId'] as String?;
            final teamBId = liveState['selectedTeamBId'] as String?;
            _rotationState = liveState['rotationState'] as RotationState?;

            if (_rotationState != null) {
              _updateTeamsFromRotation();
            } else {
              if (teamAId != null && _teams.isNotEmpty) {
                try {
                  _selectedTeamA =
                      _teams.firstWhere((t) => t.teamId == teamAId);
                } catch (e) {
                  _selectedTeamA = _teams[0];
                }
              } else if (_teams.length >= 1) {
                _selectedTeamA = _teams[0];
              }

              if (teamBId != null && _teams.length > 1) {
                try {
                  _selectedTeamB =
                      _teams.firstWhere((t) => t.teamId == teamBId);
                } catch (e) {
                  _selectedTeamB = _teams.length > 1 ? _teams[1] : null;
                }
              } else if (_teams.length >= 2) {
                _selectedTeamB = _teams[1];
              }
            }

            // Resume stopwatch if it was running
            if (isRunning && _startTimestamp != null) {
              final now = DateTime.now();
              final elapsedSinceStart =
                  now.difference(_startTimestamp!).inSeconds;
              _elapsedOffsetSeconds = _elapsedOffsetSeconds + elapsedSinceStart;
              _stopwatchUtility.reset();
              _stopwatchUtility.start();
            } else {
              // Just set the accumulated time - we'll handle this in the widget
              _elapsedOffsetSeconds = _elapsedOffsetSeconds;
            }
          } else {
            // No saved state - select first two teams if available
            if (_teams.length >= 2) {
              _selectedTeamA = _teams[0];
              _selectedTeamB = _teams[1];
            } else if (_teams.length == 1) {
              _selectedTeamA = _teams[0];
              _selectedTeamB = null;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading live match data: $e');
      if (mounted) {
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בטעינת נתוני המשחק: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Subscribe to live state updates for real-time sync
  void _subscribeToLiveState() {
    final eventsRepo = ref.read(hubEventsRepositoryProvider);
    _liveStateSubscription = eventsRepo
        .watchLiveState(widget.hubId, widget.eventId)
        .listen((liveState) {
      if (liveState != null && mounted) {
        // Update state from remote changes (other admins)
        setState(() {
          // Update scores
          final remoteScoreA = liveState['scoreA'] as int?;
          final remoteScoreB = liveState['scoreB'] as int?;
          if (remoteScoreA != null) _scoreA = remoteScoreA;
          if (remoteScoreB != null) _scoreB = remoteScoreB;

          // Update teams
          final teamAId = liveState['selectedTeamAId'] as String?;
          final teamBId = liveState['selectedTeamBId'] as String?;

          if (teamAId != null && _teams.isNotEmpty) {
            try {
              _selectedTeamA = _teams.firstWhere((t) => t.teamId == teamAId);
            } catch (e) {
              // Team not found, keep current selection
            }
          }

          if (teamBId != null && _teams.length > 1) {
            try {
              _selectedTeamB = _teams.firstWhere((t) => t.teamId == teamBId);
            } catch (e) {
              // Team not found, keep current selection
            }
          }

          // Update rotation state
          final remoteRotationJson = liveState['rotationState'];
          if (remoteRotationJson != null) {
            _rotationState = remoteRotationJson as RotationState;
            _updateTeamsFromRotation();
          }

          // Update stopwatch state if changed remotely
          final remoteIsRunning = liveState['isRunning'] as bool? ?? false;
          final remoteElapsed = liveState['elapsedOffsetSeconds'] as int? ?? 0;
          final remoteStartTs = liveState['startTimestamp'] as Timestamp?;

          // Only sync if stopwatch state changed and we're not the one who changed it
          // (This prevents infinite loops)
          if (remoteIsRunning != _stopwatchUtility.isRunning) {
            if (remoteIsRunning && !_stopwatchUtility.isRunning) {
              // Remote started - sync
              _startTimestamp = remoteStartTs?.toDate() ?? DateTime.now();
              _elapsedOffsetSeconds = remoteElapsed;
              _stopwatchUtility.reset();
              _stopwatchUtility.start();
            } else if (!remoteIsRunning && _stopwatchUtility.isRunning) {
              // Remote stopped - sync
              _stopwatchUtility.pause();
              _elapsedOffsetSeconds = remoteElapsed;
            }
          } else if (remoteElapsed != _elapsedOffsetSeconds &&
              !_stopwatchUtility.isRunning) {
            // Only update elapsed if stopwatch is not running (to avoid conflicts)
            _elapsedOffsetSeconds = remoteElapsed;
            _stopwatchUtility.reset();
          }
        });
      }
    });
  }

  /// Save live state to Firestore
  Future<void> _saveLiveState() async {
    try {
      final eventsRepo = ref.read(hubEventsRepositoryProvider);
      // Calculate total elapsed: offset + current stopwatch time
      final totalElapsed = _elapsedOffsetSeconds +
          (_stopwatchUtility.isRunning
              ? _stopwatchUtility.elapsed.inSeconds
              : 0);

      await eventsRepo.saveLiveState(
        hubId: widget.hubId,
        eventId: widget.eventId,
        startTimestamp: _startTimestamp,
        isRunning: _stopwatchUtility.isRunning,
        elapsedOffsetSeconds: totalElapsed,
        scoreA: _scoreA,
        scoreB: _scoreB,
        selectedTeamAId: _selectedTeamA?.teamId,
        selectedTeamBId: _selectedTeamB?.teamId,
        rotationState: _rotationState,
      );
    } catch (e) {
      debugPrint('Error saving live state: $e');
    }
  }

  void _finishMatch() {
    if (_selectedTeamA == null || _selectedTeamB == null) return;
    if (_event == null || _hub == null) return;

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      SnackbarHelper.showError(context, 'נדרש להתחבר כדי לשמור משחק');
      return;
    }

    // Permission check
    if (!LiveMatchPermissions.canLogMatch(
        userId: currentUserId, hub: _hub!, event: _event!)) {
      SnackbarHelper.showError(context, 'אין לך הרשאה לתעד משחקים באירוע זה');
      return;
    }

    // Show dialog to confirm and log stats
    showDialog(
      context: context,
      builder: (context) => _MatchLoggingDialog(
        hubId: widget.hubId,
        eventId: widget.eventId,
        teamA: _selectedTeamA!,
        teamB: _selectedTeamB!,
        initialScoreA: _scoreA,
        initialScoreB: _scoreB,
        durationSeconds: _elapsedOffsetSeconds +
            (_stopwatchUtility.isRunning
                ? _stopwatchUtility.elapsed.inSeconds
                : 0),
        allPlayerIds: _getAllPlayerIds(),
        onSave: (record) async {
          // Save to Firestore using transaction (with permission check)
          try {
            final eventsRepo = ref.read(hubEventsRepositoryProvider);

            // Use the new saveMatchResult method with transaction and permission check
            await eventsRepo.saveMatchResult(
              hubId: widget.hubId,
              eventId: widget.eventId,
              matchResult: record,
              userId: currentUserId,
              hub: _hub!,
              event: _event!,
            );

            if (mounted) {
              setState(() {
                _matchHistory.insert(0, record);
                _scoreA = 0;
                _scoreB = 0;
                _stopwatchUtility.reset();
                _startTimestamp = null;
                _elapsedOffsetSeconds = 0;

                // Apply Winner Stays rotation
                _applyWinnerStaysRotation(record);
              });

              // Clear live state after match is saved
              await eventsRepo.saveLiveState(
                hubId: widget.hubId,
                eventId: widget.eventId,
                startTimestamp: null,
                isRunning: false,
                elapsedOffsetSeconds: 0,
                scoreA: 0,
                scoreB: 0,
                selectedTeamAId: _selectedTeamA?.teamId,
                selectedTeamBId: _selectedTeamB?.teamId,
                rotationState: _rotationState,
              );

              SnackbarHelper.showSuccess(context, 'המשחק נשמר בהצלחה!');
            }
          } catch (e) {
            if (mounted) {
              SnackbarHelper.showError(
                context,
                'שגיאה בשמירת המשחק: $e',
              );
            }
          }
        },
      ),
    );
  }

  /// Apply Winner Stays rotation logic using SessionRotationLogic
  void _applyWinnerStaysRotation(MatchResult completedMatch) {
    if (_teams.length < 2) return;

    // Initialize rotation state if not already set
    if (_rotationState == null) {
      // Reorder teams so currently selected teams are first in the rotation
      final otherTeams = _teams
          .where((t) =>
              t.teamId != _selectedTeamA?.teamId &&
              t.teamId != _selectedTeamB?.teamId)
          .toList();

      final orderedTeams = [
        if (_selectedTeamA != null) _selectedTeamA!,
        if (_selectedTeamB != null) _selectedTeamB!,
        ...otherTeams,
      ];

      if (orderedTeams.length >= 2) {
        _rotationState = SessionRotationLogic.createInitialState(orderedTeams);
      }
    }

    try {
      // Calculate next rotation
      _rotationState = SessionRotationLogic.calculateNextRotation(
        current: _rotationState!,
        completedMatch: completedMatch,
      );

      // Update UI selection
      _updateTeamsFromRotation();

      // Save updated state to Firestore
      _saveLiveState();
    } catch (e) {
      debugPrint('Error applying rotation: $e');
    }
  }

  /// Show confirmation dialog for ending the event
  Future<void> _showEndEventDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('סיום אירוע'),
        content: const Text(
          'האם אתה בטוח שברצונך לסיים את האירוע?\n\n'
          'פעולה זו תחשב את הסטטיסטיקות הסופיות ותפרסם פוסט בפיד הקהילתי.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('אישור'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _completeEvent();
    }
  }

  /// Complete the event and navigate back
  Future<void> _completeEvent() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final currentUserId = ref.read(currentUserIdProvider);
      if (currentUserId == null || _hub == null || _event == null) {
        throw Exception('Missing required data');
      }

      final eventsRepo = ref.read(hubEventsRepositoryProvider);

      await eventsRepo.completeEvent(
        hubId: widget.hubId,
        eventId: widget.eventId,
        userId: currentUserId,
        hub: _hub!,
        event: _event!,
      );

      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);

        // Show success message
        SnackbarHelper.showSuccess(context, 'האירוע הסתיים בהצלחה!');

        // Navigate back
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog if open
        Navigator.pop(context);

        SnackbarHelper.showError(
          context,
          'שגיאה בסיום האירוע: ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final canLog = currentUserId != null &&
        _hub != null &&
        _event != null &&
        LiveMatchPermissions.canLogMatch(
            userId: currentUserId, hub: _hub!, event: _event!);

    // Calculate current match number
    final currentMatchNumber = _matchHistory.length + 1;

    return AppScaffold(
      title: 'ניהול משחק חי',
      actions: [
        // Change teams button
        if (canLog && _teams.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'שינוי כוחות',
            onPressed: () {
              // Navigate to team maker screen
              context.push(
                  '/hubs/${widget.hubId}/events/${widget.eventId}/team-maker');
            },
          ),
        if (canLog)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Open settings to appoint scorers
            },
          ),
      ],
      body: Column(
        children: [
          // 1. Stopwatch Header (Premium with Hero animation) - MOVED TO TOP
          _buildPremiumStopwatchHeader(canLog, currentMatchNumber),

          // 2. Current Match Scoreboard - תיעוד תוצאה מיד מתחת לסטופר!
          const SizedBox(height: 8),
          _buildScoreboard(canLog),

          // 3. Teams Carousel (Premium with glassmorphism)
          if (_teams.isNotEmpty) _buildTeamsCarousel(),

          // 4. Match History & Leaderboard
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // 5. Leaderboard (Mini Table)
                  _buildLeaderboard(),

                  const SizedBox(height: 24),

                  // 6. Match History
                  _buildMatchHistory(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build premium teams carousel with glassmorphism effect
  Widget _buildTeamsCarousel() {
    if (_teams.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 280, // הגדלה מ-200 ל-280 כדי להציג את כל השחקנים
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: PageView.builder(
        itemCount: _teams.length,
        controller:
            PageController(viewportFraction: 0.9), // Show hint of next card
        itemBuilder: (context, index) {
          final team = _teams[index];
          final teamColor = _getTeamColor(team.color);
          final isSelected = _selectedTeamA?.teamId == team.teamId ||
              _selectedTeamB?.teamId == team.teamId;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  teamColor.withOpacity(0.15),
                  teamColor.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: isSelected ? teamColor : Colors.transparent,
                width: isSelected ? 2 : 0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14), // הגדלה מ-12 ל-14 לחלל נושם יותר
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team header
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: teamColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: teamColor.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          team.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: teamColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: teamColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'משחק',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Player list - Compact Column instead of ListView
                  Expanded(
                    child: team.playerIds.isEmpty
                        ? Center(
                            child: Text(
                              'אין שחקנים',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                ...team.playerIds.map((playerId) {
                                  final player = _playersMap[playerId];
                                  if (player == null)
                                    return const SizedBox.shrink();

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        PlayerAvatar(
                                          user: player,
                                          radius: 14, // Smaller avatar
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            player.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build premium stopwatch header
  Widget _buildPremiumStopwatchHeader(bool canLog, int currentMatchNumber) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Slate 800
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Stopwatch Section
          Hero(
            tag: 'stopwatch',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canLog
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FullScreenStopwatchScreen(
                              stopwatchUtility: _stopwatchUtility,
                              elapsedOffsetSeconds: _elapsedOffsetSeconds,
                              isRunning: _stopwatchUtility.isRunning,
                              isCountdownMode: _isCountdownMode,
                              onRunningChanged: (isRunning) {
                                setState(() {
                                  if (isRunning) {
                                    _startTimestamp = DateTime.now();
                                    _stopwatchUtility.start();
                                  } else {
                                    _elapsedOffsetSeconds +=
                                        _stopwatchUtility.elapsed.inSeconds;
                                    _stopwatchUtility.pause();
                                  }
                                  _saveLiveState();
                                });
                              },
                              onReset: () {
                                setState(() {
                                  _stopwatchUtility.reset();
                                  _startTimestamp = null;
                                  _elapsedOffsetSeconds = 0;
                                  _saveLiveState();
                                });
                              },
                            ),
                          ),
                        );
                      }
                    : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Display time with offset in MM:SS:mm format
                      ExcludeSemantics(
                        child: AnimatedBuilder(
                          animation: _stopwatchUtility,
                          builder: (context, _) {
                            final totalMilliseconds = (_elapsedOffsetSeconds *
                                    1000) +
                                (_stopwatchUtility.isRunning
                                    ? _stopwatchUtility.elapsed.inMilliseconds
                                    : 0);

                            final durationMinutes =
                                _event?.durationMinutes ?? 12;
                            final timeLimitMilliseconds =
                                durationMinutes * 60 * 1000;

                            final displayMs = _isCountdownMode
                                ? (timeLimitMilliseconds - totalMilliseconds)
                                    .clamp(0, timeLimitMilliseconds)
                                : totalMilliseconds;

                            final totalSeconds = displayMs ~/ 1000;
                            final minutes = totalSeconds ~/ 60;
                            final seconds = totalSeconds % 60;
                            final centiseconds = (displayMs % 1000) ~/ 10;

                            final isTimeUp =
                                totalMilliseconds >= timeLimitMilliseconds;

                            final color = (isTimeUp && !_isCountdownMode) ||
                                    (_isCountdownMode && displayMs == 0)
                                ? Colors.red
                                : Colors.white;

                            return Text(
                              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}:${centiseconds.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: color,
                                fontFamily: 'monospace',
                                letterSpacing: 2,
                                shadows: isTimeUp
                                    ? [
                                        Shadow(
                                          color: Colors.red.withOpacity(0.8),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (canLog) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _isCountdownMode ? Icons.history : Icons.timer_outlined,
                    color: Colors.white,
                  ),
                  tooltip: _isCountdownMode ? 'סטופר' : 'ספירה לאחור',
                  onPressed: () {
                    setState(() {
                      _isCountdownMode = !_isCountdownMode;
                    });
                  },
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: Icon(
                    _stopwatchUtility.isRunning
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 48,
                  ),
                  color: Colors.white,
                  onPressed: () {
                    if (_stopwatchUtility.isRunning) {
                      _elapsedOffsetSeconds +=
                          _stopwatchUtility.elapsed.inSeconds;
                      _stopwatchUtility.pause();
                    } else {
                      _startTimestamp = DateTime.now();
                      _stopwatchUtility.start();
                    }
                    _saveLiveState();
                  },
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 32),
                  color: Colors.white70,
                  onPressed: () {
                    _stopwatchUtility.reset();
                    _startTimestamp = null;
                    _elapsedOffsetSeconds = 0;
                    _saveLiveState();
                  },
                ),
              ],
            ),
          ],
          // End Event Button (always shown for managers)
          if (canLog)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // End Event Button
                  GestureDetector(
                    onTap: _showEndEventDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.red.withOpacity(0.3), width: 1.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.exit_to_app,
                              color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'סיום אירוע',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Match number badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.blue.withOpacity(0.5), width: 1.5),
                    ),
                    child: Text(
                      'משחק #$currentMatchNumber',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreboard(bool canLog) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.blue.shade100,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // כותרת ברורה
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.scoreboard, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  'תיעוד תוצאה',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTeamControl(
                    _selectedTeamA,
                    _scoreA,
                    (s) {
                      setState(() => _scoreA = s);
                      _saveLiveState();
                    },
                    canLog,
                    isTeamA: true,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 30),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildTeamControl(
                    _selectedTeamB,
                    _scoreB,
                    (s) {
                      setState(() => _scoreB = s);
                      _saveLiveState();
                    },
                    canLog,
                    isTeamA: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (canLog)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _finishMatch,
                  icon: const Icon(Icons.save, size: 22),
                  label: const Text('שמור משחק ותעד תוצאה',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 18),
                    elevation: 3,
                    shadowColor: Colors.green.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamControl(
      Team? team, int score, Function(int) onScoreChanged, bool canLog,
      {required bool isTeamA}) {
    final teamColor = team != null ? _getTeamColor(team.color) : Colors.grey;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Team Dropdown or Name
        if (canLog && _teams.length > 1)
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: team?.teamId,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: teamColor),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: teamColor,
              ),
              alignment: Alignment.center,
              items: _teams.map((t) {
                // Optional: Disable selection if team is already selected in the other slot
                // final isSelectedOther = isTeamA
                //     ? t.teamId == _selectedTeamB?.teamId
                //     : t.teamId == _selectedTeamA?.teamId;

                return DropdownMenuItem<String>(
                  value: t.teamId,
                  child: Center(
                    child: Text(
                      t.name,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (newTeamId) {
                if (newTeamId == null) return;
                setState(() {
                  final newTeam =
                      _teams.firstWhere((t) => t.teamId == newTeamId);
                  if (isTeamA) {
                    _selectedTeamA = newTeam;
                  } else {
                    _selectedTeamB = newTeam;
                  }
                  _saveLiveState();
                });
              },
            ),
          )
        else
          Text(
            team?.name ?? 'קבוצה',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: teamColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),

        const SizedBox(height: 12),

        // Score Control (Premium)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canLog)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    onTap: () => onScoreChanged(score + 1),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.keyboard_arrow_up,
                          color: Colors.grey[600]),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  score.toString(),
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: teamColor,
                  ),
                ),
              ),
              if (canLog)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16)),
                    onTap: () => onScoreChanged(score > 0 ? score - 1 : 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.keyboard_arrow_down,
                          color: Colors.grey[600]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboard() {
    // Calculate stats from _matchHistory
    final stats = <String, Map<String, int>>{}; // TeamID -> {Points, GF, GA}

    for (var team in _teams) {
      stats[team.teamId] = {'points': 0, 'gf': 0, 'ga': 0, 'played': 0};
    }

    for (var match in _matchHistory) {
      // Find teams by color
      final teamA = _teams.firstWhere(
        (t) => t.color == match.teamAColor,
        orElse: () => _teams.first,
      );
      final teamB = _teams.firstWhere(
        (t) => t.color == match.teamBColor,
        orElse: () => _teams.length > 1 ? _teams[1] : _teams.first,
      );

      final teamAStats =
          stats[teamA.teamId] ?? {'points': 0, 'gf': 0, 'ga': 0, 'played': 0};
      final teamBStats =
          stats[teamB.teamId] ?? {'points': 0, 'gf': 0, 'ga': 0, 'played': 0};

      // Goals for/against
      teamAStats['gf'] = (teamAStats['gf'] ?? 0) + match.scoreA;
      teamAStats['ga'] = (teamAStats['ga'] ?? 0) + match.scoreB;
      teamBStats['gf'] = (teamBStats['gf'] ?? 0) + match.scoreB;
      teamBStats['ga'] = (teamBStats['ga'] ?? 0) + match.scoreA;

      // Points (3 for win, 1 for draw)
      if (match.scoreA > match.scoreB) {
        teamAStats['points'] = (teamAStats['points'] ?? 0) + 3;
      } else if (match.scoreB > match.scoreA) {
        teamBStats['points'] = (teamBStats['points'] ?? 0) + 3;
      } else {
        teamAStats['points'] = (teamAStats['points'] ?? 0) + 1;
        teamBStats['points'] = (teamBStats['points'] ?? 0) + 1;
      }

      teamAStats['played'] = (teamAStats['played'] ?? 0) + 1;
      teamBStats['played'] = (teamBStats['played'] ?? 0) + 1;

      stats[teamA.teamId] = teamAStats;
      stats[teamB.teamId] = teamBStats;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const ListTile(
            title: Text('טבלת הטורניר',
                style: TextStyle(fontWeight: FontWeight.bold)),
            leading: Icon(Icons.leaderboard, color: Colors.amber),
          ),
          const Divider(height: 1),
          // Table Header
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text('קבוצה')),
                Expanded(child: Center(child: Text('מש\''))),
                Expanded(child: Center(child: Text('הפרש'))),
                Expanded(
                    child: Center(
                        child: Text('נק\'',
                            style: TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
          // Rows
          ...(() {
            final sortedEntries = stats.entries.toList()
              ..sort((a, b) {
                final pointsA = a.value['points'] ?? 0;
                final pointsB = b.value['points'] ?? 0;
                if (pointsB != pointsA) return pointsB.compareTo(pointsA);

                final gdA = (a.value['gf'] ?? 0) - (a.value['ga'] ?? 0);
                final gdB = (b.value['gf'] ?? 0) - (b.value['ga'] ?? 0);
                return gdB.compareTo(gdA);
              });

            return sortedEntries.map((entry) {
              final teamId = entry.key;
              final teamStats = entry.value;
              final team = _teams.firstWhere((t) => t.teamId == teamId,
                  orElse: () => _teams.first);
              final goalDiff = (teamStats['gf'] ?? 0) - (teamStats['ga'] ?? 0);

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(team.name)),
                    Expanded(
                        child:
                            Center(child: Text('${teamStats['played'] ?? 0}'))),
                    Expanded(child: Center(child: Text('$goalDiff'))),
                    Expanded(
                      child: Center(
                        child: Text(
                          '${teamStats['points'] ?? 0}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            });
          })(),
        ],
      ),
    );
  }

  Widget _buildMatchHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('היסטוריית משחקים',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _matchHistory.length,
          itemBuilder: (context, index) {
            final match = _matchHistory[index];
            return _buildMatchHistoryItem(match, index);
          },
        ),
      ],
    );
  }

  Widget _buildMatchHistoryItem(MatchResult match, int index) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final canLog = currentUserId != null &&
        _hub != null &&
        _event != null &&
        LiveMatchPermissions.canLogMatch(
            userId: currentUserId, hub: _hub!, event: _event!);

    return FutureBuilder<Map<String, User>>(
      future: _loadMatchPlayers(match),
      builder: (context, snapshot) {
        final playersMap = snapshot.data ?? {};

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: InkWell(
            onTap: canLog ? () => _editMatch(match) : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Match header: Teams and Score
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              match.teamAColor,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${match.scoreA} - ${match.scoreB}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              match.teamBColor,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (canLog)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _editMatch(match),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Scorers
                  if (match.scorerIds.isNotEmpty) ...[
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: match.scorerIds.map((scorerId) {
                        final player = playersMap[scorerId];
                        return Chip(
                          label: Text(
                            player?.name ?? 'לא ידוע',
                            style: const TextStyle(fontSize: 11),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // MVP with star icon
                  if (match.mvpId != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          playersMap[match.mvpId]?.name ?? 'לא ידוע',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Time
                  Text(
                    DateFormat('HH:mm').format(match.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, User>> _loadMatchPlayers(MatchResult match) async {
    final allPlayerIds = <String>{};
    allPlayerIds.addAll(match.scorerIds);
    allPlayerIds.addAll(match.assistIds);
    if (match.mvpId != null) {
      allPlayerIds.add(match.mvpId!);
    }

    if (allPlayerIds.isEmpty) return {};

    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      final users = await usersRepo.getUsers(allPlayerIds.toList());
      return {for (var user in users) user.uid: user};
    } catch (e) {
      return {};
    }
  }

  void _editMatch(MatchResult match) {
    if (_event == null || _hub == null) return;

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      SnackbarHelper.showError(context, 'נדרש להתחבר כדי לערוך משחק');
      return;
    }

    // Permission check
    if (!LiveMatchPermissions.canLogMatch(
        userId: currentUserId, hub: _hub!, event: _event!)) {
      SnackbarHelper.showError(context, 'אין לך הרשאה לערוך משחקים באירוע זה');
      return;
    }

    // Get all player IDs from teams
    final allPlayerIds = <String>{};
    for (final team in _teams) {
      allPlayerIds.addAll(team.playerIds);
    }

    // Show edit dialog (similar to logging dialog)
    showDialog(
      context: context,
      builder: (context) => _MatchEditDialog(
        hubId: widget.hubId,
        eventId: widget.eventId,
        matchId: match.matchId,
        teamA: _teams.firstWhere(
          (t) => (t.color ?? t.name) == match.teamAColor,
          orElse: () => _teams.first,
        ),
        teamB: _teams.firstWhere(
          (t) => (t.color ?? t.name) == match.teamBColor,
          orElse: () => _teams.length > 1 ? _teams[1] : _teams.first,
        ),
        initialScoreA: match.scoreA,
        initialScoreB: match.scoreB,
        initialScorers: match.scorerIds,
        initialAssists: match.assistIds,
        initialMvp: match.mvpId,
        allPlayerIds: allPlayerIds.toList(),
        onSave: (updatedMatch) async {
          try {
            final eventsRepo = ref.read(hubEventsRepositoryProvider);
            await eventsRepo.updateMatchResult(
              hubId: widget.hubId,
              eventId: widget.eventId,
              matchId: match.matchId,
              updatedMatch: updatedMatch,
              userId: currentUserId,
              hub: _hub!,
              event: _event!,
            );

            if (mounted) {
              // Reload event data to refresh match history
              await _loadData();
              SnackbarHelper.showSuccess(context, 'המשחק עודכן בהצלחה!');
            }
          } catch (e) {
            if (mounted) {
              SnackbarHelper.showError(context, 'שגיאה בעדכון המשחק: $e');
            }
          }
        },
      ),
    );
  }

  Color _getTeamColor(String? colorName) {
    switch (colorName?.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.orangeAccent;
      case 'green':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Get all player IDs from both selected teams
  List<String> _getAllPlayerIds() {
    final playerIds = <String>{};
    if (_selectedTeamA != null) {
      playerIds.addAll(_selectedTeamA!.playerIds);
    }
    if (_selectedTeamB != null) {
      playerIds.addAll(_selectedTeamB!.playerIds);
    }
    return playerIds.toList();
  }

  void _updateTeamsFromRotation() {
    if (_rotationState == null || _teams.isEmpty) return;

    try {
      final teamA = _teams.firstWhere(
        (t) =>
            SessionRotationLogic.getTeamIdentifier(t) ==
            _rotationState!.teamAColor,
        orElse: () => _teams[0],
      );
      final teamB = _teams.firstWhere(
        (t) =>
            SessionRotationLogic.getTeamIdentifier(t) ==
            _rotationState!.teamBColor,
        orElse: () => _teams.length > 1 ? _teams[1] : _teams[0],
      );

      setState(() {
        _selectedTeamA = teamA;
        _selectedTeamB = teamB;
      });
    } catch (e) {
      debugPrint('Error updating teams from rotation: $e');
    }
  }
}

class _MatchLoggingDialog extends ConsumerStatefulWidget {
  final String hubId;
  final String eventId;
  final Team teamA;
  final Team teamB;
  final int initialScoreA;
  final int initialScoreB;
  final int durationSeconds;
  final List<String> allPlayerIds;
  final Function(MatchResult) onSave;

  const _MatchLoggingDialog({
    required this.hubId,
    required this.eventId,
    required this.teamA,
    required this.teamB,
    required this.initialScoreA,
    required this.initialScoreB,
    required this.durationSeconds,
    required this.allPlayerIds,
    required this.onSave,
  });

  @override
  ConsumerState<_MatchLoggingDialog> createState() =>
      _MatchLoggingDialogState();
}

class _MatchLoggingDialogState extends ConsumerState<_MatchLoggingDialog> {
  late int scoreA;
  late int scoreB;
  List<String> _selectedScorers = [];
  List<String> _selectedAssists = [];
  String? _selectedMvp;
  List<User> _players = [];
  bool _isLoadingPlayers = true;
  String? _drawWinner; // For draw scenarios
  int _currentStep = 0; // 0: Score, 1: MVP, 2: Scorers, 3: Assists, 4: Confirm
  late FixedExtentScrollController _scoreAController;
  late FixedExtentScrollController _scoreBController;

  // Get winner team
  Team? get _winnerTeam {
    if (scoreA > scoreB) return widget.teamA;
    if (scoreB > scoreA) return widget.teamB;
    return null; // Draw
  }

  // Get winner players (only from winning team)
  List<User> get _winnerPlayers {
    if (_winnerTeam == null) return [];
    return _players
        .where((p) => _winnerTeam!.playerIds.contains(p.uid))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    scoreA = widget.initialScoreA.clamp(0, 5);
    scoreB = widget.initialScoreB.clamp(0, 5);
    _scoreAController = FixedExtentScrollController(initialItem: scoreA);
    _scoreBController = FixedExtentScrollController(initialItem: scoreB);
    _loadPlayers();
  }

  @override
  void dispose() {
    _scoreAController.dispose();
    _scoreBController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    if (widget.allPlayerIds.isEmpty) {
      setState(() => _isLoadingPlayers = false);
      return;
    }

    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      final players = await usersRepo.getUsers(widget.allPlayerIds);
      if (mounted) {
        setState(() {
          _players = players;
          _isLoadingPlayers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPlayers = false);
      }
    }
  }

  void _showDrawWinnerSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('תיקו - יש לבחור מנצחת'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'המשחק נגמר בתיקו. יש לבחור קבוצה מנצחת כדי להמשיך עם "המנצח נשאר".',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            RadioListTile<String>(
              title: Text(widget.teamA.name),
              value: 'teamA',
              groupValue: _drawWinner,
              onChanged: (value) {
                setState(() {
                  _drawWinner = value;
                  scoreA = scoreA + 1; // Increment to make team A winner
                });
                Navigator.pop(context);
                _saveMatchResult();
              },
            ),
            RadioListTile<String>(
              title: Text(widget.teamB.name),
              value: 'teamB',
              groupValue: _drawWinner,
              onChanged: (value) {
                setState(() {
                  _drawWinner = value;
                  scoreB = scoreB + 1; // Increment to make team B winner
                });
                Navigator.pop(context);
                _saveMatchResult();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );
  }

  /// Validate game logic rules
  String? _validateGameLogic() {
    // 1. Validate Scorers count vs Goals
    int teamAScorersCount = 0;
    int teamBScorersCount = 0;

    for (var id in _selectedScorers) {
      if (widget.teamA.playerIds.contains(id)) teamAScorersCount++;
      if (widget.teamB.playerIds.contains(id)) teamBScorersCount++;
    }

    if (teamAScorersCount > scoreA) {
      return 'נבחרו יותר מבקיעים לקבוצה ${widget.teamA.name} ($teamAScorersCount) מכמות השערים ($scoreA)';
    }
    if (teamBScorersCount > scoreB) {
      return 'נבחרו יותר מבקיעים לקבוצה ${widget.teamB.name} ($teamBScorersCount) מכמות השערים ($scoreB)';
    }

    // 2. Validate Assists count vs Goals
    int teamAAssistsCount = 0;
    int teamBAssistsCount = 0;

    for (var id in _selectedAssists) {
      if (widget.teamA.playerIds.contains(id)) teamAAssistsCount++;
      if (widget.teamB.playerIds.contains(id)) teamBAssistsCount++;
    }

    // Usually assists <= goals, but sometimes own goals happen or no assist.
    // Strict rule: assists cannot exceed goals for the team.
    if (teamAAssistsCount > scoreA) {
      return 'נבחרו יותר מבשלים לקבוצה ${widget.teamA.name} ($teamAAssistsCount) מכמות השערים ($scoreA)';
    }
    if (teamBAssistsCount > scoreB) {
      return 'נבחרו יותר מבשלים לקבוצה ${widget.teamB.name} ($teamBAssistsCount) מכמות השערים ($scoreB)';
    }

    return null;
  }

  Future<void> _saveMatchResult() async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      SnackbarHelper.showError(context, 'משתמש לא מחובר');
      return;
    }

    // Run validation
    final validationError = _validateGameLogic();
    if (validationError != null) {
      SnackbarHelper.showError(context, validationError);
      return;
    }

    final record = MatchResult(
      matchId: const Uuid().v4(),
      teamAColor: widget.teamA.color ?? widget.teamA.name,
      teamBColor: widget.teamB.color ?? widget.teamB.name,
      scoreA: scoreA,
      scoreB: scoreB,
      scorerIds: _selectedScorers,
      assistIds: _selectedAssists,
      mvpId: _selectedMvp,
      matchDurationMinutes: widget.durationSeconds ~/ 60,
      createdAt: DateTime.now(),
      loggedBy: currentUserId,
    );

    try {
      // Update player statistics in hub members
      await _updatePlayerStats(record);

      // Save match result (this will also add to match history)
      widget.onSave(record);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בשמירה: $e');
      }
    }
  }

  /// Update player statistics in hub members subcollection
  Future<void> _updatePlayerStats(MatchResult match) async {
    // DATA ACCESS: Use repository to update member stats
    await ref.read(hubsRepositoryProvider).updateMemberStatsFromMatch(
          hubId: widget.hubId,
          scorerIds: match.scorerIds,
          assistIds: match.assistIds,
          mvpId: match.mvpId,
        );
  }

  @override
  Widget build(BuildContext context) {
    // Validate scores - max 5 for winner
    final winnerScore =
        scoreA > scoreB ? scoreA : (scoreB > scoreA ? scoreB : null);
    final isValidScore = winnerScore == null || winnerScore <= 5;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with step indicator
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _getStepTitle(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentStep + 1}/5',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildStepContent(isValidScore),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _currentStep--);
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('חזור'),
                    )
                  else
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ביטול',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  if (_currentStep < 4)
                    ElevatedButton.icon(
                      onPressed: isValidScore
                          ? () {
                              if (_currentStep == 0) {
                                // Validate score
                                if (scoreA == scoreB) {
                                  _showDrawWinnerSelectionDialog();
                                  return;
                                }
                                if (winnerScore != null && winnerScore > 5) {
                                  SnackbarHelper.showError(
                                    context,
                                    'התוצאה המקסימלית למנצח היא 5 שערים',
                                  );
                                  return;
                                }
                              }
                              setState(() => _currentStep++);
                            }
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('המשך'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () => _showConfirmationDialog(),
                      icon: const Icon(Icons.check),
                      label: const Text('תעד תוצאה'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'בחר תוצאה';
      case 1:
        return 'בחר MVP (מהמנצחת)';
      case 2:
        return 'בחר מבקיעים';
      case 3:
        return 'בחר מבשלים';
      case 4:
        return 'אישור סופי';
      default:
        return 'תיעוד תוצאה';
    }
  }

  Widget _buildStepContent(bool isValidScore) {
    switch (_currentStep) {
      case 0:
        return _buildScoreStep(isValidScore);
      case 1:
        return _buildMvpStep();
      case 2:
        return _buildScorersStep();
      case 3:
        return _buildAssistsStep();
      case 4:
        return _buildConfirmStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildScoreStep(bool isValidScore) {
    return Column(
      children: [
        if (!isValidScore)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'התוצאה המקסימלית למנצח היא 5 שערים',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Team A Score Picker
            Expanded(
              child: Column(
                children: [
                  Text(
                    widget.teamA.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: ListWheelScrollView.useDelegate(
                      controller: _scoreAController,
                      itemExtent: 60,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          scoreA = index;
                          // Ensure winner max is 5
                          if (scoreA > scoreB && scoreA > 5) {
                            scoreA = 5;
                            _scoreAController.jumpToItem(5);
                          } else if (scoreB > scoreA && scoreB > 5) {
                            scoreB = 5;
                            _scoreBController.jumpToItem(5);
                          }
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          final value = index;
                          final isSelected = value == scoreA;
                          return Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: isSelected ? 48 : 28,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[300],
                              ),
                              child: Text('$value'),
                            ),
                          );
                        },
                        childCount: 6, // 0-5
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              ':',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w200,
                color: Colors.grey,
              ),
            ),
            // Team B Score Picker
            Expanded(
              child: Column(
                children: [
                  Text(
                    widget.teamB.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: ListWheelScrollView.useDelegate(
                      controller: _scoreBController,
                      itemExtent: 60,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          scoreB = index;
                          // Ensure winner max is 5
                          if (scoreA > scoreB && scoreA > 5) {
                            scoreA = 5;
                            _scoreAController.jumpToItem(5);
                          } else if (scoreB > scoreA && scoreB > 5) {
                            scoreB = 5;
                            _scoreBController.jumpToItem(5);
                          }
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          final value = index;
                          final isSelected = value == scoreB;
                          return Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: isSelected ? 48 : 28,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[300],
                              ),
                              child: Text('$value'),
                            ),
                          );
                        },
                        childCount: 6, // 0-5
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMvpStep() {
    if (_isLoadingPlayers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_winnerTeam == null) {
      return const Center(
        child: Text('יש לבחור מנצחת קודם'),
      );
    }

    final winnerPlayers = _winnerPlayers;
    if (winnerPlayers.isEmpty) {
      return const Center(
        child: Text('אין שחקנים בקבוצה המנצחת'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'בחר MVP מהקבוצה המנצחת: ${_winnerTeam!.name}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...winnerPlayers.map((player) {
          return RadioListTile<String>(
            title: Row(
              children: [
                PlayerAvatar(user: player, radius: 20),
                const SizedBox(width: 12),
                Text(player.name),
              ],
            ),
            value: player.uid,
            groupValue: _selectedMvp,
            onChanged: (value) {
              setState(() {
                _selectedMvp = value;
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildScorersStep() {
    if (_isLoadingPlayers) {
      return const Center(child: CircularProgressIndicator());
    }

    // Count scorers per team for validation
    int teamAScorersCount = _selectedScorers
        .where((id) => widget.teamA.playerIds.contains(id))
        .length;
    int teamBScorersCount = _selectedScorers
        .where((id) => widget.teamB.playerIds.contains(id))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'בחר מבקיעים (ניתן לבחור מספר שחקנים)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'סה"כ שערים: ${scoreA + scoreB}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const Spacer(),
            if (teamAScorersCount > scoreA)
              Text(
                '⚠️ ${widget.teamA.name}: $teamAScorersCount > $scoreA',
                style: TextStyle(color: Colors.red[700], fontSize: 11),
              )
            else if (teamBScorersCount > scoreB)
              Text(
                '⚠️ ${widget.teamB.name}: $teamBScorersCount > $scoreB',
                style: TextStyle(color: Colors.red[700], fontSize: 11),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ..._players.map((player) {
          final isSelected = _selectedScorers.contains(player.uid);
          // Determine team for visual hint
          final isTeamA = widget.teamA.playerIds.contains(player.uid);
          final teamColor = isTeamA ? Colors.blue : Colors.red; // Simplified

          return CheckboxListTile(
            title: Row(
              children: [
                PlayerAvatar(user: player, radius: 20),
                const SizedBox(width: 12),
                Text(player.name),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: teamColor.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedScorers.add(player.uid);
                } else {
                  _selectedScorers.remove(player.uid);
                }
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildAssistsStep() {
    if (_isLoadingPlayers) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'בחר מבשלים (ניתן לבחור מספר שחקנים)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._players.map((player) {
          final isSelected = _selectedAssists.contains(player.uid);
          return CheckboxListTile(
            title: Row(
              children: [
                PlayerAvatar(user: player, radius: 20),
                const SizedBox(width: 12),
                Text(player.name),
              ],
            ),
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedAssists.add(player.uid);
                } else {
                  _selectedAssists.remove(player.uid);
                }
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildConfirmStep() {
    final winnerTeam = _winnerTeam;
    final winnerName = winnerTeam?.name ?? 'תיקו';
    final mvpName = _selectedMvp != null
        ? _players
            .firstWhere(
              (p) => p.uid == _selectedMvp,
              orElse: () => User(
                uid: '',
                name: 'לא ידוע',
                email: '',
                birthDate: DateTime.now(),
                createdAt: DateTime.now(),
              ),
            )
            .name
        : 'לא נבחר';

    final scorersNames = _selectedScorers
        .map((id) => _players
            .firstWhere(
              (p) => p.uid == id,
              orElse: () => User(
                uid: '',
                name: 'לא ידוע',
                email: '',
                birthDate: DateTime.now(),
                createdAt: DateTime.now(),
              ),
            )
            .name)
        .join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'סיכום התוצאה:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildSummaryRow('תוצאה', '$scoreA - $scoreB'),
              _buildSummaryRow('מנצחת', winnerName),
              if (_selectedMvp != null) _buildSummaryRow('MVP', mvpName),
              if (_selectedScorers.isNotEmpty)
                _buildSummaryRow('מבקיעים', scorersNames),
              if (_selectedAssists.isNotEmpty)
                _buildSummaryRow(
                  'מבשלים',
                  _selectedAssists
                      .map((id) => _players
                          .firstWhere(
                            (p) => p.uid == id,
                            orElse: () => User(
                              uid: '',
                              name: 'לא ידוע',
                              email: '',
                              birthDate: DateTime.now(),
                              createdAt: DateTime.now(),
                            ),
                          )
                          .name)
                      .join(', '),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Validation Warning if any
        Builder(builder: (context) {
          final error = _validateGameLogic();
          if (error != null) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(error,
                          style: TextStyle(color: Colors.red[900]))),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog() {
    // Check validation before showing confirmation
    final validationError = _validateGameLogic();
    if (validationError != null) {
      SnackbarHelper.showError(context, validationError);
      return;
    }

    final winnerTeam = _winnerTeam;
    final winnerName = winnerTeam?.name ?? 'תיקו';
    final mvpName = _selectedMvp != null
        ? _players
            .firstWhere(
              (p) => p.uid == _selectedMvp,
              orElse: () => User(
                uid: '',
                name: 'לא ידוע',
                email: '',
                birthDate: DateTime.now(),
                createdAt: DateTime.now(),
              ),
            )
            .name
        : 'לא נבחר';

    final scorersText = _selectedScorers.isEmpty
        ? 'אין מבקיעים'
        : _selectedScorers.map((id) {
            final player = _players.firstWhere(
              (p) => p.uid == id,
              orElse: () => User(
                uid: '',
                name: 'לא ידוע',
                email: '',
                birthDate: DateTime.now(),
                createdAt: DateTime.now(),
              ),
            );
            final count = _selectedScorers.where((i) => i == id).length;
            return count > 1 ? '${player.name} ($count)' : player.name;
          }).join(', ');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('לאשר?'),
        content: Text(
          '$winnerName ניצחו את ${scoreA > scoreB ? widget.teamB.name : widget.teamA.name} $scoreA:$scoreB\n\n'
          '${mvpName != 'לא נבחר' ? 'MVP: $mvpName\n' : ''}'
          'מבקיעים: $scorersText',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation
              _saveMatchResult();
            },
            child: const Text('אישור'),
          ),
        ],
      ),
    );
  }
}

/// Dialog for editing an existing match result
class _MatchEditDialog extends ConsumerStatefulWidget {
  final String hubId;
  final String eventId;
  final String matchId;
  final Team teamA;
  final Team teamB;
  final int initialScoreA;
  final int initialScoreB;
  final List<String> initialScorers;
  final List<String> initialAssists;
  final String? initialMvp;
  final List<String> allPlayerIds;
  final Function(MatchResult) onSave;

  const _MatchEditDialog({
    required this.hubId,
    required this.eventId,
    required this.matchId,
    required this.teamA,
    required this.teamB,
    required this.initialScoreA,
    required this.initialScoreB,
    required this.initialScorers,
    required this.initialAssists,
    required this.initialMvp,
    required this.allPlayerIds,
    required this.onSave,
  });

  @override
  ConsumerState<_MatchEditDialog> createState() => _MatchEditDialogState();
}

class _MatchEditDialogState extends ConsumerState<_MatchEditDialog> {
  late int scoreA;
  late int scoreB;
  late List<String> _selectedScorers;
  late List<String> _selectedAssists;
  String? _selectedMvp;
  List<User> _players = [];
  bool _isLoadingPlayers = true;

  @override
  void initState() {
    super.initState();
    scoreA = widget.initialScoreA;
    scoreB = widget.initialScoreB;
    _selectedScorers = List.from(widget.initialScorers);
    _selectedAssists = List.from(widget.initialAssists);
    _selectedMvp = widget.initialMvp;
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    if (widget.allPlayerIds.isEmpty) {
      setState(() => _isLoadingPlayers = false);
      return;
    }

    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      final players = await usersRepo.getUsers(widget.allPlayerIds);
      if (mounted) {
        setState(() {
          _players = players;
          _isLoadingPlayers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPlayers = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('עריכת תוצאה'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score display with controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  widget.teamA.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$scoreA - $scoreB',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.teamB.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    setState(() {
                      if (scoreA > 0) scoreA--;
                    });
                  },
                ),
                const SizedBox(width: 40),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    setState(() => scoreA++);
                  },
                ),
                const SizedBox(width: 40),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    setState(() {
                      if (scoreB > 0) scoreB--;
                    });
                  },
                ),
                const SizedBox(width: 40),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    setState(() => scoreB++);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Goal Scorers
            ExpansionTile(
              title: const Text('מבקיעים'),
              subtitle: Text(_selectedScorers.isEmpty
                  ? 'לא נבחרו מבקיעים'
                  : '${_selectedScorers.length} מבקיעים'),
              children: [
                if (_isLoadingPlayers)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                else
                  ..._players.map((player) {
                    final isSelected = _selectedScorers.contains(player.uid);
                    return CheckboxListTile(
                      title: Text(player.name),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedScorers.add(player.uid);
                          } else {
                            _selectedScorers.remove(player.uid);
                          }
                        });
                      },
                    );
                  }),
              ],
            ),

            const SizedBox(height: 8),

            // Assists
            ExpansionTile(
              title: const Text('בישולים'),
              subtitle: Text(_selectedAssists.isEmpty
                  ? 'לא נבחרו בישולים'
                  : '${_selectedAssists.length} בישולים'),
              children: [
                if (_isLoadingPlayers)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                else
                  ..._players.map((player) {
                    final isSelected = _selectedAssists.contains(player.uid);
                    return CheckboxListTile(
                      title: Text(player.name),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedAssists.add(player.uid);
                          } else {
                            _selectedAssists.remove(player.uid);
                          }
                        });
                      },
                    );
                  }),
              ],
            ),

            const SizedBox(height: 8),

            // MVP Selection
            ExpansionTile(
              title: const Text('MVP - שחקן מצטיין'),
              subtitle: Text(_selectedMvp == null
                  ? 'לא נבחר MVP'
                  : _players
                      .firstWhere(
                        (p) => p.uid == _selectedMvp,
                        orElse: () => _players.isNotEmpty
                            ? _players.first
                            : User(
                                uid: '',
                                name: 'לא ידוע',
                                email: '',
                                birthDate: DateTime.now(),
                                createdAt: DateTime.now(),
                              ),
                      )
                      .name),
              children: [
                if (_isLoadingPlayers)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                else
                  ..._players.map((player) {
                    return RadioListTile<String>(
                      title: Text(player.name),
                      value: player.uid,
                      groupValue: _selectedMvp,
                      onChanged: (value) {
                        setState(() {
                          _selectedMvp = value;
                        });
                      },
                    );
                  }),
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
          onPressed: () {
            final currentUserId = ref.read(currentUserIdProvider);
            final record = MatchResult(
              matchId: widget.matchId, // Keep same match ID
              teamAColor: widget.teamA.color ?? widget.teamA.name,
              teamBColor: widget.teamB.color ?? widget.teamB.name,
              scoreA: scoreA,
              scoreB: scoreB,
              scorerIds: _selectedScorers,
              assistIds: _selectedAssists,
              mvpId: _selectedMvp,
              matchDurationMinutes: 12, // Keep original duration
              createdAt: DateTime.now(), // Update timestamp
              loggedBy: currentUserId,
            );
            widget.onSave(record);
            Navigator.pop(context);
          },
          child: const Text('שמור שינויים'),
        ),
      ],
    );
  }
}
