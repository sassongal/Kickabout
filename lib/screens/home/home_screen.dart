import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Duplicate import removed
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/core/audio/audio_controller.dart';
import 'package:kattrick/core/constants.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/features/games/data/repositories/game_queries_repository.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/shared/domain/models/value_objects/geographic_point.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';
import 'package:kattrick/widgets/common/home_logo_button.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/widgets/dialogs/location_search_dialog.dart';
import 'package:kattrick/widgets/home/atmospheric_profile_header.dart';
import 'package:kattrick/widgets/home/bubble_menu.dart';
import 'package:kattrick/widgets/home/hubs_carousel.dart';
import 'package:kattrick/widgets/home/next_game_spotlight_card.dart';
import 'package:kattrick/widgets/premium/animated_menu_logo.dart';
import 'package:kattrick/widgets/premium/bottom_navigation_bar.dart';
import 'package:kattrick/widgets/premium/empty_state.dart';
import 'package:kattrick/widgets/premium/loading_state.dart';
import 'package:kattrick/widgets/premium/premium_drawer.dart';
import 'package:kattrick/widgets/stopwatch_countdown_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Premium Home Dashboard - Figma Design Implementation
/// This is a simplified version matching the Figma design exactly
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasPreloaded = false;
  Stream<User?>? _userStream;
  Stream<int>? _unreadCountStream;
  Stream<Gamification?>? _gamificationStream;
  String? _cachedUserId;

  @override
  void initState() {
    super.initState();
    // Schedule prefetching for next frame to avoid blocking initial render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetchData();
      // Ensure background music is playing
      ref.read(audioControllerProvider.notifier).ensurePlaying();
    });
  }

  /// OPTIMIZATION: Prefetch common data to warm up the cache
  void _prefetchData() {
    if (_hasPreloaded) return;
    _hasPreloaded = true;

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    final hubsRepo = ref.read(hubsRepositoryProvider);
    final usersRepo = ref.read(usersRepositoryProvider);

    // Prefetch user and hubs in parallel (will be cached for immediate use)
    Future.wait([
      usersRepo.getUser(currentUserId),
      hubsRepo.getHubsByMember(currentUserId),
    ]).then((_) {
      debugPrint('✅ Prefetch completed successfully');
    }).catchError((e) {
      // Silently fail - data will be fetched on demand if prefetch fails
      debugPrint('⚠️ Prefetch failed (non-critical): $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final hubsRepo = ref.read(hubsRepositoryProvider);
    final notificationsRepo = ref.read(notificationsRepositoryProvider);
    final gamificationRepo = ref.read(gamificationRepositoryProvider);
    final usersRepo = ref.read(usersRepositoryProvider);

    if (currentUserId == null) {
      // Clear cached streams when user logs out
      _userStream = null;
      _unreadCountStream = null;
      _gamificationStream = null;
      _cachedUserId = null;

      return Scaffold(
        backgroundColor: PremiumColors.background,
        appBar: AppBar(
          title: const HomeLogoButton(
            height: 56,
            padding: EdgeInsets.zero,
          ),
          backgroundColor: PremiumColors.surface,
          foregroundColor: PremiumColors.textPrimary,
          elevation: 0,
          automaticallyImplyLeading: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: PremiumColors.surfaceVariant,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ברוכים הבאים',
                style: PremiumTypography.techHeadline,
              ),
              const SizedBox(height: 8),
              Text(
                'התחבר כדי להמשיך',
                style: PremiumTypography.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    // OPTIMIZATION: Only recreate streams if userId changed
    // This prevents stream recreation on every rebuild, eliminating flickering
    if (_cachedUserId != currentUserId) {
      _cachedUserId = currentUserId;
      _userStream = usersRepo.watchUser(currentUserId);
      _unreadCountStream = notificationsRepo.watchUnreadCount(currentUserId);
      _gamificationStream = gamificationRepo.watchGamification(currentUserId);
    }

    final unreadCountStream = _unreadCountStream!;
    final gamificationStream = _gamificationStream!;
    final userStream = _userStream!;

    return StreamBuilder<User?>(
      stream: userStream,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: PremiumColors.background,
            appBar:
                _buildAppBar(context, null, unreadCountStream, currentUserId),
            body: const PremiumLoadingState(message: 'טוען...'),
          );
        }

        if (userSnapshot.hasError) {
          return Scaffold(
            backgroundColor: PremiumColors.background,
            appBar:
                _buildAppBar(context, null, unreadCountStream, currentUserId),
            body: PremiumEmptyState(
              icon: Icons.error_outline,
              title: 'שגיאה בטעינת הנתונים',
              message: userSnapshot.error.toString(),
            ),
          );
        }

        final user = userSnapshot.data;

        // Figma design: Custom AppBar with DASHBOARD title, Bell icon, and Avatar
        return Scaffold(
          backgroundColor: Colors.transparent, // Transparent for Prism
          extendBodyBehindAppBar:
              false, // Prevent header from going under app bar
          drawer: PremiumDrawer(
            user: user,
            currentUserId: currentUserId,
            onLogout: () => _showLogoutDialog(context, currentUserId),
          ),
          appBar: _buildAppBar(context, user, unreadCountStream, currentUserId),
          bottomNavigationBar: PremiumBottomNavBar(
            currentRoute: GoRouterState.of(context).uri.toString(),
          ),
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: PremiumColors.backgroundGradient,
                ),
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Force refresh
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Atmospheric profile header with time-based backgrounds
                        if (user != null) ...[
                          AtmosphericProfileHeader(
                            user: user,
                            currentUserId: currentUserId,
                          ),
                        ],

                        // Rest of the content with consistent padding
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),

                              // Next Game Spotlight Card - Shows upcoming game/event
                              NextGameSpotlightCard(userId: currentUserId),

                              // Removed old redundant "To All Events" link

                              const SizedBox(height: 16),

                              // Admin Tasks Card (if user is admin)
                              _buildAdminTasksCard(context, currentUserId),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),

                        // My Hubs Carousel (Unified) + Upcoming Games
                        // OPTIMIZED: Single stream query for both carousel and games
                        StreamBuilder<List<Hub>>(
                          stream: hubsRepo.watchAllMyHubs(currentUserId),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const SizedBox.shrink();
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: KineticLoadingAnimation(size: 40));
                            }

                            final hubs = snapshot.data ?? [];
                            final hubIds = hubs.map((h) => h.hubId).toList();
                            final now = DateTime.now();
                            final nextWeek = now.add(const Duration(days: 7));

                            return Column(
                              children: [
                                // Hubs Carousel
                                HubsCarousel(
                                  hubs: hubs,
                                  currentUserId: currentUserId,
                                ),
                                const SizedBox(height: 24),

                                // Upcoming Games Section
                                FutureBuilder<List<Game>>(
                                  future: _getUpcomingGames(
                                      ref.read(gameQueriesRepositoryProvider),
                                      hubIds,
                                      now,
                                      nextWeek),
                                  builder: (context, gamesSnapshot) {
                                    final games = gamesSnapshot.data ?? [];
                                    if (games.isEmpty) {
                                      return const SizedBox.shrink();
                                    }

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'UPCOMING GAMES',
                                          style: GoogleFonts.orbitron(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 2.0,
                                            color: const Color(0xFF212121),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ...games.take(2).map((game) => Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 12),
                                              child: PremiumCard(
                                                onTap: () => context.push(
                                                    '/games/${game.gameId}'),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_today,
                                                      color:
                                                          PremiumColors.primary,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            DateFormat(
                                                                    'dd/MM HH:mm')
                                                                .format(game
                                                                    .gameDate),
                                                            style: GoogleFonts
                                                                .montserrat(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: const Color(
                                                                  0xFF212121),
                                                            ),
                                                          ),
                                                          if (game.location !=
                                                              null)
                                                            Text(
                                                              game.location!,
                                                              style: GoogleFonts
                                                                  .inter(
                                                                fontSize: 14,
                                                                color: const Color(
                                                                    0xFF757575),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    // Signup count (simplified - just show status)
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: PremiumColors
                                                            .secondary,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                      ),
                                                      child: Builder(
                                                        builder: (context) {
                                                          final signupsRepo =
                                                              ref.read(
                                                                  signupsRepositoryProvider);
                                                          return StreamBuilder<
                                                              List<GameSignup>>(
                                                            stream: signupsRepo
                                                                .watchSignups(
                                                                    game.gameId),
                                                            builder: (context,
                                                                signupsSnapshot) {
                                                              final signups =
                                                                  signupsSnapshot
                                                                          .data ??
                                                                      [];
                                                              final confirmedCount = signups
                                                                  .where((s) =>
                                                                      s.status ==
                                                                      SignupStatus
                                                                          .confirmed)
                                                                  .length;
                                                              final minRequired = game
                                                                      .teamCount *
                                                                  AppConstants
                                                                      .minPlayersPerTeam;
                                                              return Text(
                                                                '$confirmedCount/$minRequired',
                                                                style: GoogleFonts
                                                                    .montserrat(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              );
                                                            },
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Developer Tools & Admin Console
                        if (user != null) ...[
                          // Admin Console Button (prominent)
                          ElevatedButton.icon(
                            onPressed: () => context.push('/admin/dashboard'),
                            icon: const Icon(Icons.admin_panel_settings),
                            label: const Text('Admin Console'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),

                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const QuickActionsBubbleMenu(),
            ],
          ),
        );
      },
    );
  }

  /// Show logout confirmation dialog
  Future<void> _showLogoutDialog(BuildContext context, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PremiumColors.surface,
        title: Text(
          'התנתקות',
          style: PremiumTypography.heading3.copyWith(
            color: PremiumColors.textPrimary,
          ),
        ),
        content: Text(
          'האם אתה בטוח שברצונך להתנתק?',
          style: PremiumTypography.bodyMedium.copyWith(
            color: PremiumColors.textSecondary,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: PremiumColors.surfaceVariant,
            width: 1,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'ביטול',
              style: PremiumTypography.labelLarge.copyWith(
                color: PremiumColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'התנתק',
              style: PremiumTypography.labelLarge,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();

      if (!mounted) return;

      SnackbarHelper.showSuccess(
        context,
        'התנתקת בהצלחה',
      );

      if (!mounted) return;
      context.go('/auth');
    } catch (e) {
      if (!mounted) return;

      SnackbarHelper.showError(
        context,
        'שגיאה בהתנתקות: ${e.toString()}',
      );
    }
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    User? user,
    Stream<int> unreadCountStream,
    String currentUserId,
  ) {
    return AppBar(
      toolbarHeight: 72, // Increased from default 56
      leading: const AnimatedMenuLogo(size: 80),
      leadingWidth: 90,
      title: null, // Title replaced by logo
      backgroundColor: Colors.transparent,
      foregroundColor: PremiumColors.textPrimary,
      elevation: 0,
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: PremiumColors.surfaceVariant,
        ),
      ),
      actions: [
        // Inbox icon - Premium style
        _PremiumIconButton(
          icon: Icons.inbox_outlined,
          onPressed: () => context.push('/messages'),
          tooltip: 'הודעות',
        ),
        // Stopwatch/Countdown Timer
        const StopwatchCountdownWidget(),
        // Discover icon - Premium style
        _PremiumIconButton(
          icon: Icons.explore_outlined,
          onPressed: () => context.push('/discover'),
          tooltip: 'גלה הובים',
        ),
        // Leaderboard icon - Premium style
        _PremiumIconButton(
          icon: Icons.emoji_events_outlined,
          onPressed: () => context.push('/leaderboard'),
          tooltip: 'שולחן מובילים',
        ),
        // Audio Toggle - Header
        // Notifications icon with badge - Premium style
        StreamBuilder<int>(
          stream: unreadCountStream,
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _PremiumIconButton(
                    icon: Icons.notifications_outlined,
                    onPressed: () => context.push('/notifications'),
                    tooltip: 'התראות',
                  ),
                  if (count > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: PremiumColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: PremiumColors.surface,
                            width: 2,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            count > 9 ? '9+' : count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        // Profile button removed - Menu is now in the Drawer via Logo
      ],
    );
  }

  /// Get upcoming games from user's hubs
  Future<List<Game>> _getUpcomingGames(
    GameQueriesRepository gameQueriesRepo,
    List<String> hubIds,
    DateTime start,
    DateTime end,
  ) async {
    final allGames = <Game>[];
    for (final hubId in hubIds) {
      final games = await gameQueriesRepo.getGamesByHub(hubId);
      allGames.addAll(games);
    }

    return allGames
        .where((game) =>
            game.gameDate.isAfter(start) && game.gameDate.isBefore(end))
        .toList()
      ..sort((a, b) => a.gameDate.compareTo(b.gameDate));
  }

  Widget _buildAdminTasksCard(BuildContext context, String? currentUserId) {
    if (currentUserId == null) {
      return const SizedBox.shrink();
    }

    final adminTasksAsync = ref.watch(adminTasksProvider);

    return adminTasksAsync.when(
      data: (stuckGamesCount) {
        if (stuckGamesCount == 0) {
          return const SizedBox.shrink();
        }

        return PremiumCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'משימות ניהול',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212121),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'יש לך $stuckGamesCount משחקים שממתינים לסגירה.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to games list filtered by stuck games
                  context.push('/games?filter=stuck');
                },
                icon: const Icon(Icons.update),
                label: const Text('עדכן תוצאות'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

/// Location Toggle Button for AppBar
/// Supports GPS mode and Manual Location mode
class _LocationToggleButton extends ConsumerStatefulWidget {
  const _LocationToggleButton();

  @override
  ConsumerState<_LocationToggleButton> createState() =>
      _LocationToggleButtonState();
}

class _LocationToggleButtonState extends ConsumerState<_LocationToggleButton> {
  bool _isGpsMode = false;
  bool _isManualMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLocationMode();
  }

  Future<void> _checkLocationMode() async {
    try {
      final permission = await Geolocator.checkPermission();
      final prefs = await SharedPreferences.getInstance();
      final hasManualLocation =
          prefs.getBool('location_permission_skipped') ?? false;

      setState(() {
        _isGpsMode = permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always;
        _isManualMode = hasManualLocation && !_isGpsMode;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLocation() async {
    try {
      final permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.deniedForever) {
        // Open app settings or show manual location dialog
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('הרשאת מיקום נדחתה לצמיתות'),
            content: const Text(
              'האם תרצה להגדיר מיקום ידני במקום?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('ביטול'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('הגדר מיקום ידני'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await _openManualLocationDialog();
        } else if (await openAppSettings()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('פתח את הגדרות האפליקציה כדי לאפשר מיקום'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
        return;
      }

      // If GPS is enabled, offer to switch to manual
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('מיקום GPS פעיל'),
            content: const Text(
              'האם תרצה לכבות GPS ולהגדיר מיקום ידני?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('ביטול'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('הגדר מיקום ידני'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await _openManualLocationDialog();
        }
      } else {
        // GPS is not enabled - request permission or show manual dialog
        final newPermission = await Geolocator.requestPermission();

        if (newPermission == LocationPermission.denied ||
            newPermission == LocationPermission.deniedForever) {
          // Offer manual location
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('הרשאת מיקום נדחתה'),
              content: const Text(
                'האם תרצה להגדיר מיקום ידני?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('ביטול'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('הגדר מיקום ידני'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await _openManualLocationDialog();
          }
        } else {
          // GPS permission granted
          setState(() {
            _isGpsMode = true;
            _isManualMode = false;
          });

          // Get current location and update user profile
          final locationService = ref.read(locationServiceProvider);
          final position = await locationService.getCurrentLocation();

          if (position != null && mounted) {
            final auth = firebase_auth.FirebaseAuth.instance;
            final user = auth.currentUser;

            if (user != null) {
              final firestore = FirebaseFirestore.instance;
              final userRef = firestore.collection('users').doc(user.uid);
              final geohash = locationService.generateGeohash(
                position.latitude,
                position.longitude,
              );

              await userRef.update({
                'location': GeographicPoint(
                  latitude: position.latitude,
                  longitude: position.longitude,
                ),
                'geohash': geohash,
                'hasManualLocation': false,
              });

              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('location_permission_skipped', false);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ מיקום GPS עודכן'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        }
      }

      await _checkLocationMode(); // Refresh state
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openManualLocationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const LocationSearchDialog(),
    );

    if (result == true) {
      await _checkLocationMode(); // Refresh state after manual location set
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // Determine icon and color based on mode
    IconData icon;
    Color iconColor;
    String tooltip;

    if (_isGpsMode) {
      icon = Icons.gps_fixed;
      iconColor = PremiumColors.primary;
      tooltip = 'GPS פעיל - לחץ לניהול';
    } else if (_isManualMode) {
      icon = Icons.edit_location;
      iconColor = PremiumColors.secondary;
      tooltip = 'מיקום ידני - לחץ לניהול';
    } else {
      icon = Icons.location_off;
      iconColor = PremiumColors.textSecondary;
      tooltip = 'מיקום מושבת - לחץ להפעיל';
    }

    return IconButton(
      icon: Icon(icon, color: iconColor),
      onPressed: _toggleLocation,
      tooltip: tooltip,
    );
  }
}

/// Premium Icon Button - עיצוב פרימיום לאייקונים ב-AppBar
class _PremiumIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _PremiumIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Tooltip(
            message: tooltip,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    PremiumColors.surfaceVariant.withValues(alpha: 0.5),
                    PremiumColors.surface.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: PremiumColors.primary.withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: PremiumColors.primary.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 26,
                color: PremiumColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
