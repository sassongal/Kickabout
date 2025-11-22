import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/data/repositories.dart';
import 'package:kickadoor/services/location_service.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:kickadoor/widgets/futuristic/gradient_button.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_card.dart';
import 'package:kickadoor/widgets/futuristic/stats_dashboard.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/widgets/futuristic/skeleton_loader.dart';
import 'package:kickadoor/widgets/kicka_ball_logo.dart';
import 'package:kickadoor/widgets/availability_toggle.dart';
import 'package:kickadoor/widgets/player_avatar.dart';
import 'package:kickadoor/widgets/optimized_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kickadoor/services/error_handler_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// Futuristic Home Dashboard - Next-gen mobile experience
class HomeScreenFuturistic extends ConsumerStatefulWidget {
  const HomeScreenFuturistic({super.key});

  @override
  ConsumerState<HomeScreenFuturistic> createState() => _HomeScreenFuturisticState();
}

class _HomeScreenFuturisticState extends ConsumerState<HomeScreenFuturistic> {
  bool _hasRequestedLocationPermission = false;

  @override
  void initState() {
    super.initState();
    // Request location permission when screen is first loaded
    // This happens for both authenticated users and guests
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermission();
    });
  }

  /// Request location permission on home screen entry
  /// This ensures the app has location permission before user tries to use map
  Future<void> _requestLocationPermission() async {
    // Only request once per screen instance
    if (_hasRequestedLocationPermission) return;
    _hasRequestedLocationPermission = true;

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services are disabled');
        return;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // Request permission
        debugPrint('📍 Requesting location permission...');
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Location permission denied by user');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission denied forever. User needs to enable in settings.');
        return;
      }

      // Permission granted - try to get location to verify it works
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        debugPrint('✅ Location permission granted');
        
        // Optionally get location to verify it works (non-blocking)
        // This helps ensure location is available when user opens map
        Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        ).then((position) {
          debugPrint('📍 Location obtained: ${position.latitude}, ${position.longitude}');
        }).catchError((e) {
          debugPrint('⚠️ Could not get location: $e');
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error requesting location permission: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    // Use ref.read for repositories - they don't change, so no need to watch
    final hubsRepo = ref.read(hubsRepositoryProvider);
    final gamesRepo = ref.read(gamesRepositoryProvider);
    final notificationsRepo = ref.read(notificationsRepositoryProvider);
    final gamificationRepo = ref.read(gamificationRepositoryProvider);
    final locationService = ref.read(locationServiceProvider);
    final usersRepo = ref.read(usersRepositoryProvider);

    if (currentUserId == null) {
      return FuturisticScaffold(
        title: 'קיקאוט',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              KickaBallLogo(
                size: 160,
                showText: true,
              ),
              const SizedBox(height: 24),
              Text(
                'ברוכים הבאים',
                style: FuturisticTypography.techHeadline,
              ),
              const SizedBox(height: 8),
              Text(
                'התחבר כדי להמשיך',
                style: FuturisticTypography.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Create streams - Firestore streams are efficient and handle updates automatically
    final unreadCountStream = notificationsRepo.watchUnreadCount(currentUserId);
    final gamificationStream = gamificationRepo.watchGamification(currentUserId);
    final userStream = usersRepo.watchUser(currentUserId);

    return StreamBuilder<User?>(
      stream: userStream,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return FuturisticScaffold(
            title: 'לוח בקרה',
            showBottomNav: true,
            body: const FuturisticLoadingState(message: 'טוען...'),
          );
        }

        if (userSnapshot.hasError) {
          return FuturisticScaffold(
            title: 'לוח בקרה',
            showBottomNav: true,
            body: FuturisticEmptyState(
              icon: Icons.error_outline,
              title: 'שגיאה בטעינת הנתונים',
              message: userSnapshot.error.toString(),
              action: ElevatedButton.icon(
                onPressed: () {
                  // Retry by rebuilding
                  setState(() {});
                },
                icon: const Icon(Icons.refresh),
                label: const Text('נסה שוב'),
              ),
            ),
          );
        }

        final user = userSnapshot.data;
        final availabilityStatus = user?.availabilityStatus ?? 'available';

        return FuturisticScaffold(
          title: 'לוח בקרה',
          showBottomNav: true,
          actions: [
            // Availability Toggle
            if (user != null)
              AvailabilityToggle(
                userId: currentUserId,
                currentStatus: availabilityStatus,
              ),
            StreamBuilder<int>(
              stream: unreadCountStream,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.inbox_outlined),
                      onPressed: () => context.push('/messages'),
                      tooltip: 'הודעות',
                    ),
                    if (count > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: FuturisticColors.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
                    IconButton(
                      icon: const Icon(Icons.people_outlined),
                      onPressed: () => context.push('/players'),
                      tooltip: 'לוח שחקנים',
                    ),
                    IconButton(
                      icon: const Icon(Icons.dashboard_outlined),
                      onPressed: () => context.push('/hubs-board'),
                      tooltip: 'לוח Hubs',
                    ),
                    IconButton(
                      icon: const Icon(Icons.map_outlined),
                      onPressed: () => context.push('/map'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.emoji_events_outlined),
                      onPressed: () => context.push('/leaderboard'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      onPressed: () => context.push('/admin/generate-dummy-data'),
                      tooltip: 'Admin - יצירת נתוני דמה',
                    ),
          ],
          floatingActionButton: GradientButton(
            label: 'צור הוב',
            icon: Icons.add,
            onPressed: () => context.push('/hubs/create'),
            width: 160,
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: FuturisticColors.backgroundGradient,
            ),
            child: RefreshIndicator(
              onRefresh: () async {
                // Force refresh
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Profile Card (matching Figma design)
                    if (user != null) ...[
                      FuturisticCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Avatar
                                PlayerAvatar(
                                  user: user,
                                  size: AvatarSize.lg,
                                ),
                                const SizedBox(width: 16),
                                // Name and city
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF212121),
                                        ),
                                      ),
                                      if (user.city != null)
                                        Text(
                                          user.city!,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: const Color(0xFF757575),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Rating display
                                Column(
                                  children: [
                                    Text(
                                      user.currentRankScore.toStringAsFixed(1),
                                      style: GoogleFonts.montserrat(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1976D2),
                                        height: 1,
                                      ),
                                    ),
                                    Text(
                                      'דירוג',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF757575),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            // Active status toggle
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  user.isActive ? 'פעיל - פתוח להאבים והזמנות' : 'לא פעיל - לא פתוח להאבים והזמנות',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF757575),
                                  ),
                                ),
                                Switch(
                                  value: user.isActive,
                                  onChanged: (value) {
                                    // Update active status
                                    ref.read(usersRepositoryProvider).updateUser(
                                      currentUserId,
                                      {'isActive': value},
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Quick Actions - 3 column grid (matching Figma)
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.add,
                              label: 'צור משחק',
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                              ),
                              onTap: () => context.push('/games/create'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.people,
                              label: 'מצא שחקנים',
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                              ),
                              onTap: () => context.push('/players'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.trending_up,
                              label: 'גלה קהילות',
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                              ),
                              onTap: () => context.push('/hubs-board'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Weather & Vibe Widget
                    const HomeWeatherVibeWidget(),
                    const SizedBox(height: 24),
                    
                    // Stats Dashboard (compact version)
                    StreamBuilder<Gamification?>(
                      stream: gamificationStream,
                      builder: (context, snapshot) {
                        final gamification = snapshot.data;
                        if (gamification != null) {
                          final stats = gamification.stats;
                          return StatsDashboard(
                            gamesPlayed: stats['gamesPlayed'] ?? 0,
                            wins: stats['gamesWon'] ?? 0,
                            averageRating: user?.currentRankScore ?? 5.0,
                            goals: stats['goals'] ?? 0,
                            assists: stats['assists'] ?? 0,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 24),

                    // My Hubs & Associated Hubs
                    // currentUserId is guaranteed to be non-null here (checked at line 44)
                    ...[
                      Row(
                        children: [
                          Expanded(
                            child: StreamBuilder<List<Hub>>(
                              stream: hubsRepo.watchHubsByCreator(currentUserId),
                              builder: (context, snapshot) {
                                final myHubs = snapshot.data ?? [];
                                return FuturisticCard(
                                  onTap: () => _showMyHubs(context, myHubs),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: FuturisticColors.primaryGradient,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.group,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Hubs שפתחתי',
                                        style: FuturisticTypography.labelMedium,
                                      ),
                                      Text(
                                        '${myHubs.length}',
                                        style: FuturisticTypography.bodySmall,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AssociatedHubsCard(
                              hubsRepo: hubsRepo,
                              userId: currentUserId,
                              onTap: (hubs) => _showAssociatedHubs(context, hubs),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Quick Actions - moved up to replace AI Recommendations
                    Text(
                      'פעולות מהירות',
                      style: FuturisticTypography.techHeadline,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FuturisticCard(
                            onTap: () => context.push('/hubs/create'),
                            child: Column(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: FuturisticColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.group_add,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'צור Hub',
                                  style: FuturisticTypography.labelMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FuturisticCard(
                            onTap: () => context.push('/discover'),
                            child: Column(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: FuturisticColors.accentGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.explore,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'גלה',
                                  style: FuturisticTypography.labelMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FuturisticCard(
                            onTap: () => context.push('/map'),
                            child: Column(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        FuturisticColors.secondary,
                                        FuturisticColors.secondaryDark,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.map,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'מפה',
                                  style: FuturisticTypography.labelMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // My Upcoming Games Section
                    _MyUpcomingGamesSection(
                      currentUserId: currentUserId,
                      gamesRepo: gamesRepo,
                    ),
                    const SizedBox(height: 24),
                    
                    // My Hubs Section
                    _MyHubsSection(
                      currentUserId: currentUserId,
                      hubsRepo: hubsRepo,
                    ),
                    const SizedBox(height: 24),

                    // Nearby Hubs
                    _NearbyHubsSection(
                      locationService: locationService,
                      hubsRepo: hubsRepo,
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


  // Removed _getAssociatedHubs - moved to _AssociatedHubsCard widget for optimization

  void _showMyHubs(BuildContext context, List<Hub> hubs) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hubs שפתחתי',
              style: FuturisticTypography.techHeadline,
            ),
            const SizedBox(height: 16),
            if (hubs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('אין Hubs שפתחת'),
              )
            else
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: hubs.length,
                    itemBuilder: (context, index) {
                      final hub = hubs[index];
                      return ListTile(
                        leading: const Icon(Icons.group),
                        title: Text(hub.name),
                        subtitle: Text('${hub.memberIds.length} חברים'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/hubs/${hub.hubId}');
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAssociatedHubs(BuildContext context, List<Hub> hubs) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hub אליו אני משוייך',
              style: FuturisticTypography.techHeadline,
            ),
            const SizedBox(height: 16),
            if (hubs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('אין Hubs אליהם אתה משוייך'),
              )
            else
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: hubs.length,
                    itemBuilder: (context, index) {
                      final hub = hubs[index];
                      return ListTile(
                        leading: const Icon(Icons.people),
                        title: Text(hub.name),
                        subtitle: Text('${hub.memberIds.length} חברים'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/hubs/${hub.hubId}');
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// My Upcoming Games Section - shows games user is signed up for
class _MyUpcomingGamesSection extends ConsumerWidget {
  final String currentUserId;
  final GamesRepository gamesRepo;

  const _MyUpcomingGamesSection({
    required this.currentUserId,
    required this.gamesRepo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingGamesStream = gamesRepo.streamMyUpcomingGames(currentUserId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'המשחקים הבאים שלי',
          style: FuturisticTypography.techHeadline,
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Game>>(
          stream: upcomingGamesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 3,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SkeletonLoader(height: 180, width: 280),
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return FuturisticEmptyState(
                icon: Icons.error_outline,
                title: 'שגיאה בטעינת משחקים',
                message: ErrorHandlerService().handleException(
                  snapshot.error,
                  context: 'Home screen - games loading',
                ),
              );
            }

            final games = snapshot.data ?? [];
            if (games.isEmpty) {
              return FuturisticEmptyState(
                icon: Icons.sports_soccer_outlined,
                title: 'אין משחקים קרובים',
                message: 'כשיהיו משחקים, הם יופיעו כאן',
                action: ElevatedButton.icon(
                  onPressed: () => context.push('/games/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('צור משחק'),
                ),
              );
            }

            return SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 12),
                    child: FuturisticCard(
                      onTap: () => context.push('/games/${game.gameId}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: FuturisticColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.sports_soccer,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(game.gameDate),
                                      style: FuturisticTypography.heading3,
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(game.gameDate),
                                      style: FuturisticTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (game.location != null && game.location!.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: FuturisticColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    game.location!,
                                    style: FuturisticTypography.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Chip(
                                label: Text(_getStatusText(game.status)),
                                backgroundColor: _getStatusColor(game.status).withValues(alpha: 0.1),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: FuturisticColors.textSecondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  String _getStatusText(GameStatus status) {
    switch (status) {
      case GameStatus.teamSelection:
        return 'בחירת קבוצות';
      case GameStatus.teamsFormed:
        return 'מוכן';
      default:
        return status.name;
    }
  }

  Color _getStatusColor(GameStatus status) {
    switch (status) {
      case GameStatus.teamSelection:
        return Colors.orange;
      case GameStatus.teamsFormed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

/// My Hubs Section - shows hubs user is a member of
class _MyHubsSection extends ConsumerWidget {
  final String currentUserId;
  final HubsRepository hubsRepo;

  const _MyHubsSection({
    required this.currentUserId,
    required this.hubsRepo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubsStream = hubsRepo.watchHubsByMember(currentUserId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ההאבים שלי',
          style: FuturisticTypography.techHeadline,
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Hub>>(
          stream: hubsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const FuturisticLoadingState(message: 'טוען הובים...');
            }

            if (snapshot.hasError) {
              return FuturisticEmptyState(
                icon: Icons.error_outline,
                title: 'שגיאה בטעינת הובים',
                message: ErrorHandlerService().handleException(
                  snapshot.error,
                  context: 'Home screen - hubs loading',
                ),
              );
            }

            final hubs = snapshot.data ?? [];
            if (hubs.isEmpty) {
              return FuturisticEmptyState(
                icon: Icons.group_outlined,
                title: 'אין הובים',
                message: 'הצטרף להוב או צור הוב חדש',
                action: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.push('/hubs-board'),
                      icon: const Icon(Icons.explore),
                      label: const Text('גלה הובים'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/hubs/create'),
                      icon: const Icon(Icons.add),
                      label: const Text('צור הוב'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: hubs.take(5).map((hub) {
                return FuturisticCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  onTap: () => context.push('/hubs/${hub.hubId}'),
                  child: Row(
                    children: [
                      // Hub logo or icon
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: FuturisticColors.accentGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: hub.logoUrl != null
                            ? OptimizedImage(
                                imageUrl: hub.logoUrl!,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(12),
                                errorWidget: const Icon(
                                  Icons.group,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              )
                            : const Icon(
                                Icons.group,
                                color: Colors.white,
                                size: 28,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hub.name,
                              style: FuturisticTypography.heading3,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${hub.memberIds.length} חברים',
                              style: FuturisticTypography.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: FuturisticColors.textSecondary,
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _NearbyHubsSection extends ConsumerStatefulWidget {
  final LocationService locationService;
  final HubsRepository hubsRepo;

  const _NearbyHubsSection({
    required this.locationService,
    required this.hubsRepo,
  });

  @override
  ConsumerState<_NearbyHubsSection> createState() => _NearbyHubsSectionState();
}

class _NearbyHubsSectionState extends ConsumerState<_NearbyHubsSection> {
  Future<List<Hub>>? _nearbyHubsFuture;

  @override
  void initState() {
    super.initState();
    // Load nearby hubs once when widget is created
    _loadNearbyHubs();
  }

  void _loadNearbyHubs() {
    _nearbyHubsFuture = _getNearbyHubs();
  }

  Future<List<Hub>> _getNearbyHubs() async {
    try {
      final position = await widget.locationService.getCurrentLocation();
      if (position == null) return [];
      return await widget.hubsRepo.findHubsNearby(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 10.0,
      );
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HUBS קרובים',
          style: FuturisticTypography.techHeadline,
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Hub>>(
          future: _nearbyHubsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const FuturisticLoadingState(
                message: 'מחפש הובים קרובים...',
              );
            }

            final hubs = snapshot.data ?? [];
            if (hubs.isEmpty) {
              return FuturisticCard(
                child: Center(
                  child: Text(
                    'אין הובים קרובים',
                    style: FuturisticTypography.bodyMedium,
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hubs.length,
              itemBuilder: (context, index) {
                final hub = hubs[index];
                return FuturisticCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  onTap: () => context.push('/hubs/${hub.hubId}'),
                  child: Row(
                    children: [
                      // Hub profile image or icon
                      hub.profileImageUrl != null && hub.profileImageUrl!.isNotEmpty
                          ? OptimizedImage(
                              imageUrl: hub.profileImageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(12),
                              errorWidget: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: FuturisticColors.accentGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.group,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: FuturisticColors.accentGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.group,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hub.name,
                              style: FuturisticTypography.heading3,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.group,
                                  size: 16,
                                  color: FuturisticColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${hub.memberIds.length} חברים',
                                  style: FuturisticTypography.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: FuturisticColors.textSecondary,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// Associated Hubs Card - optimized to load once
class _AssociatedHubsCard extends ConsumerStatefulWidget {
  final HubsRepository hubsRepo;
  final String userId;
  final void Function(List<Hub>) onTap;

  const _AssociatedHubsCard({
    required this.hubsRepo,
    required this.userId,
    required this.onTap,
  });

  @override
  ConsumerState<_AssociatedHubsCard> createState() => _AssociatedHubsCardState();
}

class _AssociatedHubsCardState extends ConsumerState<_AssociatedHubsCard> {
  Future<List<Hub>>? _associatedHubsFuture;

  @override
  void initState() {
    super.initState();
    _loadAssociatedHubs();
  }

  void _loadAssociatedHubs() {
    _associatedHubsFuture = _getAssociatedHubs();
  }

  Future<List<Hub>> _getAssociatedHubs() async {
    try {
      final position = await ref.read(locationServiceProvider).getCurrentLocation();
      if (position == null) return [];
      
      final nearbyHubs = await widget.hubsRepo.findHubsNearby(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 50.0,
      );
      
      return nearbyHubs.where((hub) => 
        hub.memberIds.contains(widget.userId) && 
        hub.createdBy != widget.userId
      ).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Hub>>(
      future: _associatedHubsFuture,
      builder: (context, snapshot) {
        final associatedHubs = snapshot.data ?? [];
        return FuturisticCard(
          onTap: () => widget.onTap(associatedHubs),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: FuturisticColors.accentGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.people,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hub אליו אני משוייך',
                style: FuturisticTypography.labelMedium,
                textAlign: TextAlign.center,
              ),
              Text(
                '${associatedHubs.length}',
                style: FuturisticTypography.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Quick Action Button matching Figma design
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Weather & Vibe Widget for Home Screen
class HomeWeatherVibeWidget extends ConsumerWidget {
  const HomeWeatherVibeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(homeDashboardDataProvider);

    return dashboardData.when(
      data: (data) {
        final vibeMessage = data['vibeMessage'] as String? ?? 'יום טוב לכדורגל!';
        final temp = data['temperature'] as int?;
        final aqi = data['aqiIndex'] as int?;

        return FuturisticCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          onTap: () => context.push('/weather'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Vibe Message (משמאל, תופס את רוב המקום)
              Expanded(
                child: Text(
                  vibeMessage,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: FuturisticColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 16),
              // 2. Data Icons (מימין, קומפקטי)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // טמפרטורה
                  if (temp != null) ...[
                    Icon(
                      Icons.thermostat,
                      size: 16,
                      color: FuturisticColors.primary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$temp°',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: FuturisticColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // איכות אוויר
                  if (aqi != null) ...[
                    Icon(
                      Icons.air,
                      size: 16,
                      color: FuturisticColors.secondary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$aqi',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: FuturisticColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SkeletonLoader(height: 100),
      error: (err, stack) => FuturisticEmptyState(
        icon: Icons.cloud_off,
        title: 'שגיאה בטעינת נתוני מזג אוויר',
        message: 'לא ניתן לטעון את נתוני מזג האוויר כרגע',
      ),
    );
  }
}

