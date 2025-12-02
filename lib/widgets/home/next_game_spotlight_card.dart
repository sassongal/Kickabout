import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/data/repositories.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/theme/futuristic_theme.dart';

/// Next Game Spotlight Card - Shows the user's next upcoming game/event
///
/// Features:
/// - Countdown timer to game start
/// - Participant count
/// - Hub name or creator name
/// - Stunning spotlight effect
/// - Compact and inviting design
class NextGameSpotlightCard extends ConsumerStatefulWidget {
  final String userId;

  const NextGameSpotlightCard({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<NextGameSpotlightCard> createState() =>
      _NextGameSpotlightCardState();
}

class _NextGameSpotlightCardState extends ConsumerState<NextGameSpotlightCard> {
  Timer? _countdownTimer;
  final ValueNotifier<Duration?> _timeUntilGame = ValueNotifier(null);
  String? _lastItemId;
  DateTime? _lastDateTime;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _timeUntilGame.dispose();
    super.dispose();
  }

  void _startCountdown(DateTime gameDate) {
    _countdownTimer?.cancel();
    _updateCountdown(gameDate);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateCountdown(gameDate);
      }
    });
  }

  void _maybeScheduleCountdown(_NextGameData gameData) {
    if (_lastItemId == gameData.id && _lastDateTime == gameData.dateTime) {
      return;
    }
    _lastItemId = gameData.id;
    _lastDateTime = gameData.dateTime;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startCountdown(gameData.dateTime);
    });
  }

  void _updateCountdown(DateTime gameDate) {
    final now = DateTime.now();
    final difference = gameDate.difference(now);
    // שימוש ב-ValueNotifier במקום setState - עדכון רק הספירה לאחור!
    _timeUntilGame.value = difference.isNegative ? Duration.zero : difference;
  }

  String _formatCountdown(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hubsRepo = ref.watch(hubsRepositoryProvider);
    final gamesRepo = ref.watch(gamesRepositoryProvider);
    final hubEventsRepo = ref.watch(hubEventsRepositoryProvider);

    return StreamBuilder<List<Hub>>(
      stream: hubsRepo.watchHubsByMember(widget.userId),
      builder: (context, hubsSnapshot) {
        final hubs = hubsSnapshot.data ?? [];

        return StreamBuilder<_NextGameData?>(
          stream: _getNextGameStream(
            gamesRepo,
            hubEventsRepo,
            hubs,
            widget.userId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingCard();
            }

            final nextGame = snapshot.data;
            if (nextGame == null) {
              return _buildEmptyCard();
            }

            _maybeScheduleCountdown(nextGame);

            return _buildGameCard(context, nextGame);
          },
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FuturisticColors.surface,
            FuturisticColors.surfaceVariant,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: FuturisticColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: FuturisticColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'אין אירועים קרובים',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'הירשם למשחק או צור אירוע חדש',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, _NextGameData gameData) {
    return ValueListenableBuilder<Duration?>(
      valueListenable: _timeUntilGame,
      builder: (context, countdown, _) {
        final safeCountdown = countdown ?? Duration.zero;
        final isUrgent = safeCountdown.inHours < 24;

        return GestureDetector(
          onTap: () {
            if (gameData.isEvent) {
              context.push('/hubs/${gameData.hubId}/events/${gameData.id}');
            } else {
              context.push('/games/${gameData.id}');
            }
          },
          child: RepaintBoundary(
            // RepaintBoundary מבודד את הכרטיס - מפחית הבהובים!
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: isUrgent
                        ? Colors.orange.withValues(alpha: 0.3)
                        : FuturisticColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Animated gradient background
                    AnimatedContainer(
                      duration: const Duration(seconds: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isUrgent
                              ? [
                                  const Color(0xFFFF6B35),
                                  const Color(0xFFF7931E),
                                  const Color(0xFFFDC830),
                                ]
                              : [
                                  const Color(0xFF667eea),
                                  const Color(0xFF764ba2),
                                  const Color(0xFFf093fb),
                                ],
                        ),
                      ),
                    ),

                    // Spotlight effect overlay
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SpotlightPainter(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header: Type badge + Hub/Creator
                          Row(
                            children: [
                              // Type badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      gameData.isEvent
                                          ? Icons.event
                                          : Icons.sports_soccer,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      gameData.isEvent ? 'אירוע' : 'משחק',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              // Hub/Creator info
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      gameData.hubName != null
                                          ? Icons.group
                                          : Icons.person,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      gameData.hubName ?? gameData.creatorName,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Main content: Title + Date + Location
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (gameData.title != null) ...[
                                Text(
                                  gameData.title!,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.3),
                                        offset: const Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                              ],
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat('dd/MM/yyyy · HH:mm')
                                        .format(gameData.dateTime),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                              if (gameData.location != null) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        gameData.location!,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white
                                              .withValues(alpha: 0.85),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Footer: Countdown + Participants
                          Row(
                            children: [
                              // Countdown - עטוף ב-RepaintBoundary נוסף!
                              Expanded(
                                child: RepaintBoundary(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'מתחיל בעוד',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        // רק החלק הזה מתעדכן כל שניה!
                                        Text(
                                          _formatCountdown(safeCountdown),
                                          style: GoogleFonts.orbitron(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: isUrgent
                                                ? const Color(0xFFFF6B35)
                                                : const Color(0xFF667eea),
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Participants count
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.people,
                                      size: 20,
                                      color: isUrgent
                                          ? const Color(0xFFFF6B35)
                                          : const Color(0xFF667eea),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${gameData.participantCount}',
                                      style: GoogleFonts.orbitron(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: isUrgent
                                            ? const Color(0xFFFF6B35)
                                            : const Color(0xFF667eea),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Stream<_NextGameData?> _getNextGameStream(
    GamesRepository gamesRepo,
    HubEventsRepository hubEventsRepo,
    List<Hub> hubs,
    String userId,
  ) {
    final controller = StreamController<_NextGameData?>();
    final subscriptions = <StreamSubscription>[];

    List<Game> latestGames = [];
    Map<String, List<HubEvent>> latestEventsByHub = {};

    // Create a map for quick hub lookup
    final hubsMap = {for (var h in hubs) h.hubId: h};

    void update() {
      try {
        final now = DateTime.now();
        final futureLimit = now.add(const Duration(days: 30));
        final List<_NextGameData> allItems = [];

        // Process Games
        for (final game in latestGames) {
          // Use denormalized data
          final isSignedUp = game.confirmedPlayerIds.contains(userId);
          if (isSignedUp) {
            final hub = hubsMap[game.hubId];
            allItems.add(_NextGameData(
              id: game.gameId,
              title: null,
              dateTime: game.gameDate,
              location: game.location ?? game.venueName,
              hubId: game.hubId,
              hubName: game.hubName ?? hub?.name,
              creatorName: game.createdByName ?? 'משתמש',
              participantCount: game.confirmedPlayerCount,
              isEvent: false,
            ));
          }
        }

        // Process Events
        for (final entry in latestEventsByHub.entries) {
          final hubId = entry.key;
          final events = entry.value;
          final hub = hubsMap[hubId];

          for (final event in events) {
            if (event.eventDate.isAfter(now) &&
                event.eventDate.isBefore(futureLimit)) {
              final isRegistered = event.registeredPlayerIds.contains(userId);
              if (isRegistered) {
                allItems.add(_NextGameData(
                  id: event.eventId,
                  title: event.title,
                  dateTime: event.eventDate,
                  location: event.location,
                  hubId: hubId,
                  hubName: hub?.name,
                  creatorName: 'מארגן',
                  participantCount: event.registeredPlayerIds.length,
                  isEvent: true,
                ));
              }
            }
          }
        }

        if (allItems.isEmpty) {
          controller.add(null);
        } else {
          allItems.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          controller.add(allItems.first);
        }
      } catch (e) {
        debugPrint('Error in update: $e');
      }
    }

    // Subscribe to games
    subscriptions.add(gamesRepo.streamMyUpcomingGames(userId).listen((games) {
      latestGames = games;
      update();
    }));

    // Subscribe to events for each hub
    for (final hub in hubs) {
      subscriptions
          .add(hubEventsRepo.watchHubEvents(hub.hubId).listen((events) {
        latestEventsByHub[hub.hubId] = events;
        update();
      }));
    }

    controller.onCancel = () {
      for (var sub in subscriptions) {
        sub.cancel();
      }
      controller.close();
    };

    return controller.stream;
  }
}

/// Data class for next game/event
class _NextGameData {
  final String id;
  final String? title;
  final DateTime dateTime;
  final String? location;
  final String hubId;
  final String? hubName;
  final String creatorName;
  final int participantCount;
  final bool isEvent;

  _NextGameData({
    required this.id,
    this.title,
    required this.dateTime,
    this.location,
    required this.hubId,
    this.hubName,
    required this.creatorName,
    required this.participantCount,
    required this.isEvent,
  });
}

/// Custom painter for spotlight effect
class _SpotlightPainter extends CustomPainter {
  final Color color;

  _SpotlightPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.7, -0.5),
        radius: 1.0,
        colors: [
          color,
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
