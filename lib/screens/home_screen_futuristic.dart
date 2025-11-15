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
import 'package:kickadoor/widgets/futuristic/player_recommendation_card.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/widgets/futuristic/skeleton_loader.dart';
import 'package:kickadoor/widgets/kicka_ball_logo.dart';
import 'package:kickadoor/widgets/availability_toggle.dart';
import 'package:kickadoor/widgets/player_avatar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

/// Futuristic Home Dashboard - Next-gen mobile experience
class HomeScreenFuturistic extends ConsumerStatefulWidget {
  const HomeScreenFuturistic({super.key});

  @override
  ConsumerState<HomeScreenFuturistic> createState() => _HomeScreenFuturisticState();
}

class _HomeScreenFuturisticState extends ConsumerState<HomeScreenFuturistic> {
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
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () => context.push('/notifications'),
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
                            // Availability toggle
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'זמין למשחקים',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF757575),
                                  ),
                                ),
                                Switch(
                                  value: user.availabilityStatus == 'available',
                                  onChanged: (value) {
                                    // Update availability
                                    ref.read(usersRepositoryProvider).updateUser(
                                      currentUserId,
                                      {'availabilityStatus': value ? 'available' : 'notAvailable'},
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
                            child: FutureBuilder<List<Hub>>(
                              future: _getAssociatedHubs(hubsRepo, currentUserId),
                              builder: (context, snapshot) {
                                final associatedHubs = snapshot.data ?? [];
                                return FuturisticCard(
                                  onTap: () => _showAssociatedHubs(context, associatedHubs),
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
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // AI Recommendations - Players
                    Text(
                      'המלצות AI - שחקנים',
                      style: FuturisticTypography.techHeadline,
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<User>>(
                      future: _getRecommendedPlayers(currentUserId, locationService),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const FuturisticLoadingState(
                            message: 'מחפש שחקנים מומלצים...',
                          );
                        }

                        final recommendedPlayers = snapshot.data ?? [];
                        if (recommendedPlayers.isEmpty) {
                          return FuturisticEmptyState(
                            icon: Icons.people_outline,
                            title: 'אין שחקנים מומלצים כרגע',
                            message: 'נסה שוב מאוחר יותר או בדוק הובים קרובים',
                            action: ElevatedButton.icon(
                              onPressed: () => context.push('/discover'),
                              icon: const Icon(Icons.explore),
                              label: const Text('גלה שחקנים'),
                            ),
                          );
                        }

                        return Column(
                          children: recommendedPlayers.map((player) {
                            return FutureBuilder<double?>(
                              future: _calculateDistance(locationService, player),
                              builder: (context, distanceSnapshot) {
                                final distance = distanceSnapshot.data;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: PlayerRecommendationCard(
                                    player: player,
                                    reason: _getRecommendationReason(player),
                                    distanceKm: distance,
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
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

                    // Upcoming Games
                    _UpcomingGamesSection(
                      currentUserId: currentUserId,
                      gamesRepo: gamesRepo,
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

  Future<List<User>> _getRecommendedPlayers(
    String? currentUserId,
    LocationService locationService,
  ) async {
    if (currentUserId == null) return [];

    try {
      final position = await locationService.getCurrentLocation();
      if (position == null) return [];

      final usersRepo = ref.read(usersRepositoryProvider);
      return await usersRepo.getRecommendedPlayers(
        latitude: position.latitude,
        longitude: position.longitude,
        excludeUserId: currentUserId,
        limit: 3,
      );
    } catch (e) {
      return [];
    }
  }

  Future<double?> _calculateDistance(
    LocationService locationService,
    User player,
  ) async {
    if (player.location == null) return null;

    try {
      final position = await locationService.getCurrentLocation();
      if (position == null) return null;

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        player.location!.latitude,
        player.location!.longitude,
      ) / 1000; // Convert to km
      return distance;
    } catch (e) {
      return null;
    }
  }

  String? _getRecommendationReason(User player) {
    if (player.availabilityStatus == 'available') {
      return 'זמין למשחק';
    } else if (player.availabilityStatus == 'busy') {
      return 'עסוק כרגע';
    }
    if (player.currentRankScore >= 8.0) {
      return 'דירוג גבוה';
    }
    return null;
  }

  Future<List<Hub>> _getAssociatedHubs(HubsRepository hubsRepo, String userId) async {
    try {
      final position = await ref.read(locationServiceProvider).getCurrentLocation();
      if (position == null) return [];
      
      final nearbyHubs = await hubsRepo.findHubsNearby(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 50.0,
      );
      
      return nearbyHubs.where((hub) => 
        hub.memberIds.contains(userId) && 
        hub.createdBy != userId
      ).toList();
    } catch (e) {
      return [];
    }
  }

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
                child: ListView.builder(
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
                child: ListView.builder(
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
          ],
        ),
      ),
    );
  }
}

class _UpcomingGamesSection extends ConsumerWidget {
  final String currentUserId;
  final GamesRepository gamesRepo;
  final HubsRepository hubsRepo;

  const _UpcomingGamesSection({
    required this.currentUserId,
    required this.gamesRepo,
    required this.hubsRepo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubsStream = hubsRepo.watchHubsByMember(currentUserId);

    return StreamBuilder<List<Hub>>(
      stream: hubsStream,
      builder: (context, hubsSnapshot) {
        if (hubsSnapshot.connectionState == ConnectionState.waiting) {
          return const FuturisticLoadingState(message: 'טוען הובים...');
        }

        final hubs = hubsSnapshot.data ?? [];
        if (hubs.isEmpty) {
          return const SizedBox.shrink();
        }

        final hubIds = hubs.map((h) => h.hubId).toList();
        final now = DateTime.now();
        final nextWeek = now.add(const Duration(days: 7));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'משחקים קרובים',
              style: FuturisticTypography.techHeadline,
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Game>>(
              future: _getUpcomingGames(hubIds, now, nextWeek),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 3,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SkeletonLoader(height: 100),
                    ),
                  );
                }

                final games = snapshot.data ?? [];
                if (games.isEmpty) {
                  return FuturisticCard(
                    child: Center(
                      child: Text(
                        'אין משחקים קרובים',
                        style: FuturisticTypography.bodyMedium,
                      ),
                    ),
                  );
                }

                return Column(
                  children: games.take(3).map((game) {
                    return FuturisticCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      onTap: () => context.push('/games/${game.gameId}'),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: FuturisticColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.sports_soccer,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm').format(game.gameDate),
                                  style: FuturisticTypography.heading3,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  game.location ?? 'Location TBD',
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
      },
    );
  }

  Future<List<Game>> _getUpcomingGames(
    List<String> hubIds,
    DateTime start,
    DateTime end,
  ) async {
    final allGames = <Game>[];
    for (final hubId in hubIds) {
      final games = await gamesRepo.getGamesByHub(hubId);
      allGames.addAll(games);
    }

    return allGames
        .where((game) =>
            game.gameDate.isAfter(start) && game.gameDate.isBefore(end))
        .toList()
      ..sort((a, b) => a.gameDate.compareTo(b.gameDate));
  }
}

class _NearbyHubsSection extends ConsumerWidget {
  final LocationService locationService;
  final HubsRepository hubsRepo;

  const _NearbyHubsSection({
    required this.locationService,
    required this.hubsRepo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'הובים קרובים',
          style: FuturisticTypography.techHeadline,
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Hub>>(
                  future: _getNearbyHubs(),
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

            return Column(
              children: hubs.take(3).map((hub) {
                return FuturisticCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  onTap: () => context.push('/hubs/${hub.hubId}'),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: FuturisticColors.accentGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.group,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hub.name.toUpperCase(),
                              style: FuturisticTypography.heading3,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${hub.memberIds.length} MEMBERS',
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

  Future<List<Hub>> _getNearbyHubs() async {
    try {
      final position = await locationService.getCurrentLocation();
      if (position == null) return [];
      return await hubsRepo.findHubsNearby(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 10.0,
      );
    } catch (e) {
      return [];
    }
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

