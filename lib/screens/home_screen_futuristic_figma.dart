import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kickadoor/widgets/futuristic/bottom_navigation_bar.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/data/repositories.dart';

import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/core/constants.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_card.dart';
import 'package:kickadoor/widgets/futuristic/stats_dashboard.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/widgets/futuristic/skeleton_loader.dart';
import 'package:kickadoor/widgets/player_avatar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kickadoor/scripts/generate_dummy_data.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kickadoor/widgets/dialogs/location_search_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Futuristic Home Dashboard - Figma Design Implementation
/// This is a simplified version matching the Figma design exactly
class HomeScreenFuturisticFigma extends ConsumerStatefulWidget {
  const HomeScreenFuturisticFigma({super.key});

  @override
  ConsumerState<HomeScreenFuturisticFigma> createState() =>
      _HomeScreenFuturisticFigmaState();
}

class _HomeScreenFuturisticFigmaState
    extends ConsumerState<HomeScreenFuturisticFigma> {
  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final hubsRepo = ref.read(hubsRepositoryProvider);
    final gamesRepo = ref.read(gamesRepositoryProvider);
    final notificationsRepo = ref.read(notificationsRepositoryProvider);
    final gamificationRepo = ref.read(gamificationRepositoryProvider);
    final usersRepo = ref.read(usersRepositoryProvider);

    if (currentUserId == null) {
      return Scaffold(
        backgroundColor: FuturisticColors.background,
        appBar: AppBar(
          title: Text(
            'DASHBOARD',
            style: GoogleFonts.orbitron(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              color: FuturisticColors.textPrimary,
            ),
          ),
          backgroundColor: FuturisticColors.surface,
          foregroundColor: FuturisticColors.textPrimary,
          elevation: 0,
          automaticallyImplyLeading: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: FuturisticColors.surfaceVariant,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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

    final unreadCountStream = notificationsRepo.watchUnreadCount(currentUserId);
    final gamificationStream =
        gamificationRepo.watchGamification(currentUserId);
    final userStream = usersRepo.watchUser(currentUserId);

    return StreamBuilder<User?>(
      stream: userStream,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: FuturisticColors.background,
            appBar:
                _buildAppBar(context, null, unreadCountStream, currentUserId),
            body: const FuturisticLoadingState(message: 'טוען...'),
          );
        }

        if (userSnapshot.hasError) {
          return Scaffold(
            backgroundColor: FuturisticColors.background,
            appBar:
                _buildAppBar(context, null, unreadCountStream, currentUserId),
            body: FuturisticEmptyState(
              icon: Icons.error_outline,
              title: 'שגיאה בטעינת הנתונים',
              message: userSnapshot.error.toString(),
            ),
          );
        }

        final user = userSnapshot.data;

        // Figma design: Custom AppBar with DASHBOARD title, Bell icon, and Avatar
        return Scaffold(
          backgroundColor: FuturisticColors.background,
          appBar: _buildAppBar(context, user, unreadCountStream, currentUserId),
          bottomNavigationBar: FuturisticBottomNavBar(
            currentRoute: GoRouterState.of(context).uri.toString(),
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
                    // Admin Tasks Card (if user is admin)
                    _buildAdminTasksCard(context, currentUserId),
                    const SizedBox(height: 16),

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
                                // Name and city ONLY (Rating removed)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name, // השם המלא כפי שמוגדר
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
                                // REMOVED: The Column with currentRankScore
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
                                    ref
                                        .read(usersRepositoryProvider)
                                        .updateUser(
                                      currentUserId,
                                      {
                                        'availabilityStatus':
                                            value ? 'available' : 'notAvailable'
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16), // Reduced space

                      // כותרת קטנה לפעולות מהירות (אופציונלי, אפשר גם להוריד לגמרי)
                      Text(
                        'פעולות מהירות',
                        style: FuturisticTypography.bodySmall
                            .copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),

                      // Quick Actions - Updated Layout
                      Row(
                        children: [
                          // 1. צור הוב (עבר לכאן)
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.add_business, // או אייקון אחר מתאים
                              label: 'צור Hub',
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF9C27B0),
                                  Color(0xFF7B1FA2)
                                ], // סגול
                              ),
                              onTap: () => context.push('/hubs/create'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 2. צור משחק
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.sports_soccer,
                              label: 'צור משחק',
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1976D2),
                                  Color(0xFF1565C0)
                                ], // כחול
                              ),
                              onTap: () => context.push('/games/create'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 3. מצא שחקנים
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.person_search,
                              label: 'מצא שחקנים',
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF4CAF50),
                                  Color(0xFF388E3C)
                                ], // ירוק
                              ),
                              onTap: () => context.push('/players'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16), // Reduced space
                    ],

                    // Weather & Vibe Widget (moved to top)
                    const HomeWeatherVibeWidget(),
                    const SizedBox(height: 24),

                    // Stats Dashboard (matching Figma)
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

                    // My Hubs section (simplified for Figma)
                    StreamBuilder<List<Hub>>(
                      stream: hubsRepo.watchHubsByMember(currentUserId),
                      builder: (context, snapshot) {
                        final hubs = snapshot.data ?? [];
                        if (hubs.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MY HUBS',
                              style: GoogleFonts.orbitron(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.0,
                                color: const Color(0xFF212121),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...hubs.take(3).map((hub) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: FuturisticCard(
                                    onTap: () =>
                                        context.push('/hubs/${hub.hubId}'),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: FuturisticColors
                                                .primaryGradient,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.group,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                hub.name,
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      const Color(0xFF212121),
                                                ),
                                              ),
                                              Text(
                                                '${hub.memberIds.length} חברים',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  color:
                                                      const Color(0xFF757575),
                                                ),
                                              ),
                                            ],
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
                    const SizedBox(height: 24),

                    // My Hubs & Associated Hubs
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
                                        gradient:
                                            FuturisticColors.primaryGradient,
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
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF212121),
                                      ),
                                    ),
                                    Text(
                                      '${myHubs.length}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: const Color(0xFF757575),
                                      ),
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
                                onTap: () => _showAssociatedHubs(
                                    context, associatedHubs),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient:
                                            FuturisticColors.accentGradient,
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
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF212121),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      '${associatedHubs.length}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: const Color(0xFF757575),
                                      ),
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

                    // Quick Actions - moved up to replace AI Recommendations
                    Text(
                      'פעולות מהירות',
                      style: GoogleFonts.orbitron(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: const Color(0xFF212121),
                      ),
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
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF212121),
                                  ),
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
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF212121),
                                  ),
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
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF212121),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Upcoming Games
                    StreamBuilder<List<Hub>>(
                      stream: hubsRepo.watchHubsByMember(currentUserId),
                      builder: (context, hubsSnapshot) {
                        if (hubsSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }

                        final hubs = hubsSnapshot.data ?? [];
                        if (hubs.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final hubIds = hubs.map((h) => h.hubId).toList();
                        final now = DateTime.now();
                        final nextWeek = now.add(const Duration(days: 7));

                        return FutureBuilder<List<Game>>(
                          future: _getUpcomingGames(
                              gamesRepo, hubIds, now, nextWeek),
                          builder: (context, snapshot) {
                            final games = snapshot.data ?? [];
                            if (games.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: FuturisticCard(
                                        onTap: () => context
                                            .push('/games/${game.gameId}'),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              color: FuturisticColors.primary,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    DateFormat('dd/MM HH:mm')
                                                        .format(game.gameDate),
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: const Color(
                                                          0xFF212121),
                                                    ),
                                                  ),
                                                  if (game.location != null)
                                                    Text(
                                                      game.location!,
                                                      style: GoogleFonts.inter(
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color:
                                                    FuturisticColors.secondary,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Builder(
                                                builder: (context) {
                                                  final signupsRepo = ref.read(
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
                                                      final confirmedCount =
                                                          signups
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
                                                              FontWeight.w600,
                                                          color: Colors.white,
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
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Developer Tools
                    if (user != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _generateDummyData(context),
                              icon: const Icon(Icons.science_outlined),
                              label: const Text('Generate Dummy Data (Dev)'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(
                                    color: FuturisticColors.textSecondary
                                        .withValues(alpha: 0.3)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _forceHaifaLocation(context, currentUserId),
                              icon: const Icon(Icons.location_city_outlined),
                              label: const Text('Force Haifa Location (Dev)'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(
                                    color: FuturisticColors.textSecondary
                                        .withValues(alpha: 0.3)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateDummyData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('יצירת נתוני דמה'),
        content: const Text(
          'פעולה זו תיצור:\n'
          '• 20 שחקנים\n'
          '• 3 Hubs\n'
          '• 15 משחקי עבר\n\n'
          'האם להמשיך?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FuturisticColors.primary,
            ),
            child: const Text('צור נתוני דמה'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final generator = DummyDataGenerator();
      await generator.generateComprehensiveData();

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✅ נתוני דמה נוצרו בהצלחה! (20 שחקנים, 3 Hubs, 15 משחקים)'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ שגיאה ביצירת נתוני דמה: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Force Haifa location for emulator testing
  Future<void> _forceHaifaLocation(BuildContext context, String userId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Haifa coordinates
      const double haifaLat = 32.7940;
      const double haifaLng = 34.9896;

      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(userId);

      final locationService = ref.read(locationServiceProvider);
      final geohash = locationService.generateGeohash(haifaLat, haifaLng);

      await userRef.update({
        'location': GeoPoint(haifaLat, haifaLng),
        'geohash': geohash,
        'city': 'חיפה',
        'region': 'צפון',
        'manualLocationCity': 'חיפה',
        'hasManualLocation': true,
      });

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('manual_location_city', 'חיפה');
      await prefs.setBool('location_permission_skipped', true);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ מיקום עודכן לחיפה (Dev Mode)'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ שגיאה בעדכון מיקום: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    User? user,
    Stream<int> unreadCountStream,
    String currentUserId,
  ) {
    return AppBar(
      title: Text(
        'DASHBOARD',
        style: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
          color: FuturisticColors.textPrimary,
        ),
      ),
      backgroundColor: FuturisticColors.surface,
      foregroundColor: FuturisticColors.textPrimary,
      elevation: 0,
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: FuturisticColors.surfaceVariant,
        ),
      ),
      actions: [
        // Inbox icon
        IconButton(
          icon: const Icon(Icons.inbox_outlined),
          onPressed: () => context.push('/messages'),
          tooltip: 'הודעות',
          color: FuturisticColors.textSecondary,
        ),
        // Location toggle
        _LocationToggleButton(),
        // Discover icon
        IconButton(
          icon: const Icon(Icons.explore_outlined),
          onPressed: () => context.push('/discover'),
          tooltip: 'גלה הובים',
          color: FuturisticColors.textSecondary,
        ),
        // Leaderboard icon
        IconButton(
          icon: const Icon(Icons.emoji_events_outlined),
          onPressed: () => context.push('/leaderboard'),
          tooltip: 'שולחן מובילים',
          color: FuturisticColors.textSecondary,
        ),
        // Notifications icon with badge
        StreamBuilder<int>(
          stream: unreadCountStream,
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push('/notifications'),
                  tooltip: 'התראות',
                  color: FuturisticColors.textSecondary,
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: FuturisticColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        // Profile button (top-left in RTL) - Circular Avatar - ALWAYS SHOWN
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: InkWell(
            onTap: () {
              debugPrint('Navigating to edit profile for $currentUserId');
              context.push('/profile/$currentUserId/edit');
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: FuturisticColors.primary, // solid color for visibility
                  width: 2,
                ),
              ),
              child: user != null
                  ? PlayerAvatar(
                      user: user,
                      size: AvatarSize.sm,
                      clickable: false,
                    )
                  : const Icon(Icons.person,
                      color: FuturisticColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }

  /// Get upcoming games from user's hubs
  Future<List<Game>> _getUpcomingGames(
    GamesRepository gamesRepo,
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

  Future<List<Hub>> _getAssociatedHubs(
      HubsRepository hubsRepo, String userId) async {
    try {
      final position =
          await ref.read(locationServiceProvider).getCurrentLocation();
      if (position == null) return [];

      final nearbyHubs = await hubsRepo.findHubsNearby(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 50.0,
      );

      return nearbyHubs
          .where((hub) =>
              hub.memberIds.contains(userId) && hub.createdBy != userId)
          .toList();
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
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                color: const Color(0xFF212121),
              ),
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
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                color: const Color(0xFF212121),
              ),
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

        return FuturisticCard(
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

/// Weather & Vibe Widget for Home Screen
class HomeWeatherVibeWidget extends ConsumerWidget {
  const HomeWeatherVibeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(homeDashboardDataProvider);

    return dashboardData.when(
      data: (data) {
        final vibeMessage =
            data['vibeMessage'] as String? ?? 'יום טוב לכדורגל!';
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
                'location': GeoPoint(position.latitude, position.longitude),
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
      iconColor = FuturisticColors.primary;
      tooltip = 'GPS פעיל - לחץ לניהול';
    } else if (_isManualMode) {
      icon = Icons.edit_location;
      iconColor = FuturisticColors.secondary;
      tooltip = 'מיקום ידני - לחץ לניהול';
    } else {
      icon = Icons.location_off;
      iconColor = FuturisticColors.textSecondary;
      tooltip = 'מיקום מושבת - לחץ להפעיל';
    }

    return IconButton(
      icon: Icon(icon, color: iconColor),
      onPressed: _toggleLocation,
      tooltip: tooltip,
    );
  }
}

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
    return InkWell(
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
    );
  }
}
