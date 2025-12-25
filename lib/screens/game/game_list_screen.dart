import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sliver_tools/sliver_tools.dart';

import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/premium/skeleton_loader.dart';
import 'package:kattrick/widgets/premium/empty_state.dart';
import 'package:kattrick/widgets/premium/empty_state_illustrations.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';

import 'package:kattrick/widgets/game/my_next_match_card.dart';
import 'package:kattrick/widgets/game/game_feed_card.dart';
import 'package:google_fonts/google_fonts.dart';

/// Selected hub provider (for filtering games)
final selectedHubProvider = StateProvider<String?>((ref) => null);

/// Game list screen - The Game Board
class GameListScreen extends ConsumerStatefulWidget {
  const GameListScreen({super.key});

  @override
  ConsumerState<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends ConsumerState<GameListScreen> {
  GeoPoint? _userLocation;
  Stream<Game?>? _cachedNextMatchStream;
  Stream<List<Game>>? _cachedDiscoveryStream;
  Stream<List<Hub>>? _cachedUserHubsStream;
  String? _cachedUserId;
  GeoPoint? _cachedLocation;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      setState(() {
        _userLocation = GeoPoint(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameQueriesRepo = ref.watch(gameQueriesRepositoryProvider);
    final hubsRepo = ref.watch(hubsRepositoryProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    if (currentUserId == null) {
      // Clear cached streams when user logs out
      _cachedNextMatchStream = null;
      _cachedDiscoveryStream = null;
      _cachedUserHubsStream = null;
      _cachedUserId = null;
      return const SizedBox.shrink();
    }

    // OPTIMIZATION: Only recreate streams if userId or location changed
    // This prevents stream recreation on every rebuild, eliminating flickering
    final locationChanged = _cachedLocation != _userLocation;
    if (_cachedUserId != currentUserId || locationChanged) {
      _cachedUserId = currentUserId;
      _cachedLocation = _userLocation;
      _cachedNextMatchStream = gameQueriesRepo.watchNextMatch(currentUserId);
      _cachedDiscoveryStream = gameQueriesRepo.watchDiscoveryFeed(
        userLocation: _userLocation,
        radiusKm: 10.0,
      );
      _cachedUserHubsStream = hubsRepo.watchHubsByMember(currentUserId);
    }

    final nextMatchStream = _cachedNextMatchStream!;
    final discoveryStream = _cachedDiscoveryStream!;
    final userHubsStream = _cachedUserHubsStream!;

    return AppScaffold(
      title: 'לוח משחקים',
      showBottomNav: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => context.push('/calendar'),
          tooltip: 'לוח שנה',
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/games/create'),
        icon: const Icon(Icons.add),
        label: const Text('צור משחק'),
      ),
      body: StreamBuilder<List<Hub>>(
        stream: userHubsStream,
        builder: (context, hubsSnapshot) {
          final userHubIds =
              hubsSnapshot.data?.map((h) => h.hubId).toSet() ?? {};

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh logic if needed (streams auto-update usually)
              setState(() {});
            },
            child: CustomScrollView(
              slivers: [
                // 1. My Next Match Section
                SliverToBoxAdapter(
                  child: StreamBuilder<Game?>(
                    stream: nextMatchStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                'המשחק הבא',
                                style: GoogleFonts.rubik(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            MyNextMatchCard(game: snapshot.data!),
                            const SizedBox(height: 16),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),

                // 2. Discovery Feed Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          'משחקים בסביבה',
                          style: GoogleFonts.rubik(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        // TODO: Add region filter button here
                      ],
                    ),
                  ),
                ),

                // 3. Discovery Feed List
                StreamBuilder<List<Game>>(
                  stream: discoveryStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const SkeletonGameCard(),
                          childCount: 3,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: PremiumEmptyState(
                          icon: Icons.error_outline,
                          title: 'שגיאה בטעינת משחקים',
                          message: 'אנא נסה שוב מאוחר יותר',
                        ),
                      );
                    }

                    final games = snapshot.data ?? [];

                    if (games.isEmpty) {
                      return SliverToBoxAdapter(
                        child: PremiumEmptyState(
                          icon: Icons.sports_soccer_outlined,
                          title: 'אין משחקים בסביבה',
                          message: 'היה הראשון ליצור משחק!',
                          illustration: const EmptyGamesIllustration(),
                          action: ElevatedButton.icon(
                            onPressed: () => context.push('/games/create'),
                            icon: const Icon(Icons.add),
                            label: const Text('צור משחק'),
                          ),
                        ),
                      );
                    }

                    // Group games by date
                    final groupedGames = _groupGamesByDate(games);

                    // Build sliver list with sticky headers
                    return MultiSliver(
                      children: groupedGames.entries.map((entry) {
                        final dateLabel = entry.key;
                        final gamesForDate = entry.value;

                        return MultiSliver(
                          children: [
                            // Sticky Date Header
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _DateHeaderDelegate(
                                minHeight: 40,
                                maxHeight: 40,
                                child: Container(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withValues(alpha: 0.95),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getIconForDate(dateLabel),
                                        size: 20,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        dateLabel,
                                        style: GoogleFonts.rubik(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${gamesForDate.length} משחקים',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Games for this date
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final game = gamesForDate[index];

                                  // Determine state
                                  final isPublic = game.hubId == null;
                                  final isMyHub = game.hubId != null &&
                                      userHubIds.contains(game.hubId);
                                  final isLocked =
                                      game.hubId != null && !isMyHub;

                                  // Calculate distance if location available
                                  double? distance;
                                  if (_userLocation != null &&
                                      game.locationPoint != null) {
                                    final distanceMeters =
                                        Geolocator.distanceBetween(
                                      _userLocation!.latitude,
                                      _userLocation!.longitude,
                                      game.locationPoint!.latitude,
                                      game.locationPoint!.longitude,
                                    );
                                    distance =
                                        distanceMeters / 1000; // Convert to km
                                  }

                                  return GameFeedCard(
                                    game: game,
                                    isLocked: isLocked,
                                    isMyHub: isMyHub,
                                    isPublic: isPublic,
                                    distanceKm: distance,
                                  );
                                },
                                childCount: gamesForDate.length,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),

                // Bottom padding for FAB
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Group games by date labels (Today, Tomorrow, This Week, Later)
  Map<String, List<Game>> _groupGamesByDate(List<Game> games) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    final Map<String, List<Game>> grouped = {
      'היום': [],
      'מחר': [],
      'השבוע': [],
      'מאוחר יותר': [],
    };

    for (final game in games) {
      final gameDate = DateTime(
        game.gameDate.year,
        game.gameDate.month,
        game.gameDate.day,
      );

      if (gameDate == today) {
        grouped['היום']!.add(game);
      } else if (gameDate == tomorrow) {
        grouped['מחר']!.add(game);
      } else if (gameDate.isBefore(weekEnd)) {
        grouped['השבוע']!.add(game);
      } else {
        grouped['מאוחר יותר']!.add(game);
      }
    }

    // Remove empty groups
    grouped.removeWhere((key, value) => value.isEmpty);

    return grouped;
  }

  /// Get icon for date label
  IconData _getIconForDate(String dateLabel) {
    switch (dateLabel) {
      case 'היום':
        return Icons.today;
      case 'מחר':
        return Icons.wb_sunny_outlined;
      case 'השבוע':
        return Icons.date_range;
      case 'מאוחר יותר':
        return Icons.event;
      default:
        return Icons.calendar_today;
    }
  }
}

/// Delegate for sticky date headers
class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _DateHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_DateHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
