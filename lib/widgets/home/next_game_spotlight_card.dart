import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/data/repositories.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/features/games/data/repositories/game_queries_repository.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';
import 'package:kattrick/features/games/domain/services/event_action_service.dart';
import 'package:kattrick/widgets/premium/premium_live_event_button.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Widget _buildManagerButtons(
      BuildContext context, _NextGameData gameData, HubEvent event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Create Teams button (if no teams exist)
          if (event.teams.isEmpty)
            SizedBox(
              width: double.infinity,
              child: _PremiumCreateTeamsButton(
                onPressed: () {
                  context.push(
                      '/hubs/${gameData.hubId}/events/${gameData.id}/team-generator');
                },
              ),
            ),
          // Start Event button (if teams exist and valid)
          if (event.teams.isNotEmpty &&
              event.teams.every((t) => t.playerIds.isNotEmpty)) ...[
            SizedBox(
              width: double.infinity,
              child: _PremiumStartEventButton(
                onPressed: () async {
                  final actionController = ref
                      .read(eventActionControllerProvider);
                  await actionController.handleStartEvent(
                    context: context,
                    hubId: gameData.hubId,
                    eventId: gameData.id,
                    event: event,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
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
    final gameQueriesRepo = ref.watch(gameQueriesRepositoryProvider);
    final hubEventsRepo = ref.watch(hubEventsRepositoryProvider);

    return StreamBuilder<List<Hub>>(
      stream: hubsRepo.watchHubsByMember(widget.userId),
      builder: (context, hubsSnapshot) {
        final hubs = hubsSnapshot.data ?? [];

        return StreamBuilder<_NextGameData?>(
          stream: _getNextGameStream(
            gameQueriesRepo,
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

            // Check if user is manager for this event
            final currentUserId = ref.watch(currentUserIdProvider);
            final hub = hubs.firstWhere(
              (h) => h.hubId == nextGame.hubId,
              orElse: () => Hub(
                hubId: nextGame.hubId,
                name: nextGame.hubName ?? '',
                createdBy: '',
                createdAt: DateTime.now(),
              ),
            );
            final isManager = currentUserId != null &&
                (hub.createdBy == currentUserId ||
                    hub.managerIds.contains(currentUserId));
            
            // Check if event is within 1 hour before start (for manager actions)
            final now = DateTime.now();
            final oneHourBeforeEvent = nextGame.dateTime.subtract(const Duration(hours: 1));
            final canShowManagerActions = isManager && 
                nextGame.isEvent &&
                !nextGame.dateTime.isBefore(now) && // Event hasn't started yet
                now.isAfter(oneHourBeforeEvent); // Within 1 hour before event

            return _buildGameCard(
              context, 
              nextGame,
              isManager: isManager,
              canShowManagerActions: canShowManagerActions,
            );
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
            PremiumColors.surface,
            PremiumColors.surfaceVariant,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: PremiumColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: const Center(
        child: KineticLoadingAnimation(size: 40),
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

  Widget _buildGameCard(
    BuildContext context, 
    _NextGameData gameData, {
    bool isManager = false,
    bool canShowManagerActions = false,
  }) {
    return ValueListenableBuilder<Duration?>(
      valueListenable: _timeUntilGame,
      builder: (context, countdown, _) {
        final safeCountdown = countdown ?? Duration.zero;
        final isUrgent = safeCountdown.inHours < 24;

        // Check if event is ongoing for navigation
        return StreamBuilder<HubEvent?>(
          stream: gameData.isEvent
              ? ref
                  .read(hubEventsRepositoryProvider)
                  .watchHubEvent(gameData.hubId, gameData.id)
              : null,
          builder: (context, eventSnapshot) {
            final event = eventSnapshot.data;
            final isEventOngoing = gameData.isEvent &&
                event != null &&
                (event.isStarted || event.status == 'ongoing');

            return GestureDetector(
              onTap: () {
                if (gameData.isEvent) {
                  // If event is ongoing, navigate to live match screen
                  if (isEventOngoing) {
                    context.push(
                        '/hubs/${gameData.hubId}/events/${gameData.id}/live');
                  } else {
                    context.push(
                        '/hubs/${gameData.hubId}/events/${gameData.id}/manage');
                  }
                } else {
                  context.push('/games/${gameData.id}');
                }
              },
              child: RepaintBoundary(
                // RepaintBoundary מבודד את הכרטיס - מפחית הבהובים!
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 232,
                    maxHeight: 320, // Allow expansion for manager buttons
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isUrgent
                            ? Colors.orange.withValues(alpha: 0.3)
                            : PremiumColors.primary.withValues(alpha: 0.2),
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
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
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
                                    Flexible(
                                      child: Text(
                                        DateFormat('dd/MM/yyyy · HH:mm')
                                            .format(gameData.dateTime),
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              Colors.white.withValues(alpha: 0.9),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                                      // Navigation icon
                                      if (gameData.isEvent && event != null && event.locationPoint != null)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.navigation,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () async {
                                            final lat = event.locationPoint!.latitude;
                                            final lng = event.locationPoint!.longitude;
                                            final url = Uri.parse(
                                              'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                                            );
                                            try {
                                              if (await canLaunchUrl(url)) {
                                                await launchUrl(url, mode: LaunchMode.externalApplication);
                                              }
                                            } catch (e) {
                                              // Ignore errors
                                            }
                                          },
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),

                          // LIVE Event Button (if event is ongoing and teams are saved)
                          if (gameData.isEvent && isEventOngoing && event.teams.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: RepaintBoundary(
                                child: PremiumLiveEventButton(
                                  onPressed: () {
                                    context.push(
                                        '/hubs/${gameData.hubId}/events/${gameData.id}/live');
                                  },
                                ),
                              ),
                            ),

                          // Manager Action Buttons (only for events, managers, and 1 hour before event)
                          if (gameData.isEvent && canShowManagerActions && !isEventOngoing)
                            RepaintBoundary(
                              child: StreamBuilder<HubEvent?>(
                                stream: ref
                                    .read(hubEventsRepositoryProvider)
                                    .watchHubEvent(gameData.hubId, gameData.id),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting ||
                                      !snapshot.hasData) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  final event = snapshot.data;
                                  if (event == null || 
                                      event.isStarted ||
                                      event.status != 'upcoming' ||
                                      !canShowManagerActions) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  return _buildManagerButtons(context, gameData, event);
                                },
                              ),
                            ),

                          // Footer: Countdown + Participants
                          Row(
                              children: [
                              // Countdown - עטוף ב-RepaintBoundary נוסף!
                              Expanded(
                                child: RepaintBoundary(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
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
                                  vertical: 8,
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
      },
    );
  }

  Stream<_NextGameData?> _getNextGameStream(
    GameQueriesRepository gameQueriesRepo,
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
          final isSignedUp =
              game.denormalized.confirmedPlayerIds.contains(userId);
          if (isSignedUp) {
            final hub = hubsMap[game.hubId];
            allItems.add(_NextGameData(
              id: game.gameId,
              title: null,
              dateTime: game.gameDate,
              location: game.location ?? game.denormalized.venueName,
              hubId: game.hubId ?? '',
              hubName: game.denormalized.hubName ?? hub?.name ?? 'Public Game',
              creatorName: game.denormalized.createdByName ?? 'משתמש',
              participantCount: game.denormalized.confirmedPlayerCount,
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
            // Check if event is live/ongoing
            final isLive = event.isStarted || event.status == 'ongoing' || event.status == 'live';
            
            // Check if event is within duration window (5 hours after start)
            final startTime = event.startedAt ?? event.eventDate;
            final happeningWindowEnd = startTime.add(const Duration(hours: 5));
            final isWithinDurationWindow = now.isBefore(happeningWindowEnd) && 
                (event.isStarted || now.isAfter(startTime.subtract(const Duration(minutes: 30))));
            
            // Include event if:
            // 1. It's live/ongoing, OR
            // 2. It's within the duration window, OR
            // 3. It's upcoming (future event)
            final shouldInclude = isLive || 
                isWithinDurationWindow || 
                (event.eventDate.isAfter(now) && event.eventDate.isBefore(futureLimit));
            
            if (shouldInclude) {
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
    subscriptions.add(gameQueriesRepo.streamMyUpcomingGames(userId).listen((games) {
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

/// Premium Create Teams Button with animation
class _PremiumCreateTeamsButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const _PremiumCreateTeamsButton({
    required this.onPressed,
  });

  @override
  State<_PremiumCreateTeamsButton> createState() => _PremiumCreateTeamsButtonState();
}

class _PremiumCreateTeamsButtonState extends State<_PremiumCreateTeamsButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.onPressed != null ? _scaleAnimation.value : 1.0,
          child: Transform.rotate(
            angle: widget.onPressed != null ? _rotationAnimation.value : 0.0,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF667eea), // Purple
                    Color(0xFF764ba2), // Dark Purple
                    Color(0xFFf093fb), // Pink
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: widget.onPressed != null
                    ? [
                        BoxShadow(
                          color: const Color(0xFF667eea).withValues(
                            alpha: _glowAnimation.value * 0.7,
                          ),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                        BoxShadow(
                          color: const Color(0xFFf093fb).withValues(
                            alpha: _glowAnimation.value * 0.5,
                          ),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.rotate(
                          angle: _rotationAnimation.value * 2,
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'צור כוחות',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Premium Start Event Button with animation
class _PremiumStartEventButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _PremiumStartEventButton({
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<_PremiumStartEventButton> createState() => _PremiumStartEventButtonState();
}

class _PremiumStartEventButtonState extends State<_PremiumStartEventButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.onPressed != null && !widget.isLoading
              ? _scaleAnimation.value
              : 1.0,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF00C853), // Green
                  Color(0xFF00E676), // Light Green
                  Color(0xFF69F0AE), // Lighter Green
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: widget.onPressed != null && !widget.isLoading
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00C853).withValues(
                          alpha: _glowAnimation.value * 0.6,
                        ),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: const Color(0xFF00E676).withValues(
                          alpha: _glowAnimation.value * 0.4,
                        ),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onPressed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else ...[
                        const Icon(
                          Icons.play_arrow_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'התחל אירוע',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
