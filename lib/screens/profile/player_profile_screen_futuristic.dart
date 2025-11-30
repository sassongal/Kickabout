import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kattrick/widgets/futuristic/futuristic_card.dart';
import 'package:kattrick/widgets/futuristic/loading_state.dart';
import 'package:kattrick/widgets/futuristic/empty_state.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/data/repositories.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/theme/futuristic_theme.dart';
// ignore_for_file: unused_element

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
    // Simplified: 3 tabs - Overview, Games, Hubs
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _displayName(User user) {
    final hasFirst = user.firstName != null && user.firstName!.isNotEmpty;
    final hasLast = user.lastName != null && user.lastName!.isNotEmpty;
    if (hasFirst || hasLast) {
      return '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    }
    if (user.name.isNotEmpty) return user.name;
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return 'שחקן';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final isAnonymous = ref.watch(isAnonymousUserProvider);
    final usersRepo = ref.read(usersRepositoryProvider);
    // Removed: ratingsRepo - no longer needed (ratings tab removed)
    final gamesRepo = ref.read(gamesRepositoryProvider);
    final hubsRepo = ref.read(hubsRepositoryProvider);
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
      actions: [
        if (isOwnProfile && !isAnonymous)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () =>
                context.push('/profile/${widget.playerId}/settings'),
            tooltip: 'הגדרות',
          ),
        if (!isOwnProfile && !isAnonymous && currentUserId != null)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'block') {
                await _handleBlockUser(context, currentUserId!, widget.playerId);
              } else if (value == 'unblock') {
                await _handleUnblockUser(
                    context, currentUserId!, widget.playerId);
              }
            },
            itemBuilder: (context) {
              return FutureBuilder<bool>(
                future: usersRepo.isUserBlocked(currentUserId!, widget.playerId),
                builder: (context, snapshot) {
                  final isBlocked = snapshot.data ?? false;
                  return [
                    if (isBlocked)
                      const PopupMenuItem(
                        value: 'unblock',
                        child: Row(
                          children: [
                            Icon(Icons.block, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('בטל חסימה'),
                          ],
                        ),
                      )
                    else
                      const PopupMenuItem(
                        value: 'block',
                        child: Row(
                          children: [
                            Icon(Icons.block, color: Colors.red),
                            SizedBox(width: 8),
                            Text('חסום משתמש'),
                          ],
                        ),
                      ),
                  ];
                },
              );
            },
          ),
      ],
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
              if (isOwnProfile && isAnonymous) _buildAnonymousBanner(context),

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
                    Tab(text: 'האבים', icon: Icon(Icons.group_work)),
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
                    _buildHubsTab(
                      context,
                      user,
                      hubsRepo,
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
                          _displayName(user),
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
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
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
                                      content:
                                          Text('נא להתחבר כדי לשלוח הודעה'),
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
                                      content: Text(
                                          'נא להתחבר כדי לעקוב אחרי שחקנים'),
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
          // Big Counters: Games Played, Goals, Assists, MVP
          StreamBuilder<Gamification?>(
            stream: gamificationStream,
            builder: (context, snapshot) {
              final gamification = snapshot.data;
              if (gamification != null) {
                final stats = gamification.stats;
                final gamesPlayed = stats['gamesPlayed'] ?? 0;
                final goals = stats['goals'] ?? 0;
                final assists = stats['assists'] ?? 0;
                final mvpCount =
                    stats['mvp'] ?? 0; // MVP count from stats (if available)

                return Column(
                  children: [
                    // Big Counters Row
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildBigCounter(
                          context,
                          'משחקים',
                          gamesPlayed.toString(),
                          Icons.sports_soccer,
                          FuturisticColors.primary,
                        ),
                        _buildBigCounter(
                          context,
                          'שערים',
                          goals.toString(),
                          Icons.sports_soccer,
                          FuturisticColors.secondary,
                        ),
                        _buildBigCounter(
                          context,
                          'בישולים',
                          assists.toString(),
                          Icons.assistant,
                          Colors.purple,
                        ),
                        _buildBigCounter(
                          context,
                          'MVP',
                          mvpCount.toString(),
                          Icons.star,
                          Colors.amber,
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

          const SizedBox(height: 24),

          // Player meta info card (no rating)
          FuturisticCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'פרטי שחקן',
                  style: FuturisticTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.location_on_outlined,
                      user.city != null && user.city!.isNotEmpty
                          ? user.city!
                          : 'עיר לא עודכנה',
                      FuturisticColors.textSecondary,
                    ),
                    _buildInfoChip(
                      Icons.map_outlined,
                      user.region != null && user.region!.isNotEmpty
                          ? user.region!
                          : 'אזור לא עודכן',
                      FuturisticColors.textSecondary,
                    ),
                    _buildInfoChip(
                      Icons.sports,
                      user.preferredPosition,
                      FuturisticColors.textSecondary,
                    ),
                    _buildInfoChip(
                      Icons.wifi_tethering,
                      user.availabilityStatus == 'available'
                          ? 'זמין למשחקים'
                          : 'לא זמין למשחקים',
                      FuturisticColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Placeholder for future insights (removed rating charts)
          FuturisticCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ביצועים אחרונים',
                  style: FuturisticTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'מידע אנליטי מפורט יתווסף בהמשך. בינתיים תוכל לראות סיכום כללי ומידע בסיסי.',
                  style: FuturisticTypography.bodySmall.copyWith(
                    color: FuturisticColors.textSecondary,
                  ),
                ),
              ],
            ),
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
    final gamesStream = gamesRepo.watchGamesByCreator(user.uid);

    return StreamBuilder<List<Game>>(
      stream: gamesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const FuturisticLoadingState(message: 'טוען משחקים...');
        }

        if (snapshot.hasError) {
          return FuturisticEmptyState(
            icon: Icons.error_outline,
            title: 'שגיאה בטעינת משחקים',
            message: snapshot.error.toString(),
            action: ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('נסה שוב'),
            ),
          );
        }

        final games = snapshot.data ?? [];
        if (games.isEmpty) {
          return FuturisticEmptyState(
            icon: Icons.sports_soccer,
            title: 'אין משחקים',
            message: 'עדיין לא יצרת או שיחקת משחקים',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            final statusText = game.status.toString().split('.').last;
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
                    child: const Icon(Icons.sports_soccer, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy').format(game.gameDate),
                          style: FuturisticTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          game.venueName ?? game.location ?? 'מיקום לא ידוע',
                          style: FuturisticTypography.bodySmall.copyWith(
                            color: FuturisticColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        statusText,
                        style: FuturisticTypography.bodySmall.copyWith(
                          color: FuturisticColors.textSecondary,
                        ),
                      ),
                      Text(
                        game.hubName ?? 'משחק פרטי',
                        style: FuturisticTypography.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
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
                  backgroundColor:
                      FuturisticColors.primary.withValues(alpha: 0.1),
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


  // Rating components removed

  Widget _buildHubsTab(
    BuildContext context,
    User user,
    HubsRepository hubsRepo,
  ) {
    return StreamBuilder<List<Hub>>(
      stream: hubsRepo.watchHubsByMember(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const FuturisticLoadingState(message: 'טוען האבים...');
        }

        if (snapshot.hasError) {
          return FuturisticEmptyState(
            icon: Icons.error_outline,
            title: 'שגיאה בטעינת האבים',
            message: snapshot.error.toString(),
          );
        }

        final hubs = snapshot.data ?? [];

        if (hubs.isEmpty) {
          return FuturisticEmptyState(
            icon: Icons.group_off,
            title: 'אין האבים',
            message: 'השחקן לא חבר באף האב',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: hubs.length,
          itemBuilder: (context, index) {
            final hub = hubs[index];
            return FuturisticCard(
              margin: const EdgeInsets.only(bottom: 12),
              onTap: () => context.push(
                '/profile/${user.uid}/hub-stats/${hub.hubId}',
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Hero(
                      tag: 'hub_avatar_${hub.hubId}',
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            FuturisticColors.primary.withOpacity(0.2),
                        child: Icon(
                          Icons.group,
                          color: FuturisticColors.primary,
                        ),
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
                          if (hub.description != null &&
                              hub.description!.isNotEmpty)
                            Text(
                              hub.description!,
                              style: FuturisticTypography.bodySmall.copyWith(
                                color: FuturisticColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_left,
                      color: FuturisticColors.textSecondary,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleBlockUser(
      BuildContext context, String currentUserId, String userIdToBlock) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('חסימת משתמש'),
        content: const Text(
          'האם אתה בטוח שברצונך לחסום משתמש זה? המשתמש לא יוכל לראות את הפרופיל שלך ולשלוח לך הודעות.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('חסום', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      await usersRepo.blockUser(currentUserId, userIdToBlock);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('המשתמש נחסם בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the screen
        setState(() {});
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בחסימת משתמש: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleUnblockUser(
      BuildContext context, String currentUserId, String userIdToUnblock) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ביטול חסימה'),
        content: const Text('האם אתה בטוח שברצונך לבטל את החסימה?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('אישור'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      await usersRepo.unblockUser(currentUserId, userIdToUnblock);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('החסימה בוטלה בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the screen
        setState(() {});
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בביטול חסימה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
