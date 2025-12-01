import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/widgets/futuristic/futuristic_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/widgets/futuristic/loading_state.dart';
import 'package:kattrick/widgets/futuristic/skeleton_loader.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/screens/hub/add_manual_player_dialog.dart';
import 'package:kattrick/screens/hub/edit_manual_player_dialog.dart';
import 'package:kattrick/widgets/dialogs/merge_player_dialog.dart';
import 'package:kattrick/widgets/dialogs/set_player_rating_dialog.dart';
import 'package:kattrick/theme/futuristic_theme.dart';
import 'package:kattrick/widgets/futuristic/futuristic_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kattrick/services/error_handler_service.dart';
import 'package:kattrick/models/hub_role.dart';

class HubMember {
  final User user;
  final DateTime? joinedAt;
  final String role;

  HubMember({
    required this.user,
    this.joinedAt,
    required this.role,
  });
}

/// Dedicated screen for viewing all players in a hub
class HubPlayersListScreen extends ConsumerStatefulWidget {
  final String hubId;

  const HubPlayersListScreen({super.key, required this.hubId});

  @override
  ConsumerState<HubPlayersListScreen> createState() =>
      _HubPlayersListScreenState();
}

class _HubPlayersListScreenState extends ConsumerState<HubPlayersListScreen> {
  String _searchQuery = '';
  String _sortBy = 'rating'; // rating, name, position, tenure
  final TextEditingController _searchController = TextEditingController();

  // Manager Ratings Mode
  bool _isRatingMode = false;
  Map<String, double> _tempRatings = {}; // userId -> rating (1.0-7.0)
  bool _isSavingRatings = false;

  // Pagination state for subcollection
  final ScrollController _scrollController = ScrollController();
  final List<HubMember> _members = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMembers();
    }
  }

  Future<void> _loadMembers() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('hubs')
          .doc(widget.hubId)
          .collection('members')
          .orderBy('joinedAt', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      _lastDocument = snapshot.docs.last;

      final memberIds = snapshot.docs.map((doc) => doc.id).toList();
      final metadata = <String, Map<String, dynamic>>{};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        metadata[doc.id] = {
          'joinedAt': data['joinedAt'] as Timestamp?,
          'role': data['role'] as String? ?? 'member',
        };
      }

      final users =
          await ref.read(usersRepositoryProvider).getUsers(memberIds);

      final newMembers = users.map((u) {
        final meta = metadata[u.uid];
        return HubMember(
          user: u,
          joinedAt: meta?['joinedAt']?.toDate(),
          role: meta?['role'] as String? ?? 'member',
        );
      }).toList();

      if (mounted) {
        setState(() {
          _members.addAll(newMembers);
          _hasMore = snapshot.docs.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
      }
      debugPrint('Error loading members: $e');
    }
  }

  List<HubMember> _filterAndSort(List<HubMember> members, Hub? hub, bool isHubManager) {
    var filtered = List<HubMember>.from(members);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((member) {
        final query = _searchQuery.toLowerCase();
        final user = member.user;
        return user.name.toLowerCase().contains(query) ||
            (user.email.toLowerCase().contains(query)) ||
            (user.city?.toLowerCase().contains(query) ?? false) ||
            (user.preferredPosition.toLowerCase().contains(query));
      }).toList();
    }

    // Sort with priority: Managers first, then by Tenure (Join Date)
    filtered.sort((a, b) {
      // Priority 1: Managers/Admins must appear at the very top
      final isAManager = a.role == 'manager' || a.role == 'admin';
      final isBManager = b.role == 'manager' || b.role == 'admin';

      if (isAManager && !isBManager) return -1;
      if (!isAManager && isBManager) return 1;

      // Priority 2: Sort by selected criterion
      switch (_sortBy) {
        case 'rating':
          // Only managers can see and use manager ratings for sorting
          // Non-managers always use global rating
          final aRating = isHubManager && hub != null
              ? (hub.managerRatings[a.user.uid] ?? a.user.currentRankScore)
              : a.user.currentRankScore;
          final bRating = isHubManager && hub != null
              ? (hub.managerRatings[b.user.uid] ?? b.user.currentRankScore)
              : b.user.currentRankScore;
          return bRating.compareTo(aRating);
        case 'name':
          return a.user.name.compareTo(b.user.name);
        case 'position':
          return a.user.preferredPosition.compareTo(b.user.preferredPosition);
        default: // tenure (oldest join date first)
          if (a.joinedAt != null && b.joinedAt != null) {
            return a.joinedAt!.compareTo(b.joinedAt!);
          }
          return 0;
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final hubsRepo = ref.watch(hubsRepositoryProvider);
    final usersRepo = ref.watch(usersRepositoryProvider);

    return FuturisticScaffold(
      title: 'שחקני ההוב',
      showBackButton: true,
      body: StreamBuilder<Hub?>(
        stream: hubsRepo.watchHub(widget.hubId),
        builder: (context, hubSnapshot) {
          if (hubSnapshot.connectionState == ConnectionState.waiting) {
            return const FuturisticLoadingState(message: 'טוען שחקנים...');
          }

          if (!hubSnapshot.hasData || hubSnapshot.data == null) {
            return Center(
              child: Text(
                'Hub לא נמצא',
                style: FuturisticTypography.bodyLarge,
              ),
            );
          }

          final hub = hubSnapshot.data!;
          final isHubManager = currentUserId == hub.createdBy;
          final hubPermissions = currentUserId != null
              ? HubPermissions(hub: hub, userId: currentUserId)
              : null;
          final canManageRatings = (hubPermissions?.isManager() ?? false) ||
              (hubPermissions?.isModerator() ?? false);

          // Load existing ratings when entering rating mode
          if (_isRatingMode &&
              _tempRatings.isEmpty &&
              hub.managerRatings.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _tempRatings = Map<String, double>.from(hub.managerRatings);
                });
              }
            });
          }

          if (hub.memberCount == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: FuturisticColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'אין שחקנים בהוב',
                    style: FuturisticTypography.heading3,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'הוסף שחקנים כדי להתחיל',
                    style: FuturisticTypography.bodyMedium,
                  ),
                  if (isHubManager) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) =>
                              AddManualPlayerDialog(hubId: widget.hubId),
                        );
                        if (result == true && mounted) {
                          // Refresh will happen automatically
                        }
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('הוסף שחקן'),
                    ),
                  ],
                ],
              ),
            );
          }

          return FutureBuilder<List<User>>(
            future: () async {
              final memberIds = await hubsRepo.getHubMemberIds(hub.hubId);
              return usersRepo.getUsers(memberIds);
            }(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  itemBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: SkeletonPlayerCard(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: FuturisticColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'שגיאה בטעינת שחקנים',
                        style: FuturisticTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ErrorHandlerService().handleException(
                          snapshot.error,
                          context: 'Hub players list screen',
                        ),
                        style: FuturisticTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final filteredMembers = _filterAndSort(_members, hub, isHubManager);
              final membersToShow = filteredMembers;
              final hasMoreToShow = _hasMore;

              return Column(
                children: [
                  // Search and filter bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Search field
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'חפש שחקן...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        // Sort options
                        Row(
                          children: [
                            Text(
                              'מיין לפי:',
                              style: FuturisticTypography.labelMedium,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'rating',
                                    label: Text('ציון'),
                                    icon: Icon(Icons.star),
                                  ),
                                  ButtonSegment(
                                    value: 'name',
                                    label: Text('שם'),
                                    icon: Icon(Icons.sort_by_alpha),
                                  ),
                                  ButtonSegment(
                                    value: 'position',
                                    label: Text('עמדה'),
                                    icon: Icon(Icons.sports_soccer),
                                  ),
                                ],
                                selected: {_sortBy},
                                onSelectionChanged: (Set<String> newSelection) {
                                  setState(() {
                                    _sortBy = newSelection.first;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        // Manager Ratings Toggle (only for managers)
                        if (canManageRatings) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SwitchListTile(
                                  title: const Text('מצב ניהול דירוגים'),
                                  subtitle: const Text(
                                      'דרג שחקנים (1-7) לשיפור חלוקת קבוצות'),
                                  value: _isRatingMode,
                                  onChanged: (value) {
                                    setState(() {
                                      _isRatingMode = value;
                                      if (value) {
                                        // Load existing ratings
                                        _tempRatings = Map<String, double>.from(
                                            hub.managerRatings);
                                      } else {
                                        // Clear temp ratings when exiting mode
                                        _tempRatings.clear();
                                      }
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          if (_isRatingMode) ...[
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _isSavingRatings ? null : _saveRatings,
                              icon: _isSavingRatings
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.save),
                              label: const Text('שמור דירוגים'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FuturisticColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ],
                        ],
                        // Add player button (for managers)
                        if (isHubManager && !_isRatingMode) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (context) =>
                                    AddManualPlayerDialog(hubId: widget.hubId),
                              );
                              if (result == true && mounted) {
                                // Refresh will happen automatically
                              }
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('הוסף שחקן ידנית'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FuturisticColors.secondary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Merge player button
                          OutlinedButton.icon(
                            onPressed: () async {
                              // Get manual players
                              final manualPlayers = _members
                                  .map((m) => m.user)
                                  .where((u) => u.email.startsWith('manual_'))
                                  .toList();

                              if (manualPlayers.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('אין שחקנים ידניים למיזוג')),
                                );
                                return;
                              }

                              final result = await showDialog<bool>(
                                context: context,
                                builder: (context) => MergePlayerDialog(
                                  hubId: widget.hubId,
                                  manualPlayers: manualPlayers,
                                  usersRepo: usersRepo,
                                ),
                              );

                              if (result == true && mounted) {
                                final messenger = ScaffoldMessenger.of(context);
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('השחקנים מוזגו בהצלחה!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.merge_type),
                            label: const Text('מזג שחקן ידני'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.orange),
                              foregroundColor: Colors.orange,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Players list
                  Expanded(
                    child: membersToShow.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: FuturisticColors.textSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'לא נמצאו שחקנים',
                                  style: FuturisticTypography.heading3,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'נסה לשנות את החיפוש',
                                  style: FuturisticTypography.bodyMedium,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount:
                                membersToShow.length + (hasMoreToShow ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Show loading indicator at the bottom
                              if (index == membersToShow.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              }
                              final member = membersToShow[index];
                              final user = member.user;
                              final isManualPlayer =
                                  user.email.startsWith('manual_');
                              final isCreator = user.uid == hub.createdBy;
                              final currentRating = _tempRatings[user.uid] ??
                                  hub.managerRatings[user.uid] ??
                                  user.currentRankScore.clamp(1.0, 7.0);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: FuturisticCard(
                                  onTap: _isRatingMode
                                      ? null // Disable tap in rating mode
                                      : (isManualPlayer
                                          ? (isHubManager
                                              ? () async {
                                                  final result =
                                                      await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) =>
                                                        EditManualPlayerDialog(
                                                      player: user,
                                                      hubId: widget.hubId,
                                                    ),
                                                  );
                                                  if (result == true &&
                                                      mounted) {
                                                    // Refresh will happen automatically
                                                  }
                                                }
                                              : null)
                                          : () => context
                                              .push('/profile/${user.uid}')),
                                  child: _isRatingMode
                                      ? _buildRatingModeTile(
                                          user, currentRating, hub)
                                      : _buildNormalModeTile(
                                          user,
                                          member.role,
                                          isManualPlayer,
                                          isCreator,
                                          isHubManager,
                                          hub),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNormalModeTile(User user, String role, bool isManualPlayer,
      bool isCreator, bool isHubManager, Hub hub) {
    // Get manager rating if it exists, but only show it to managers
    final managerRating = isHubManager ? hub.managerRatings[user.uid] : null;
    // For non-managers, always show global rating
    // For managers, show manager rating if exists, otherwise global rating
    final displayRating = isHubManager 
        ? (managerRating ?? user.currentRankScore)
        : user.currentRankScore;
    final hasManagerRating = managerRating != null;
    final isManagerRole = role == 'manager' || role == 'admin';

    return ListTile(
      contentPadding: const EdgeInsets.all(12),
      // Allow managers to tap to set rating
      onTap: isHubManager
          ? () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => SetPlayerRatingDialog(
                  hubId: widget.hubId,
                  playerId: user.uid,
                  playerName: user.name,
                  currentRating: managerRating,
                ),
              );
              if (result == true && mounted) {
                // Refresh will happen automatically via stream
              }
            }
          : null,
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: FuturisticColors.primary.withValues(alpha: 0.1),
        backgroundImage: user.photoUrl != null
            ? CachedNetworkImageProvider(user.photoUrl!)
            : null,
        child: user.photoUrl == null
            ? Icon(
                Icons.person,
                size: 30,
                color: FuturisticColors.primary,
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              user.name,
              style: FuturisticTypography.labelLarge,
            ),
          ),
          // Social media icons (if enabled and links exist)
          if (user.showSocialLinks) ...[
            if (user.facebookProfileUrl != null &&
                user.facebookProfileUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.facebook,
                  size: 16,
                  color: const Color(0xFF1877F2),
                ),
              ),
            if (user.instagramProfileUrl != null &&
                user.instagramProfileUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: const Color(0xFFE4405F),
                ),
              ),
          ],
          if (isManagerRole)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: FuturisticColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'מנהל',
                style: FuturisticTypography.labelSmall.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          if (!isManagerRole && isCreator) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: FuturisticColors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'יוצר',
                style: FuturisticTypography.labelSmall.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
          if (isManualPlayer) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.edit_note,
              size: 16,
              color: FuturisticColors.secondary,
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          if (!isManualPlayer)
            Text(
              user.email,
              style: FuturisticTypography.bodySmall,
            ),
          if (isManualPlayer)
            Text(
              'שחקן ידני - ללא אפליקציה',
              style: FuturisticTypography.bodySmall.copyWith(
                color: FuturisticColors.secondary,
              ),
            ),
          if (user.city != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: FuturisticColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  user.city!,
                  style: FuturisticTypography.bodySmall,
                ),
              ],
            ),
          ],
          if (user.preferredPosition.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.sports_soccer,
                  size: 14,
                  color: FuturisticColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  user.preferredPosition,
                  style: FuturisticTypography.bodySmall,
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.star,
                size: 16,
                color:
                    (isHubManager && hasManagerRating) ? Colors.orange : FuturisticColors.warning,
              ),
              const SizedBox(width: 4),
              Text(
                displayRating.toStringAsFixed(1),
                style: FuturisticTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: (isHubManager && hasManagerRating)
                      ? Colors.orange
                      : FuturisticColors.warning,
                ),
              ),
              if (isHubManager && hasManagerRating) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.verified,
                  size: 14,
                  color: Colors.orange,
                ),
              ],
              if (isHubManager && !hasManagerRating) ...[
                const SizedBox(width: 4),
                Text(
                  '(גלובלי)',
                  style: FuturisticTypography.bodySmall.copyWith(
                    color: FuturisticColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: isManualPlayer && isHubManager
          ? IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => EditManualPlayerDialog(
                    player: user,
                    hubId: widget.hubId,
                  ),
                );
                if (result == true && mounted) {
                  // Refresh will happen automatically
                }
              },
              tooltip: 'ערוך שחקן',
            )
          : isHubManager
              ? Icon(
                  Icons.chevron_left,
                  color: FuturisticColors.primary,
                )
              : const Icon(Icons.chevron_left),
    );
  }

  Widget _buildRatingModeTile(User user, double currentRating, Hub hub) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    FuturisticColors.primary.withValues(alpha: 0.1),
                backgroundImage: user.photoUrl != null
                    ? CachedNetworkImageProvider(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? Icon(
                        Icons.person,
                        size: 24,
                        color: FuturisticColors.primary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: FuturisticTypography.labelLarge,
                    ),
                    if (user.preferredPosition.isNotEmpty)
                      Text(
                        user.preferredPosition,
                        style: FuturisticTypography.bodySmall,
                      ),
                  ],
                ),
              ),
              Text(
                currentRating.toStringAsFixed(1),
                style: FuturisticTypography.heading3.copyWith(
                  color: FuturisticColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: currentRating,
                  min: 1.0,
                  max: 7.0,
                  divisions: 12, // 0.5 increments
                  label: currentRating.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      _tempRatings[user.uid] = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: DropdownButton<double>(
                  value: currentRating,
                  isExpanded: true,
                  items: List.generate(13, (i) {
                    final value = 1.0 + (i * 0.5);
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value.toStringAsFixed(1)),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _tempRatings[user.uid] = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveRatings() async {
    if (_tempRatings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('לא בוצעו שינויים בדירוגים'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSavingRatings = true;
    });

    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);

      // Update hub with managerRatings
      await hubsRepo.updateHub(widget.hubId, {
        'managerRatings': _tempRatings,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ הדירוגים נשמרו בהצלחה!'),
            backgroundColor: Colors.green,
          ),
        );

        // Exit rating mode
        setState(() {
          _isRatingMode = false;
          _tempRatings.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשמירת דירוגים: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingRatings = false;
        });
      }
    }
  }
}
