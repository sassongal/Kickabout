import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/widgets/common/premium_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/models/hub_member.dart' as models;
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';

/// View model combining HubMember with User for display
class HubMemberWithUser {
  final models.HubMember member;
  final User user;

  HubMemberWithUser({required this.member, required this.user});

  String get userId => member.userId;
  DateTime? get joinedAt => member.joinedAt;
  String get role => member.role.name;
  double? get managerRating => member.managerRating;
  models.HubMemberStatus get status => member.status;
  bool get isVeteran => member.isVeteran;
}

/// Dedicated screen for viewing and rating all players in a hub
class HubPlayersListScreenV2 extends ConsumerStatefulWidget {
  final String hubId;

  const HubPlayersListScreenV2({super.key, required this.hubId});

  @override
  ConsumerState<HubPlayersListScreenV2> createState() =>
      _HubPlayersListScreenV2State();
}

class _HubPlayersListScreenV2State
    extends ConsumerState<HubPlayersListScreenV2> {
  // Search and filter state
  String _searchQuery = '';
  String _sortBy = 'rating'; // rating, name
  final TextEditingController _searchController = TextEditingController();

  // Rating mode state
  bool _isRatingMode = false;
  final Map<String, double> _tempRatings = {}; // userId -> rating (1.0-7.0)
  bool _isSavingRatings = false;

  // Pagination state
  final ScrollController _scrollController = ScrollController();
  final List<HubMemberWithUser> _members = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  static const int _pageSize = 30;

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

    setState(() => _isLoading = true);

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

      // Fetch user data for these members
      final memberIds = snapshot.docs.map((doc) => doc.id).toList();
      final users = await ref.read(usersRepositoryProvider).getUsers(memberIds);

      // Create map for quick lookup
      final userMap = {for (var u in users) u.uid: u};
      final memberDataMap = <String, Map<String, dynamic>>{};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String? ?? 'active';

        // Only include active members
        if (status == 'active') {
          memberDataMap[doc.id] = {
            'joinedAt': data['joinedAt'] as Timestamp?,
            'role': data['role'] as String? ?? 'member',
            'managerRating': data['managerRating'] as double?,
          };
        }
      }

      final newMembers = <HubMemberWithUser>[];
      for (final userId in memberIds) {
        // Skip if not active (filtered out above)
        if (!memberDataMap.containsKey(userId)) continue;

        final user = userMap[userId];
        if (user != null) {
          final meta = memberDataMap[userId];
          final roleString = meta?['role'] as String? ?? 'member';
          newMembers.add(HubMemberWithUser(
            user: user,
            member: models.HubMember(
              hubId: widget.hubId,
              userId: user.uid,
              joinedAt: meta?['joinedAt']?.toDate() ?? DateTime.now(),
              role: models.HubMemberRole.fromString(roleString),
              status: models.HubMemberStatus.active,
              managerRating: (meta?['managerRating'] as double?) ?? 0.0,
            ),
          ));
        }
      }

      if (mounted) {
        setState(() {
          _members.addAll(newMembers);
          _hasMore = snapshot.docs.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading members: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
      }
    }
  }

  List<HubMemberWithUser> _filterAndSort(
      List<HubMemberWithUser> members, Hub? hub) {
    var filtered = List<HubMemberWithUser>.from(members);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((member) {
        final user = member.user;
        return user.name.toLowerCase().contains(query) ||
            (user.email.toLowerCase().contains(query)) ||
            (user.city?.toLowerCase().contains(query) ?? false) ||
            (user.preferredPosition.toLowerCase().contains(query));
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      // Managers always first
      final isAManager = a.role == 'manager' || a.role == 'admin';
      final isBManager = b.role == 'manager' || b.role == 'admin';

      if (isAManager && !isBManager) return -1;
      if (!isAManager && isBManager) return 1;

      // Then by selected criterion
      switch (_sortBy) {
        case 'rating':
          final aRating = a.managerRating ?? 4.0;
          final bRating = b.managerRating ?? 4.0;
          return bRating.compareTo(aRating);
        case 'name':
          return a.user.name.compareTo(b.user.name);
        default:
          return 0;
      }
    });

    return filtered;
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

    setState(() => _isSavingRatings = true);

    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      int successCount = 0;
      int errorCount = 0;

      for (final entry in _tempRatings.entries) {
        try {
          await hubsRepo.setPlayerRating(widget.hubId, entry.key, entry.value);
          successCount++;
        } catch (e) {
          debugPrint('Error setting rating for ${entry.key}: $e');
          errorCount++;
        }
      }

      if (mounted) {
        if (errorCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ כל הדירוגים נשמרו ($successCount שחקנים)!'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh list
          setState(() {
            _isRatingMode = false;
            _tempRatings.clear();
            _members.clear();
            _lastDocument = null;
            _hasMore = true;
          });
          _loadMembers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ נשמרו $successCount, $errorCount נכשלו'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingRatings = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final hubsRepo = ref.watch(hubsRepositoryProvider);

    return PremiumScaffold(
      title: 'שחקני ההוב',
      showBackButton: true,
      body: StreamBuilder<Hub?>(
        stream: hubsRepo.watchHub(widget.hubId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: KineticLoadingAnimation(size: 40));
          }

          final hub = snapshot.data;
          if (hub == null) {
            return const Center(child: Text('Hub לא נמצא'));
          }

          final isHubManager = currentUserId == hub.createdBy;
          final hubPermissionsAsync = currentUserId != null
              ? ref.watch(hubPermissionsProvider(
                  (hubId: widget.hubId, userId: currentUserId)))
              : null;
          final hubPermissions = hubPermissionsAsync?.valueOrNull;
          final canManageRatings = (hubPermissions?.isManager ?? false) ||
              (hubPermissions?.isModerator ?? false);

          // Load ratings when entering rating mode
          if (_isRatingMode && _tempRatings.isEmpty && _members.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  for (final member in _members) {
                    if (member.managerRating != null &&
                        member.managerRating! > 0) {
                      // Round existing ratings to nearest 0.5
                      _tempRatings[member.user.uid] =
                          _roundToNearestHalf(member.managerRating!);
                    }
                  }
                });
              }
            });
          }

          final filteredMembers = _filterAndSort(_members, hub);

          return Column(
            children: [
              // Search and Controls
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search
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
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                    const SizedBox(height: 12),

                    // Sort buttons
                    Row(
                      children: [
                        Text('מיין לפי:',
                            style: PremiumTypography.labelMedium),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'rating',
                                label: Text('דירוג'),
                                icon: Icon(Icons.star),
                              ),
                              ButtonSegment(
                                value: 'name',
                                label: Text('שם'),
                                icon: Icon(Icons.sort_by_alpha),
                              ),
                            ],
                            selected: {_sortBy},
                            onSelectionChanged: (Set<String> newSelection) =>
                                setState(() => _sortBy = newSelection.first),
                          ),
                        ),
                      ],
                    ),

                    // Rating mode toggle (managers only)
                    if (canManageRatings) ...[
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('מצב דירוג שחקנים'),
                        subtitle: const Text('דרג שחקנים 1-7 לאיזון קבוצות'),
                        value: _isRatingMode,
                        onChanged: (value) {
                          setState(() {
                            _isRatingMode = value;
                            if (!value) _tempRatings.clear();
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),

                      // Save button in rating mode
                      if (_isRatingMode) ...[
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _isSavingRatings ? null : _saveRatings,
                          icon: _isSavingRatings
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: KineticLoadingAnimation(size: 16),
                                )
                              : const Icon(Icons.save),
                          label: const Text('שמור דירוגים'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PremiumColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              // Players list
              Expanded(
                child: filteredMembers.isEmpty && !_isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 64,
                                color: PremiumColors.textSecondary),
                            const SizedBox(height: 16),
                            Text('לא נמצאו שחקנים',
                                style: PremiumTypography.heading3),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredMembers.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == filteredMembers.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                  child: KineticLoadingAnimation(size: 40)),
                            );
                          }

                          final member = filteredMembers[index];
                          final user = member.user;
                          final currentRating = _tempRatings[user.uid] ??
                              member.managerRating ??
                              4.0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PremiumCard(
                              onTap: _isRatingMode
                                  ? null
                                  : () => context.push('/profile/${user.uid}'),
                              child: _isRatingMode
                                  ? _buildRatingTile(user, currentRating)
                                  : _buildNormalTile(
                                      member, isHubManager, canManageRatings),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNormalTile(
      HubMemberWithUser member, bool isHubManager, bool canManageRatings) {
    final user = member.user;
    final managerRating = canManageRatings ? member.managerRating : null;
    final displayRating = managerRating ?? user.currentRankScore;
    final isManagerRole = member.role == 'manager' || member.role == 'admin';

    return ListTile(
      contentPadding: const EdgeInsets.all(12),
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: PremiumColors.primary.withValues(alpha: 0.1),
        backgroundImage: user.photoUrl != null
            ? CachedNetworkImageProvider(user.photoUrl!)
            : null,
        child: user.photoUrl == null
            ? Icon(Icons.person, size: 30, color: PremiumColors.primary)
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(user.name, style: PremiumTypography.labelLarge),
          ),
          if (isManagerRole)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: PremiumColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('מנהל',
                  style: PremiumTypography.labelSmall
                      .copyWith(color: Colors.white)),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          if (user.preferredPosition.isNotEmpty)
            Row(
              children: [
                Icon(Icons.sports_soccer,
                    size: 14, color: PremiumColors.textSecondary),
                const SizedBox(width: 4),
                Text(user.preferredPosition,
                    style: PremiumTypography.bodySmall),
              ],
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.star,
                  size: 16,
                  color: managerRating != null
                      ? Colors.orange
                      : PremiumColors.warning),
              const SizedBox(width: 4),
              Text(
                displayRating.toStringAsFixed(1),
                style: PremiumTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: managerRating != null
                      ? Colors.orange
                      : PremiumColors.warning,
                ),
              ),
              if (canManageRatings && managerRating != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.verified, size: 14, color: Colors.orange),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingTile(User user, double currentRating) {
    // Round to nearest 0.5 to ensure it's a valid dropdown value
    final roundedRating = _roundToNearestHalf(currentRating);

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
                    PremiumColors.primary.withValues(alpha: 0.1),
                backgroundImage: user.photoUrl != null
                    ? CachedNetworkImageProvider(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? Icon(Icons.person,
                        size: 24, color: PremiumColors.primary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: PremiumTypography.labelLarge),
                    if (user.preferredPosition.isNotEmpty)
                      Text(user.preferredPosition,
                          style: PremiumTypography.bodySmall),
                  ],
                ),
              ),
              Text(
                roundedRating.toStringAsFixed(1),
                style: PremiumTypography.heading3
                    .copyWith(color: PremiumColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: roundedRating,
                  min: 1.0,
                  max: 7.0,
                  divisions: 12,
                  label: roundedRating.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() => _tempRatings[user.uid] = value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: DropdownButton<double>(
                  value: roundedRating,
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
                      setState(() => _tempRatings[user.uid] = value);
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

  /// Round rating to nearest 0.5 increment (1.0, 1.5, 2.0, ... 7.0)
  double _roundToNearestHalf(double value) {
    // Clamp to valid range
    final clamped = value.clamp(1.0, 7.0);
    // Round to nearest 0.5
    return (clamped * 2).round() / 2.0;
  }
}
