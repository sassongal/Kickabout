import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kattrick/widgets/common/premium_scaffold.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/widgets/premium/loading_state.dart';
import 'package:kattrick/widgets/premium/empty_state.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/data/repositories.dart';
import 'package:kattrick/features/games/data/repositories/game_queries_repository.dart';
import 'package:kattrick/data/proteams_repository.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/gamification/gamification_visuals.dart';
import 'package:kattrick/widgets/optimized_image.dart';
import 'package:kattrick/widgets/street_baller_avatar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kattrick/core/providers/complex_providers.dart';
// ignore_for_file: unused_element

/// Enhanced Player Profile Screen with Premium Design
/// Features: Hero Section, Tabbed Interface, Full Statistics, Privacy Settings
class PlayerProfileScreen extends ConsumerStatefulWidget {
  final String playerId;

  const PlayerProfileScreen({
    super.key,
    required this.playerId,
  });

  @override
  ConsumerState<PlayerProfileScreen> createState() =>
      _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends ConsumerState<PlayerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    // Tabs: כללי, סקירה, משחקים, האבים
    _tabController = TabController(length: 4, vsync: this);
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

  Future<void> _pickAndUploadPhoto(User user) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId != user.uid) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('בחר מגלריה'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('צלם תמונה'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
      if (image == null) return;

      final sizeBytes = await image.length();
      if (sizeBytes > 12 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('הקובץ גדול מדי (מעל 12MB). נסה תמונה קלה יותר.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      setState(() => _isUploadingPhoto = true);

      final storageService = ref.read(storageServiceProvider);
      final photoUrl =
          await storageService.uploadProfilePhoto(user.uid, image);
      await ref.read(usersRepositoryProvider).updateUser(user.uid, {
        'photoUrl': photoUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('התמונה עודכנה בהצלחה'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בהעלאת תמונה: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final isAnonymous = ref.watch(isAnonymousUserProvider);
    final usersRepo = ref.read(usersRepositoryProvider);
    // Removed: ratingsRepo - no longer needed (ratings tab removed)
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

    return PremiumScaffold(
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
          StreamBuilder<User?>(
            stream: usersRepo.watchUser(currentUserId),
            builder: (context, currentUserSnapshot) {
              final currentUser = currentUserSnapshot.data;
              final isBlocked =
                  currentUser?.blockedUserIds.contains(widget.playerId) ??
                      false;

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'block') {
                    await _handleBlockUser(
                        context, currentUserId, widget.playerId);
                  } else if (value == 'unblock') {
                    await _handleUnblockUser(
                        context, currentUserId, widget.playerId);
                  }
                },
                itemBuilder: (context) {
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
            return const PremiumLoadingState(message: 'טוען פרופיל...');
          }

          if (userSnapshot.hasError) {
            return PremiumEmptyState(
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
            return PremiumEmptyState(
              icon: Icons.person_off,
              title: 'שחקן לא נמצא',
              message: 'השחקן המבוקש לא נמצא במערכת',
            );
          }

          return Column(
            children: [
              Container(
                color: PremiumColors.surface,
                child: TabBar(
                  controller: _tabController,
                  labelColor: PremiumColors.primary,
                  unselectedLabelColor: PremiumColors.textSecondary,
                  indicatorColor: PremiumColors.primary,
                  tabs: const [
                    Tab(text: 'כללי', icon: Icon(Icons.person_outline)),
                    Tab(text: 'סקירה', icon: Icon(Icons.dashboard)),
                    Tab(text: 'משחקים', icon: Icon(Icons.sports_soccer)),
                    Tab(text: 'האבים', icon: Icon(Icons.group_work)),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGeneralTab(
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
                    _buildOverviewTab(
                      context,
                      user,
                      gamificationStream,
                    ),
                    _buildGamesTab(
                      context,
                      user,
                      ref.read(gameQueriesRepositoryProvider),
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

  Widget _buildGeneralTab(
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
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          if (isOwnProfile && isAnonymous) _buildAnonymousBanner(context),
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
        ],
      ),
    );
  }

  Widget _buildAnonymousBanner(BuildContext context) {
    return PremiumCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: PremiumColors.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'אתה משתמש כאורח',
                  style: PremiumTypography.techHeadline.copyWith(
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'כאורח, אתה יכול לצפות בתוכן אבל לא לבצע פעולות. כדי להתחיל להשתמש באפליקציה במלואה - צור חשבון או התחבר!',
            style: PremiumTypography.bodyMedium.copyWith(
              color: PremiumColors.textSecondary,
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
                    backgroundColor: PremiumColors.primary,
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
                    foregroundColor: PremiumColors.primary,
                    side: BorderSide(color: PremiumColors.primary),
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
    final avatarSize = 96.0;
    final hasPhoto = user.photoUrl != null && user.photoUrl!.isNotEmpty;

    final favoriteTeamTile = user.favoriteProTeamId == null
        ? _buildProfileInfoTile(
            icon: Icons.emoji_events_outlined,
            label: 'קבוצה אהודה',
            value: const Text('לא נבחרה'),
            onTap: isOwnProfile
                ? () => _openFavoriteTeamPicker(context, user)
                : null,
          )
        : FutureBuilder<ProTeam?>(
            future: ref
                .read(proTeamsRepositoryProvider)
                .getTeam(user.favoriteProTeamId!),
            builder: (context, snapshot) {
              final team = snapshot.data;
              if (team == null) {
                return _buildProfileInfoTile(
                  icon: Icons.emoji_events_outlined,
                  label: 'קבוצה אהודה',
                  value: const Text('לא נבחרה'),
                  onTap: isOwnProfile
                      ? () => _openFavoriteTeamPicker(context, user)
                      : null,
                );
              }
              return _buildProfileInfoTile(
                icon: Icons.emoji_events_outlined,
                label: 'קבוצה אהודה',
                value: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: team.logoUrl,
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        errorWidget: (context, url, error) => const Icon(
                          Icons.sports_soccer,
                          size: 18,
                          color: PremiumColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        team.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                onTap: isOwnProfile
                    ? () => _openFavoriteTeamPicker(context, user)
                    : null,
              );
            },
          );

    final infoTiles = <Widget>[
      if (!(privacy['hideCity'] ?? false))
        _buildProfileInfoTile(
          icon: Icons.location_on_outlined,
          label: 'עיר',
          value: Text(
            user.city != null && user.city!.isNotEmpty
                ? user.city!
                : 'עיר לא עודכנה',
          ),
        ),
      _buildProfileInfoTile(
        icon: Icons.map_outlined,
        label: 'אזור',
        value: Text(
          user.region != null && user.region!.isNotEmpty
              ? user.region!
              : 'אזור לא עודכן',
        ),
      ),
      if (!(privacy['hidePhone'] ?? false))
        _buildProfileInfoTile(
          icon: Icons.phone_outlined,
          label: 'טלפון',
          value: Text(
            user.phoneNumber != null && user.phoneNumber!.isNotEmpty
                ? user.phoneNumber!
                : 'טלפון לא עודכן',
            textDirection: ui.TextDirection.ltr,
          ),
        ),
      if (!(privacy['hideEmail'] ?? false))
        _buildProfileInfoTile(
          icon: Icons.email_outlined,
          label: 'אימייל',
          value: Text(
            user.email,
            textDirection: ui.TextDirection.ltr,
          ),
        ),
      favoriteTeamTile,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: PremiumCard(
        showGlow: true,
        glassmorphism: true,
        glowColor: PremiumColors.accent,
        elevation: PremiumCardElevation.lg,
        padding: const EdgeInsets.all(16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -40,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: PremiumColors.accent.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: -50,
              bottom: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: PremiumColors.secondary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Hero(
                          tag: 'profile_${user.uid}',
                          child: GestureDetector(
                            onTap: isOwnProfile && !isAnonymous && !_isUploadingPhoto
                                ? () => _pickAndUploadPhoto(user)
                                : null,
                            child: SizedBox(
                              width: avatarSize,
                              height: avatarSize,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipOval(
                                      child: hasPhoto
                                          ? OptimizedImage(
                                              imageUrl: user.photoUrl!,
                                              width: avatarSize,
                                              height: avatarSize,
                                              fit: BoxFit.cover,
                                              errorWidget: StreetBallerAvatar(
                                                size: avatarSize,
                                              ),
                                            )
                                          : StreetBallerAvatar(size: avatarSize),
                                    ),
                                  ),
                                  if (_isUploadingPhoto)
                                    Positioned.fill(
                                      child: ClipOval(
                                        child: Container(
                                          color: Colors.black.withValues(alpha: 0.35),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (isOwnProfile && !isAnonymous && !_isUploadingPhoto)
                                    Positioned(
                                      bottom: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: PremiumColors.primary,
                                          shape: BoxShape.circle,
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 6,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_outlined,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'מומלץ להעלות תמונת פורטרט',
                          style: PremiumTypography.bodySmall.copyWith(
                            color: PremiumColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayName(user),
                            style: PremiumTypography.heading2.copyWith(
                              color: PremiumColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildProfilePill(
                                icon: Icons.sports_soccer,
                                label: user.preferredPosition,
                              ),
                              if (user.ageGroup != null)
                                _buildProfilePill(
                                  icon: Icons.cake_outlined,
                                  label: user.ageGroup!.displayNameHe,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildProfileStatTile(
                      label: 'משחקים',
                      value: Text('${user.totalParticipations}'),
                    ),
                    _buildProfileStatDivider(),
                    _buildProfileStatTile(
                      label: 'עוקבים',
                      value: StreamBuilder<int>(
                        stream: followersCountStream,
                        builder: (context, snapshot) =>
                            Text('${snapshot.data ?? 0}'),
                      ),
                      onTap: () => context.push(
                        '/profile/${widget.playerId}/followers',
                      ),
                    ),
                    _buildProfileStatDivider(),
                    _buildProfileStatTile(
                      label: 'עוקב',
                      value: StreamBuilder<int>(
                        stream: followingCountStream,
                        builder: (context, snapshot) =>
                            Text('${snapshot.data ?? 0}'),
                      ),
                      onTap: () => context.push(
                        '/profile/${widget.playerId}/following',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final tileWidth = constraints.maxWidth >= 520
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: infoTiles
                          .map(
                            (tile) => SizedBox(
                              width: tileWidth,
                              child: tile,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                if (!isOwnProfile) ...[
                  const SizedBox(height: 16),
                  if (isAnonymous)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/login'),
                            icon: const Icon(Icons.login),
                            label: const Text('התחבר כדי לשלוח הודעה'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/login'),
                            icon: const Icon(Icons.login),
                            label: const Text('התחבר כדי לעקוב'),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
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
                                      backgroundColor: PremiumColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.message),
                            label: const Text('שלח הודעה'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: PremiumColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StreamBuilder<bool>(
                            stream: isFollowingStream,
                            builder: (context, snapshot) {
                              final isFollowing = snapshot.data ?? false;
                              return ElevatedButton.icon(
                                onPressed: () async {
                                  if (currentUserId == null || isAnonymous) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
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

                                      try {
                                        final pushIntegration = ref.read(
                                          pushNotificationIntegrationServiceProvider,
                                        );
                                        final currentUser =
                                            await usersRepo
                                                .getUser(currentUserId);

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
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('שגיאה: $e'),
                                          backgroundColor: PremiumColors.error,
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
                                label:
                                    Text(isFollowing ? 'ביטול עקיבה' : 'עקוב'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFollowing
                                      ? PremiumColors.error
                                      : Colors.white,
                                  foregroundColor: isFollowing
                                      ? Colors.white
                                      : PremiumColors.primary,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFavoriteTeamPicker(
    BuildContext context,
    User user,
  ) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId != user.uid) return;

    try {
      final teams = await ref.read(allProTeamsProvider.future);
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_outlined,
                          color: PremiumColors.accent),
                      const SizedBox(width: 8),
                      Text(
                        'בחר קבוצה אהודה',
                        style: PremiumTypography.heading3,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: teams.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected =
                            (user.favoriteProTeamId ?? '').isEmpty;
                        return ListTile(
                          leading: const Icon(Icons.block,
                              color: PremiumColors.textSecondary),
                          title: const Text('אין קבוצה אהודה'),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: PremiumColors.primary)
                              : null,
                          onTap: () async {
                            await ref
                                .read(usersRepositoryProvider)
                                .updateUser(user.uid, {
                              'favoriteProTeamId': null,
                            });
                            if (context.mounted) Navigator.pop(context);
                          },
                        );
                      }

                      final team = teams[index - 1];
                      final isSelected = team.teamId == user.favoriteProTeamId;
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
                            imageUrl: team.logoUrl,
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.sports_soccer),
                          ),
                        ),
                        title: Text(team.name),
                        subtitle: Text(
                          team.league == 'premier' ? 'ליגת העל' : 'ליגה לאומית',
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: PremiumColors.primary)
                            : null,
                        onTap: () async {
                          await ref
                              .read(usersRepositoryProvider)
                              .updateUser(user.uid, {
                            'favoriteProTeamId': team.teamId,
                          });
                          if (context.mounted) Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בבחירת קבוצה: $e')),
        );
      }
    }
  }

  Widget _buildProfilePill({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: PremiumColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: PremiumColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: PremiumColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: PremiumTypography.labelMedium.copyWith(
              color: PremiumColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStatTile({
    required String label,
    required Widget value,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              DefaultTextStyle(
                style: PremiumTypography.heading3.copyWith(
                  color: PremiumColors.textPrimary,
                ),
                child: value,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: PremiumTypography.labelSmall.copyWith(
                  color: PremiumColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStatDivider() {
    return Container(
      width: 1,
      height: 32,
      color: PremiumColors.borderStrong,
    );
  }

  Widget _buildProfileInfoTile({
    required IconData icon,
    required String label,
    required Widget value,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PremiumColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: PremiumColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: PremiumTypography.bodySmall.copyWith(
                        color: PremiumColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    DefaultTextStyle(
                      style: PremiumTypography.bodyMedium.copyWith(
                        color: PremiumColors.textPrimary,
                      ),
                      child: value,
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down, color: PremiumColors.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLinkButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    String url,
  ) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('לא ניתן לפתוח את הקישור: $url'),
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: PremiumTypography.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new,
              size: 16,
              color: color.withValues(alpha: 0.7),
            ),
          ],
        ),
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

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final counterWidth =
                        constraints.maxWidth >= 420
                            ? (constraints.maxWidth - 10) / 2
                            : constraints.maxWidth;
                    return Column(
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                              width: counterWidth,
                              child: _buildBigCounter(
                                context,
                                'משחקים',
                                gamesPlayed.toString(),
                                Icons.sports_soccer,
                                PremiumColors.primary,
                              ),
                            ),
                            SizedBox(
                              width: counterWidth,
                              child: _buildBigCounter(
                                context,
                                'שערים',
                                goals.toString(),
                                Icons.sports_soccer,
                                PremiumColors.secondary,
                              ),
                            ),
                            SizedBox(
                              width: counterWidth,
                              child: _buildBigCounter(
                                context,
                                'בישולים',
                                assists.toString(),
                                Icons.assistant,
                                Colors.purple,
                              ),
                            ),
                            SizedBox(
                              width: counterWidth,
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
                        const SizedBox(height: 12),

                        // Badges Strip
                        _buildBadgesStrip(context, gamification),
                      ],
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),

          const SizedBox(height: 12),

          // Social Media Links Section (if enabled and links exist)
          if (user.showSocialLinks &&
              ((user.facebookProfileUrl != null &&
                      user.facebookProfileUrl!.isNotEmpty) ||
                  (user.instagramProfileUrl != null &&
                      user.instagramProfileUrl!.isNotEmpty)))
            PremiumCard(
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'רשתות חברתיות',
                    style: PremiumTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (user.facebookProfileUrl != null &&
                          user.facebookProfileUrl!.isNotEmpty)
                        _buildSocialLinkButton(
                          context,
                          'פייסבוק',
                          Icons.facebook,
                          const Color(0xFF1877F2),
                          user.facebookProfileUrl!,
                        ),
                      if (user.instagramProfileUrl != null &&
                          user.instagramProfileUrl!.isNotEmpty)
                        _buildSocialLinkButton(
                          context,
                          'אינסטגרם',
                          Icons.camera_alt,
                          const Color(0xFFE4405F),
                          user.instagramProfileUrl!,
                        ),
                    ],
                  ),
                ],
              ),
            ),

          // Placeholder for future insights (removed rating charts)
          PremiumCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ביצועים אחרונים',
                  style: PremiumTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'מידע אנליטי מפורט יתווסף בהמשך. בינתיים תוכל לראות סיכום כללי ומידע בסיסי.',
                  style: PremiumTypography.bodySmall.copyWith(
                    color: PremiumColors.textSecondary,
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
    GameQueriesRepository gameQueriesRepo,
  ) {
    final gamesStream = gameQueriesRepo.watchGamesByCreator(user.uid);

    return StreamBuilder<List<Game>>(
      stream: gamesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PremiumLoadingState(message: 'טוען משחקים...');
        }

        if (snapshot.hasError) {
          return PremiumEmptyState(
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
          return PremiumEmptyState(
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
            return PremiumCard(
              margin: const EdgeInsets.only(bottom: 12),
              onTap: () => context.push('/games/${game.gameId}'),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: PremiumColors.primaryGradient,
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
                          style: PremiumTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          game.denormalized.venueName ??
                              game.location ??
                              'מיקום לא ידוע',
                          style: PremiumTypography.bodySmall.copyWith(
                            color: PremiumColors.textSecondary,
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
                        style: PremiumTypography.bodySmall.copyWith(
                          color: PremiumColors.textSecondary,
                        ),
                      ),
                      Text(
                        game.denormalized.hubName ?? 'משחק פרטי',
                        style: PremiumTypography.labelSmall,
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
    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: PremiumTypography.heading1.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: PremiumTypography.labelMedium.copyWith(
                color: PremiumColors.textSecondary,
              ),
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
      return PremiumCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'אין תגים עדיין',
            style: PremiumTypography.bodyMedium.copyWith(
              color: PremiumColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'תגים',
              style: PremiumTypography.techHeadline,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: gamification.badges.map((badgeName) {
                return AchievementBadge(
                  badgeId: badgeName,
                  label: _getBadgeDisplayName(badgeName),
                  size: 64,
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
    return PremiumCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: PremiumTypography.heading3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: PremiumTypography.bodySmall,
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
        Icon(icon, color: PremiumColors.primary, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: PremiumTypography.heading3.copyWith(
            color: PremiumColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: PremiumTypography.bodySmall,
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
    final hubsAsync = ref.watch(hubsByMemberStreamProvider(user.uid));

    return hubsAsync.when(
      data: (hubs) {
        if (hubs.isEmpty) {
          return PremiumEmptyState(
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
            return PremiumCard(
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
                            PremiumColors.primary.withValues(alpha: 0.2),
                        child: Icon(
                          Icons.group,
                          color: PremiumColors.primary,
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
                            style: PremiumTypography.heading3,
                          ),
                          if (hub.description != null &&
                              hub.description!.isNotEmpty)
                            Text(
                              hub.description!,
                              style: PremiumTypography.bodySmall.copyWith(
                                color: PremiumColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_left,
                      color: PremiumColors.textSecondary,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const PremiumLoadingState(message: 'טוען האבים...'),
      error: (err, stack) => PremiumEmptyState(
        icon: Icons.error_outline,
        title: 'שגיאה בטעינת האבים',
        message: err.toString(),
      ),
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

  Future<void> _handleUnblockUser(BuildContext context, String currentUserId,
      String userIdToUnblock) async {
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
