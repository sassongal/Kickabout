import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Still needed for unused chart functions (can be removed later)
import 'package:kickadoor/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_card.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/widgets/player_avatar.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/data/repositories.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';

/// Enhanced Player Profile Screen with Futuristic Design
/// Features: Hero Section, Tabbed Interface, Full Statistics, Privacy Settings
class PlayerProfileScreenFuturistic extends ConsumerStatefulWidget {
  final String playerId;

  const PlayerProfileScreenFuturistic({
    super.key,
    required this.playerId,
  });

  @override
  ConsumerState<PlayerProfileScreenFuturistic> createState() =>
      _PlayerProfileScreenFuturisticState();
}

class _PlayerProfileScreenFuturisticState
    extends ConsumerState<PlayerProfileScreenFuturistic>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Simplified: Only 2 tabs - Overview and Games (removed Statistics and Ratings tabs)
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final isAnonymous = ref.watch(isAnonymousUserProvider);
    final usersRepo = ref.read(usersRepositoryProvider);
    // Removed: ratingsRepo - no longer needed (ratings tab removed)
    final gamesRepo = ref.read(gamesRepositoryProvider);
    final followRepo = ref.read(followRepositoryProvider);
    final gamificationRepo = ref.read(gamificationRepositoryProvider);

    final userStream = usersRepo.watchUser(widget.playerId);
    // Removed: ratingHistoryStream - no longer needed (charts and ratings tab removed)
    final gamificationStream =
        gamificationRepo.watchGamification(widget.playerId);
    final isFollowingStream =
        currentUserId != null && currentUserId != widget.playerId
            ? followRepo.watchIsFollowing(currentUserId, widget.playerId)
            : Stream.value(false);
    final followingCountStream =
        followRepo.watchFollowingCount(widget.playerId);
    final followersCountStream =
        followRepo.watchFollowersCount(widget.playerId);
    final isOwnProfile = currentUserId == widget.playerId;

    return FuturisticScaffold(
      title: 'פרופיל שחקן',
      actions: isOwnProfile && !isAnonymous
          ? [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () =>
                    context.push('/profile/${widget.playerId}/edit'),
                tooltip: 'ערוך פרופיל',
              ),
              IconButton(
                icon: const Icon(Icons.privacy_tip),
                onPressed: () =>
                    context.push('/profile/${widget.playerId}/privacy'),
                tooltip: 'הגדרות פרטיות',
              ),
            ]
          : null,
      body: StreamBuilder<User?>(
        stream: userStream,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const FuturisticLoadingState(message: 'טוען פרופיל...');
          }

          if (userSnapshot.hasError) {
            return FuturisticEmptyState(
              icon: Icons.error_outline,
              title: 'שגיאה בטעינת פרופיל',
              message: userSnapshot.error.toString(),
              action: ElevatedButton.icon(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh),
                label: const Text('נסה שוב'),
              ),
            );
          }

          final user = userSnapshot.data;
          if (user == null) {
            return FuturisticEmptyState(
              icon: Icons.person_off,
              title: 'שחקן לא נמצא',
              message: 'השחקן המבוקש לא נמצא במערכת',
            );
          }

          return Column(
            children: [
              // Anonymous User Banner (if viewing own profile as anonymous)
              if (isOwnProfile && isAnonymous)
                _buildAnonymousBanner(context),
              
              // Hero Section
              _buildHeroSection(
                context,
                user,
                isOwnProfile,
                currentUserId,
                followRepo,
                usersRepo,
                isFollowingStream,
                followingCountStream,
                followersCountStream,
                isAnonymous,
              ),

              // Tab Bar (Simplified: Only Overview and Games)
              Container(
                color: FuturisticColors.surface,
                child: TabBar(
                  controller: _tabController,
                  labelColor: FuturisticColors.primary,
                  unselectedLabelColor: FuturisticColors.textSecondary,
                  indicatorColor: FuturisticColors.primary,
                  tabs: const [
                    Tab(text: 'סקירה', icon: Icon(Icons.dashboard)),
                    Tab(text: 'משחקים', icon: Icon(Icons.sports_soccer)),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(
                      context,
                      user,
                      gamificationStream,
                    ),
                    _buildGamesTab(
                      context,
                      user,
                      gamesRepo,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnonymousBanner(BuildContext context) {
    return FuturisticCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: FuturisticColors.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'אתה משתמש כאורח',
                  style: FuturisticTypography.techHeadline.copyWith(
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'כאורח, אתה יכול לצפות בתוכן אבל לא לבצע פעולות. כדי להתחיל להשתמש באפליקציה במלואה - צור חשבון או התחבר!',
            style: FuturisticTypography.bodyMedium.copyWith(
              color: FuturisticColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('התחבר'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FuturisticColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/register'),
                  icon: const Icon(Icons.person_add),
                  label: const Text('הירשם'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FuturisticColors.primary,
                    side: BorderSide(color: FuturisticColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    User user,
    bool isOwnProfile,
    String? currentUserId,
    FollowRepository followRepo,
    UsersRepository usersRepo,
    Stream<bool> isFollowingStream,
    Stream<int> followingCountStream,
    Stream<int> followersCountStream,
    bool isAnonymous,
  ) {
    final privacy = user.privacySettings;

    return Container(
      decoration: BoxDecoration(
        gradient: FuturisticColors.primaryGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Photo & Basic Info
              Row(
                children: [
                  // Profile Photo
                  Hero(
                    tag: 'profile_${user.uid}',
                    child: PlayerAvatar(
                      user: user,
                      radius: 50,
                      clickable: false,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name & Position
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: FuturisticTypography.heading2.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.preferredPosition,
                            style: FuturisticTypography.labelMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Rating Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getRatingColor(user.currentRankScore)
                                .withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user.currentRankScore.toStringAsFixed(1),
                                style: FuturisticTypography.labelLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Message Button (if not own profile)
              if (!isOwnProfile)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: isAnonymous
                        ? OutlinedButton.icon(
                            onPressed: () => context.push('/login'),
                            icon: const Icon(Icons.login),
                            label: const Text('התחבר כדי לשלוח הודעה'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () async {
                              if (currentUserId == null || isAnonymous) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('נא להתחבר כדי לשלוח הודעה'),
                                    ),
                                  );
                                }
                                return;
                              }
                              
                              try {
                                final privateMessagesRepo = ref.read(
                                  privateMessagesRepositoryProvider,
                                );
                                final conversationId = await privateMessagesRepo
                                    .getOrCreateConversation(
                                  currentUserId,
                                  widget.playerId,
                                );
                                
                                if (context.mounted) {
                                  context.go('/messages/$conversationId');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('שגיאה בפתיחת שיחה: $e'),
                                      backgroundColor: FuturisticColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.message),
                            label: const Text('שלח הודעה'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: FuturisticColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                  ),
                ),

              // Follow/Unfollow Button & Stats
              Row(
                children: [
                  // Follow Button (if not own profile and not anonymous)
                  if (!isOwnProfile && !isAnonymous)
                    Expanded(
                      child: StreamBuilder<bool>(
                        stream: isFollowingStream,
                        builder: (context, snapshot) {
                          final isFollowing = snapshot.data ?? false;
                          return ElevatedButton.icon(
                            onPressed: () async {
                              if (currentUserId == null || isAnonymous) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('נא להתחבר כדי לעקוב אחרי שחקנים'),
                                    ),
                                  );
                                }
                                return;
                              }
                              try {
                                if (isFollowing) {
                                  await followRepo.unfollow(
                                    currentUserId,
                                    widget.playerId,
                                  );
                                } else {
                                  await followRepo.follow(
                                    currentUserId,
                                    widget.playerId,
                                  );

                                  // Send notification
                                  try {
                                    final pushIntegration = ref.read(
                                      pushNotificationIntegrationServiceProvider,
                                    );
                                    final currentUser =
                                        await usersRepo.getUser(currentUserId);

                                    await pushIntegration.notifyNewFollow(
                                      followerName:
                                          currentUser?.name ?? 'מישהו',
                                      followingId: widget.playerId,
                                    );
                                  } catch (e) {
                                    debugPrint(
                                        'Failed to send follow notification: $e');
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('שגיאה: $e'),
                                      backgroundColor: FuturisticColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: Icon(
                              isFollowing
                                  ? Icons.person_remove
                                  : Icons.person_add,
                            ),
                            label: Text(isFollowing ? 'ביטול עקיבה' : 'עקוב'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing
                                  ? FuturisticColors.error
                                  : Colors.white,
                              foregroundColor: isFollowing
                                  ? Colors.white
                                  : FuturisticColors.primary,
                            ),
                          );
                        },
                      ),
                    ),
                  
                  // Anonymous user message for follow button
                  if (!isOwnProfile && isAnonymous)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/login'),
                        icon: const Icon(Icons.login),
                        label: const Text('התחבר כדי לעקוב'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                      ),
                    ),

                  if (!isOwnProfile) const SizedBox(width: 12),

                  // Followers Count
                  StreamBuilder<int>(
                    stream: followersCountStream,
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return InkWell(
                        onTap: () => context.push(
                          '/profile/${widget.playerId}/followers',
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$count',
                                style: FuturisticTypography.heading3.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'עוקבים',
                                style: FuturisticTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 12),

                  // Following Count
                  StreamBuilder<int>(
                    stream: followingCountStream,
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return InkWell(
                        onTap: () => context.push(
                          '/profile/${widget.playerId}/following',
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$count',
                                style: FuturisticTypography.heading3.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'עוקב',
                                style: FuturisticTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Additional Info (respecting privacy)
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (user.city != null &&
                      user.city!.isNotEmpty &&
                      !(privacy['hideCity'] ?? false))
                    _buildInfoChip(
                      Icons.location_city,
                      user.city!,
                      Colors.white,
                    ),
                  if (user.phoneNumber != null &&
                      user.phoneNumber!.isNotEmpty &&
                      !(privacy['hidePhone'] ?? false))
                    _buildInfoChip(
                      Icons.phone,
                      user.phoneNumber!,
                      Colors.white,
                    ),
                  if (!(privacy['hideEmail'] ?? false))
                    _buildInfoChip(
                      Icons.email,
                      user.email,
                      Colors.white,
                    ),
                  _buildInfoChip(
                    Icons.event,
                    '${user.totalParticipations} משחקים',
                    Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: FuturisticTypography.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    User user,
    Stream<Gamification?> gamificationStream,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Big Counters: Games Played, Goals, MVP
          StreamBuilder<Gamification?>(
            stream: gamificationStream,
            builder: (context, snapshot) {
              final gamification = snapshot.data;
              if (gamification != null) {
                final stats = gamification.stats;
                final gamesPlayed = stats['gamesPlayed'] ?? 0;
                final goals = stats['goals'] ?? 0;
                final mvpCount = stats['mvp'] ?? 0; // MVP count from stats (if available)
                
                return Column(
                  children: [
                    // Big Counters Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildBigCounter(
                            context,
                            'משחקים',
                            gamesPlayed.toString(),
                            Icons.sports_soccer,
                            FuturisticColors.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildBigCounter(
                            context,
                            'שערים',
                            goals.toString(),
                            Icons.sports_soccer,
                            FuturisticColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildBigCounter(
                            context,
                            'MVP',
                            mvpCount.toString(),
                            Icons.star,
                            Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Badges Strip
                    _buildBadgesStrip(context, gamification),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBigCounter(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return FuturisticCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: FuturisticTypography.heading1.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: FuturisticTypography.labelLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesStrip(
    BuildContext context,
    Gamification gamification,
  ) {
    if (gamification.badges.isEmpty) {
      return FuturisticCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'אין תגים עדיין',
            style: FuturisticTypography.bodyMedium.copyWith(
              color: FuturisticColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return FuturisticCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'תגים',
              style: FuturisticTypography.techHeadline,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: gamification.badges.map((badgeName) {
                return Chip(
                  label: Text(
                    _getBadgeDisplayName(badgeName),
                    style: FuturisticTypography.labelSmall,
                  ),
                  avatar: Icon(
                    _getBadgeIcon(badgeName),
                    size: 18,
                    color: FuturisticColors.primary,
                  ),
                  backgroundColor: FuturisticColors.primary.withValues(alpha: 0.1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getBadgeDisplayName(String badgeName) {
    switch (badgeName) {
      case 'firstGame':
        return 'משחק ראשון';
      case 'tenGames':
        return '10 משחקים';
      case 'fiftyGames':
        return '50 משחקים';
      case 'hundredGames':
        return '100 משחקים';
      case 'firstGoal':
        return 'שער ראשון';
      case 'hatTrick':
        return 'שלושער';
      case 'mvp':
        return 'MVP';
      default:
        return badgeName;
    }
  }

  IconData _getBadgeIcon(String badgeName) {
    switch (badgeName) {
      case 'firstGame':
      case 'tenGames':
      case 'fiftyGames':
      case 'hundredGames':
        return Icons.sports_soccer;
      case 'firstGoal':
      case 'hatTrick':
        return Icons.sports_soccer;
      case 'mvp':
        return Icons.star;
      default:
        return Icons.emoji_events;
    }
  }

  Widget _buildStatisticsTab(
    BuildContext context,
    User user,
    Stream<Gamification?> gamificationStream,
    List<RatingSnapshot> history,
  ) {
    final privacy = user.privacySettings;
    if (privacy['hideStats'] ?? false) {
      return Center(
        child: FuturisticEmptyState(
          icon: Icons.privacy_tip,
          title: 'סטטיסטיקות מוסתרות',
          message: 'השחקן בחר להסתיר את הסטטיסטיקות שלו',
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<Gamification?>(
        stream: gamificationStream,
        builder: (context, snapshot) {
          final gamification = snapshot.data;
          if (gamification == null) {
            return const FuturisticLoadingState(message: 'טוען סטטיסטיקות...');
          }

          final stats = gamification.stats;
          final gamesPlayed = stats['gamesPlayed'] ?? 0;
          final wins = stats['gamesWon'] ?? 0;
          final goals = stats['goals'] ?? 0;
          final assists = stats['assists'] ?? 0;
          final saves = stats['saves'] ?? 0;
          final winRate = gamesPlayed > 0 ? (wins / gamesPlayed * 100) : 0.0;
          final goalsPerGame = gamesPlayed > 0 ? (goals / gamesPlayed) : 0.0;
          final assistsPerGame =
              gamesPlayed > 0 ? (assists / gamesPlayed) : 0.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Detailed Stats Grid
              FuturisticCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'סטטיסטיקות מפורטות',
                      style: FuturisticTypography.techHeadline,
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          'משחקים',
                          '$gamesPlayed',
                          Icons.sports_soccer,
                          FuturisticColors.primary,
                        ),
                        _buildStatCard(
                          'ניצחונות',
                          '$wins',
                          Icons.emoji_events,
                          FuturisticColors.success,
                        ),
                        _buildStatCard(
                          'שערים',
                          '$goals',
                          Icons.sports_soccer,
                          FuturisticColors.accent,
                        ),
                        _buildStatCard(
                          'אסיסטים',
                          '$assists',
                          Icons.assistant,
                          FuturisticColors.warning,
                        ),
                        if (saves > 0)
                          _buildStatCard(
                            'הצלות',
                            '$saves',
                            Icons.save,
                            FuturisticColors.info,
                          ),
                        _buildStatCard(
                          'אחוז ניצחונות',
                          '${winRate.toStringAsFixed(1)}%',
                          Icons.trending_up,
                          FuturisticColors.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Averages Card
              FuturisticCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ממוצעים',
                      style: FuturisticTypography.techHeadline,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAverageCard(
                          'שערים למשחק',
                          goalsPerGame.toStringAsFixed(2),
                          Icons.sports_soccer,
                        ),
                        _buildAverageCard(
                          'אסיסטים למשחק',
                          assistsPerGame.toStringAsFixed(2),
                          Icons.assistant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRatingsTab(
    BuildContext context,
    User user,
    List<RatingSnapshot> history,
    RatingsRepository ratingsRepo,
  ) {
    final privacy = user.privacySettings;
    if (privacy['hideRatings'] ?? false) {
      return Center(
        child: FuturisticEmptyState(
          icon: Icons.privacy_tip,
          title: 'דירוגים מוסתרים',
          message: 'השחקן בחר להסתיר את הדירוגים שלו',
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (history.isNotEmpty) ...[
            // Rating History Chart
            FuturisticCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'היסטוריית דירוגים',
                    style: FuturisticTypography.techHeadline,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildRatingChart(history),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Skills Radar Chart
            FuturisticCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'השוואת יכולות',
                    style: FuturisticTypography.techHeadline,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: _buildSkillsRadarChart(history.last),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Trend Indicators
            _buildTrendIndicators(history),
          ] else
            FuturisticEmptyState(
              icon: Icons.trending_up,
              title: 'אין דירוגים',
              message: 'עדיין לא התקבלו דירוגים עבור שחקן זה',
            ),
        ],
      ),
    );
  }

  Widget _buildGamesTab(
    BuildContext context,
    User user,
    GamesRepository gamesRepo,
  ) {
    final privacy = user.privacySettings;
    if (privacy['hideStats'] ?? false) {
      return Center(
        child: FuturisticEmptyState(
          icon: Icons.privacy_tip,
          title: 'משחקים מוסתרים',
          message: 'השחקן בחר להסתיר את המשחקים שלו',
        ),
      );
    }

    // Simplified: Show message for now
    // TODO: In future, can fetch games from games collection filtered by player
    return Center(
      child: FuturisticEmptyState(
        icon: Icons.sports_soccer,
        title: 'רשימת משחקים',
        message: 'רשימת המשחקים תוצג כאן בקרוב',
      ),
    );
  }

  Widget _buildGamificationCard(
    BuildContext context,
    Gamification gamification,
  ) {
    // Simplified: No points/levels, just show stats
    // Progress is based on games played (for milestone badges)
    final gamesPlayed = gamification.stats['gamesPlayed'] ?? 0;
    final nextMilestone = gamesPlayed < 10 ? 10 : gamesPlayed < 50 ? 50 : gamesPlayed < 100 ? 100 : 100;
    final progress = nextMilestone > 0 ? gamesPlayed / nextMilestone : 0.0;

    return FuturisticCard(
      showGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: FuturisticColors.warning,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'גיימיפיקציה',
                style: FuturisticTypography.techHeadline,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${gamification.points}',
                      style: FuturisticTypography.heading2.copyWith(
                        color: FuturisticColors.warning,
                      ),
                    ),
                    Text(
                      'נקודות',
                      style: FuturisticTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: FuturisticColors.surfaceVariant,
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: FuturisticColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Level ${gamification.level}',
                        style: FuturisticTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'רמה',
                      style: FuturisticTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress to next level
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'לעבר רמה ${gamification.level + 1}',
                    style: FuturisticTypography.bodySmall,
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: FuturisticTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: FuturisticColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: FuturisticColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  FuturisticColors.primary,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Text(
                gamesPlayed < 10 
                    ? '${10 - gamesPlayed} משחקים עד ה-milestone הבא'
                    : gamesPlayed < 50
                        ? '${50 - gamesPlayed} משחקים עד ה-milestone הבא'
                        : gamesPlayed < 100
                            ? '${100 - gamesPlayed} משחקים עד ה-milestone הבא'
                            : 'השגת את כל ה-milestones!',
                style: FuturisticTypography.bodySmall,
              ),
            ],
          ),
          if (gamification.badges.isNotEmpty) ...[
            const SizedBox(height: 20),
            Divider(color: FuturisticColors.surfaceVariant),
            const SizedBox(height: 12),
            Text(
              'תגים',
              style: FuturisticTypography.labelLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: gamification.badges.map((badge) {
                return Chip(
                  avatar: Icon(
                    Icons.star,
                    size: 18,
                    color: FuturisticColors.warning,
                  ),
                  label: Text(badge),
                  backgroundColor:
                      FuturisticColors.warning.withValues(alpha: 0.1),
                  side: BorderSide(
                      color: FuturisticColors.warning.withValues(alpha: 0.3)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentRatingCard(BuildContext context, User user) {
    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'דירוג נוכחי',
            style: FuturisticTypography.techHeadline,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.currentRankScore.toStringAsFixed(1),
                style: FuturisticTypography.heading1.copyWith(
                  color: _getRatingColor(user.currentRankScore),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ 10',
                style: FuturisticTypography.heading3.copyWith(
                  color: FuturisticColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: user.currentRankScore / 10,
            backgroundColor: FuturisticColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getRatingColor(user.currentRankScore),
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return FuturisticCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: FuturisticTypography.heading3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: FuturisticTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAverageCard(
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: FuturisticColors.primary, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: FuturisticTypography.heading3.copyWith(
            color: FuturisticColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: FuturisticTypography.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRatingChart(List<RatingSnapshot> history) {
    final recentHistory = history.take(10).toList().reversed.toList();
    if (recentHistory.isEmpty) {
      return Center(
        child: Text(
          'אין נתונים להצגה',
          style: FuturisticTypography.bodyMedium,
        ),
      );
    }

    final ratings = recentHistory.map((snapshot) {
      return (snapshot.defense +
              snapshot.passing +
              snapshot.shooting +
              snapshot.dribbling +
              snapshot.physical +
              snapshot.leadership +
              snapshot.teamPlay +
              snapshot.consistency) /
          8.0;
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: FuturisticTypography.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= recentHistory.length) {
                  return const Text('');
                }
                final index = value.toInt();
                final date = recentHistory[index].submittedAt;
                return Text(
                  DateFormat('dd/MM').format(date),
                  style: FuturisticTypography.bodySmall,
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: ratings.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value);
            }).toList(),
            isCurved: true,
            color: FuturisticColors.primary,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        minY: 0,
        maxY: 10,
      ),
    );
  }

  Widget _buildSkillsRadarChart(RatingSnapshot snapshot) {
    final skills = [
      ('הגנה', snapshot.defense),
      ('מסירות', snapshot.passing),
      ('בעיטות', snapshot.shooting),
      ('כדרור', snapshot.dribbling),
      ('פיזי', snapshot.physical),
      ('מנהיגות', snapshot.leadership),
      ('משחק קבוצתי', snapshot.teamPlay),
      ('עקביות', snapshot.consistency),
    ];

    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            fillColor: FuturisticColors.primary.withValues(alpha: 0.2),
            borderColor: FuturisticColors.primary,
            borderWidth: 2,
            dataEntries: skills.map((s) => RadarEntry(value: s.$2)).toList(),
          ),
        ],
        tickCount: 5,
        ticksTextStyle: FuturisticTypography.bodySmall,
        tickBorderData: BorderSide(color: FuturisticColors.surfaceVariant),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: FuturisticColors.surfaceVariant,
            width: 2,
          ),
        ),
        radarBackgroundColor: FuturisticColors.background,
        radarBorderData: BorderSide(
          color: FuturisticColors.surfaceVariant,
          width: 1,
        ),
        titleTextStyle: FuturisticTypography.labelMedium.copyWith(
          fontWeight: FontWeight.bold,
        ),
        getTitle: (index, angle) {
          return RadarChartTitle(
            text: skills[index].$1,
            angle: angle,
          );
        },
      ),
    );
  }

  Widget _buildTrendIndicators(List<RatingSnapshot> history) {
    if (history.length < 2) {
      return const SizedBox.shrink();
    }

    final recent = history.take(5).toList();
    final older = history.skip(5).take(5).toList();

    if (older.isEmpty) {
      return const SizedBox.shrink();
    }

    final recentAvg = recent
            .map((s) =>
                (s.defense +
                    s.passing +
                    s.shooting +
                    s.dribbling +
                    s.physical +
                    s.leadership +
                    s.teamPlay +
                    s.consistency) /
                8.0)
            .reduce((a, b) => a + b) /
        recent.length;

    final olderAvg = older
            .map((s) =>
                (s.defense +
                    s.passing +
                    s.shooting +
                    s.dribbling +
                    s.physical +
                    s.leadership +
                    s.teamPlay +
                    s.consistency) /
                8.0)
            .reduce((a, b) => a + b) /
        older.length;

    final trend = recentAvg - olderAvg;

    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ניתוח מגמות',
            style: FuturisticTypography.techHeadline,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTrendCard(
                'מגמה',
                trend > 0.1
                    ? 'משתפר'
                    : trend < -0.1
                        ? 'יורד'
                        : 'יציב',
                trend > 0.1
                    ? FuturisticColors.success
                    : trend < -0.1
                        ? FuturisticColors.error
                        : FuturisticColors.textSecondary,
                Icons.trending_up,
              ),
              _buildTrendCard(
                'שינוי',
                '${trend > 0 ? "+" : ""}${trend.toStringAsFixed(1)}',
                trend > 0
                    ? FuturisticColors.success
                    : trend < 0
                        ? FuturisticColors.error
                        : FuturisticColors.textSecondary,
                Icons.arrow_upward,
              ),
              _buildTrendCard(
                'ממוצע אחרון',
                recentAvg.toStringAsFixed(1),
                _getRatingColor(recentAvg),
                Icons.star,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: FuturisticTypography.heading3.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: FuturisticTypography.bodySmall,
        ),
      ],
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8) return FuturisticColors.success;
    if (rating >= 6) return FuturisticColors.primary;
    if (rating >= 4) return FuturisticColors.warning;
    return FuturisticColors.error;
  }
}
