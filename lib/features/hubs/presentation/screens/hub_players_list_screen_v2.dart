import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/widgets/common/premium_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/core/providers/repositories_providers.dart';
import 'package:kattrick/core/providers/complex_providers.dart';
import 'package:kattrick/core/providers/auth_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/features/hubs/domain/models/hub_member.dart' as models;
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kattrick/features/hubs/presentation/screens/add_manual_player_dialog.dart';
import 'package:kattrick/features/hubs/presentation/widgets/contact_picker_dialog.dart';

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
      // DATA ACCESS: Use repository to get paginated members
      final result = await ref.read(hubsRepositoryProvider).getHubMembersPaginated(
            hubId: widget.hubId,
            limit: _pageSize,
            startAfter: _lastDocument,
          );

      if (result.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      _lastDocument = result.lastDoc;

      // Fetch user data for these members
      final memberIds = result.items.map((m) => m.userId).toList();
      final users = await ref.read(usersRepositoryProvider).getUsers(memberIds);

      // Create map for quick lookup
      final userMap = {for (var u in users) u.uid: u};

      final newMembers = <HubMemberWithUser>[];
      for (final member in result.items) {
        final user = userMap[member.userId];
        if (user != null) {
          newMembers.add(HubMemberWithUser(
            user: user,
            member: member,
          ));
        }
      }

      if (mounted) {
        setState(() {
          _members.addAll(newMembers);
          _hasMore = result.hasMore;
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
          // Persist rounded to nearest 0.5 for consistency
          final rounded = _roundToNearestHalf(entry.value);
          await hubsRepo.setPlayerRating(widget.hubId, entry.key, rounded);
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
    final hubAsync = ref.watch(hubStreamProvider(widget.hubId));

    return hubAsync.when(
      data: (hub) {
        if (hub == null) {
          return PremiumScaffold(
            title: 'שחקני ההוב',
            showBackButton: true,
            body: const Center(child: Text('Hub לא נמצא')),
          );
        }
        return _buildContent(context, hub);
      },
      loading: () => PremiumScaffold(
        title: 'שחקני ההוב',
        showBackButton: true,
        body: const Center(child: KineticLoadingAnimation(size: 40)),
      ),
      error: (err, stack) => PremiumScaffold(
        title: 'שחקני ההוב',
        showBackButton: true,
        body: const Center(child: Text('שגיאה בטעינת הנתונים')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Hub hub) {
    final currentUserId = ref.watch(currentUserIdProvider);

    final hubPermissionsAsync = currentUserId != null
        ? ref.watch(hubPermissionsProvider(
            (hubId: widget.hubId, userId: currentUserId)))
        : null;
    final hubPermissions = hubPermissionsAsync?.valueOrNull;
    final isManagerRole =
        (hubPermissions?.isManager ?? false) || currentUserId == hub.createdBy;
    final isModeratorRole = hubPermissions?.isModerator ?? false;
    final canEditRatings = isManagerRole;
    final canViewRatings = isManagerRole || isModeratorRole;
    final canInvitePlayers =
        hubPermissions?.canInvitePlayers ?? isManagerRole;

    if (!canEditRatings && _isRatingMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isRatingMode = false;
            _tempRatings.clear();
          });
        }
      });
    }

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

    if (!canViewRatings && _sortBy == 'rating') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _sortBy = 'name');
      });
    }

    return PremiumScaffold(
      title: 'שחקני ההוב',
      showBackButton: true,
      floatingActionButton: _buildSpeedDial(context, hub, canInvitePlayers),
      body: Column(
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
                            segments: [
                              if (canViewRatings)
                                const ButtonSegment(
                                  value: 'rating',
                                  label: Text('דירוג'),
                                  icon: Icon(Icons.star),
                                ),
                              const ButtonSegment(
                                value: 'name',
                                label: Text('שם'),
                                icon: Icon(Icons.sort_by_alpha),
                              ),
                            ],
                            selected: {_sortBy == 'rating' && canViewRatings ? 'rating' : 'name'},
                            onSelectionChanged: (Set<String> newSelection) =>
                                setState(() => _sortBy = newSelection.first),
                          ),
                        ),
                      ],
                    ),

                    // Rating mode toggle (managers only)
                    if (canEditRatings) ...[
                      const SizedBox(height: 12),
                      _buildRatingModeButton(),

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
                                  : () => _showPlayerActionsBottomSheet(
                                      context, member, canEditRatings),
                              child: _isRatingMode
                                  ? _buildRatingTile(user, currentRating)
                                  : _buildNormalTile(
                                      member, canViewRatings, canEditRatings),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
    );
  }

  Widget _buildRatingModeButton() {
    return GestureDetector(
      onTap: _isSavingRatings
          ? null
          : () {
              setState(() {
                _isRatingMode = !_isRatingMode;
                if (!_isRatingMode) _tempRatings.clear();
              });
            },
      child: PremiumCard(
        showGlow: _isRatingMode,
        glassmorphism: true,
        glowColor: _isRatingMode ? PremiumColors.accent : null,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 52,
              height: 32,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _isRatingMode
                    ? PremiumColors.primary
                    : PremiumColors.borderStrong,
                borderRadius: BorderRadius.circular(20),
                boxShadow: _isRatingMode
                    ? [
                        BoxShadow(
                          color: PremiumColors.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                alignment:
                    _isRatingMode ? Alignment.centerRight : Alignment.centerLeft,
                child: const Icon(
                  Icons.bolt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'מצב דירוג שחקנים',
                    style: PremiumTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'דרג שחקנים 1-7 לאיזון כוחות',
                    style: PremiumTypography.bodySmall.copyWith(
                      color: PremiumColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isRatingMode
                  ? const Icon(Icons.check_circle, color: PremiumColors.primary)
                  : const Icon(Icons.touch_app_outlined,
                      color: PremiumColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedDial(BuildContext context, Hub hub, bool isManager) {
    return SpeedDial(
      icon: Icons.group_add,
      activeIcon: Icons.close,
      backgroundColor: PremiumColors.primary,
      foregroundColor: Colors.white,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      spacing: 12,
      spaceBetweenChildren: 12,
      children: [
        // 1. Add Manual Player (managers only)
        if (isManager)
          SpeedDialChild(
            child: const Icon(Icons.person_add, color: Colors.white),
            backgroundColor: PremiumColors.secondary,
            label: 'הוסף שחקן ידנית',
            labelStyle: const TextStyle(fontSize: 14),
            onTap: () async {
              await showDialog(
                context: context,
                builder: (context) => AddManualPlayerDialog(hubId: widget.hubId),
              );
              // Refresh the list after adding
              _members.clear();
              _lastDocument = null;
              _hasMore = true;
              await _loadMembers();
            },
          ),

        // 2. Add from Contacts (managers only)
        if (isManager)
          SpeedDialChild(
            child: const Icon(Icons.contacts, color: Colors.white),
            backgroundColor: PremiumColors.accent,
            label: 'הוסף מאנשי הקשר',
            labelStyle: const TextStyle(fontSize: 14),
            onTap: () async {
              await _addFromContacts(context);
            },
          ),

        // 3. Share WhatsApp Link (everyone)
        SpeedDialChild(
          child: const Icon(Icons.share, color: Colors.white),
          backgroundColor: Colors.green,
          label: 'שתף קישור WhatsApp',
          labelStyle: const TextStyle(fontSize: 14),
          onTap: () async {
            await _shareHubOnWhatsApp(context, hub);
          },
        ),

        // 4. Player Archive (managers only)
        if (isManager)
          SpeedDialChild(
            child: const Icon(Icons.archive, color: Colors.white),
            backgroundColor: Colors.orange,
            label: 'ארכיון שחקנים',
            labelStyle: const TextStyle(fontSize: 14),
            onTap: () {
              context.push('/hubs/${widget.hubId}/players/archive');
            },
          ),
      ],
    );
  }

  /// Share hub on WhatsApp
  Future<void> _shareHubOnWhatsApp(BuildContext context, Hub hub) async {
    try {
      final String shareText = '''
היי! הצטרף לקבוצת הכדורגל שלנו "${hub.name}" באפליקציית Kickaboor!

להצטרפות, הורד את האפליקציה וחפש את הקבוצה שלנו.
''';

      await Share.share(
        shareText,
        subject: 'הזמנה לקבוצת ${hub.name}',
      );
    } catch (e) {
      debugPrint('Error sharing hub: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה בשיתוף'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Add player from contacts
  Future<void> _addFromContacts(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => ContactPickerDialog(hubId: widget.hubId),
    );

    // Refresh the list after adding
    _members.clear();
    _lastDocument = null;
    _hasMore = true;
    await _loadMembers();
  }

  /// Show player actions bottom sheet
  Future<void> _showPlayerActionsBottomSheet(
    BuildContext context,
    HubMemberWithUser member,
    bool isManager,
  ) async {
    final user = member.user;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PremiumColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: user.photoUrl != null
                        ? CachedNetworkImageProvider(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: PremiumTypography.heading3,
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
                          style: PremiumTypography.heading3,
                        ),
                        if (member.managerRating != null)
                          Text(
                            'דירוג: ${member.managerRating!.toStringAsFixed(1)}',
                            style: PremiumTypography.bodySmall.copyWith(
                              color: PremiumColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Actions
            ListTile(
              leading: const Icon(Icons.person, color: PremiumColors.primary),
              title: const Text('צפה בכרטיס שחקן'),
              onTap: () {
                Navigator.pop(context);
                context.push('/profile/${user.uid}');
              },
            ),

            // Edit Player (managers + fictitious only)
            if (isManager && user.isFictitious)
              ListTile(
                leading: const Icon(Icons.edit, color: PremiumColors.accent),
                title: const Text('ערוך שחקן'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show edit dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('עריכת שחקנים תתמוך בגרסה הבאה'),
                    ),
                  );
                },
              ),

            // Archive Player (managers only)
            if (isManager)
              ListTile(
                leading: const Icon(Icons.archive, color: Colors.orange),
                title: const Text('העבר לארכיון'),
                onTap: () async {
                  Navigator.pop(context);
                  await _archivePlayer(context, member);
                },
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Archive a player
  Future<void> _archivePlayer(
    BuildContext context,
    HubMemberWithUser member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('העבר לארכיון'),
        content: Text('האם להעביר את ${member.user.name} לארכיון?\n\nהשחקן לא יוכל להשתתף במשחקים עתידיים, אך ניתן לשחזר אותו בכל עת.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('העבר לארכיון'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final hubsRepo = ref.read(hubsRepositoryProvider);
        await hubsRepo.updateMemberStatus(
          widget.hubId,
          member.userId,
          models.HubMemberStatus.archived,
          reason: 'הועבר לארכיון על ידי מנהל',
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member.user.name} הועבר לארכיון'),
              backgroundColor: Colors.orange,
            ),
          );

          // Refresh the list
          _members.clear();
          _lastDocument = null;
          _hasMore = true;
          await _loadMembers();
        }
      } catch (e) {
        debugPrint('Error archiving player: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('שגיאה בהעברה לארכיון'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildNormalTile(
      HubMemberWithUser member, bool canViewRatings, bool canManageRatings) {
    final user = member.user;
    final managerRating = canViewRatings ? member.managerRating : null;
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
          if (canViewRatings)
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
          const SizedBox(height: 4),
          if (user.heightCm != null || user.weightKg != null)
            Row(
              children: [
                if (user.heightCm != null) ...[
                  Icon(Icons.straighten, size: 14, color: PremiumColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('${user.heightCm!.toInt()} ס״מ',
                      style: PremiumTypography.bodySmall),
                ],
                if (user.heightCm != null && user.weightKg != null)
                  const SizedBox(width: 12),
                if (user.weightKg != null) ...[
                  Icon(Icons.fitness_center, size: 14, color: PremiumColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('${user.weightKg!.toInt()} ק״ג',
                      style: PremiumTypography.bodySmall),
                ],
              ],
            ),
        ],
      ),
      trailing: canManageRatings
          ? IconButton(
              icon: const Icon(Icons.edit_note, size: 20),
              tooltip: 'ערוך נתונים פיזיים',
              onPressed: () => _showEditPhysicalStatsDialog(user),
            )
          : null,
    );
  }

  Widget _buildRatingTile(User user, double currentRating) {
    // Keep dragging silky smooth by containing state per-tile.
    return StatefulBuilder(
      builder: (context, innerSetState) {
        double localValue =
            _tempRatings[user.uid] ?? _roundToNearestHalf(currentRating);
        final displayValue = _roundToNearestHalf(localValue);

        void updateValue(double value) {
          final clamped = value.clamp(1.0, 7.0);
          innerSetState(() => localValue = clamped);
          _tempRatings[user.uid] = clamped;
        }

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
                    displayValue.toStringAsFixed(1),
                    style: PremiumTypography.heading3
                        .copyWith(color: PremiumColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 10,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 12),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 22),
                        activeTrackColor: PremiumColors.primary,
                        inactiveTrackColor:
                            PremiumColors.surfaceVariant.withValues(alpha: 0.6),
                      ),
                      child: Slider(
                        value: localValue,
                        min: 1.0,
                        max: 7.0,
                        // Fine divisions for smooth drag (then rounded for display/save).
                        divisions: 60,
                        label: displayValue.toStringAsFixed(1),
                        onChanged: (value) => updateValue(value),
                        onChangeEnd: (_) =>
                            HapticFeedback.selectionClick(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: DropdownButton<double>(
                      value: displayValue,
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
                          updateValue(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Round rating to nearest 0.5 increment (1.0, 1.5, 2.0, ... 7.0)
  double _roundToNearestHalf(double value) {
    // Clamp to valid range
    final clamped = value.clamp(1.0, 7.0);
    // Round to nearest 0.5
    return (clamped * 2).round() / 2.0;
  }

  /// Show dialog to edit physical stats (height, weight) for a user
  Future<void> _showEditPhysicalStatsDialog(User user) async {
    final heightController = TextEditingController(
      text: user.heightCm?.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: user.weightKg?.toString() ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('עדכן נתונים פיזיים - ${user.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: heightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
              ],
              decoration: const InputDecoration(
                labelText: 'גובה (ס״מ)',
                border: OutlineInputBorder(),
                suffixText: 'ס״מ',
                prefixIcon: Icon(Icons.height),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
              ],
              decoration: const InputDecoration(
                labelText: 'משקל (ק״ג)',
                border: OutlineInputBorder(),
                suffixText: 'ק״ג',
                prefixIcon: Icon(Icons.fitness_center),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('שמור'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final height = heightController.text.trim().isEmpty
          ? null
          : double.tryParse(heightController.text.trim());
      final weight = weightController.text.trim().isEmpty
          ? null
          : double.tryParse(weightController.text.trim());

      // Validate ranges
      if (height != null && (height < 140 || height > 220)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('גובה לא סביר (140-220 ס״מ)')),
        );
        return;
      }
      if (weight != null && (weight < 40 || weight > 150)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('משקל לא סביר (40-150 ק״ג)')),
        );
        return;
      }

      await _updatePhysicalStats(user.uid, height, weight);
    }

    heightController.dispose();
    weightController.dispose();
  }

  /// Update physical stats for a user
  Future<void> _updatePhysicalStats(
      String userId, double? height, double? weight) async {
    try {
      final usersRepo = ref.read(usersRepositoryProvider);

      await usersRepo.updateUser(userId, {
        'heightCm': height,
        'weightKg': weight,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('נתונים פיזיים עודכנו בהצלחה')),
        );
        // Refresh the members list
        setState(() {
          _members.clear();
          _lastDocument = null;
          _hasMore = true;
        });
        _loadMembers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בעדכון: $e')),
        );
      }
    }
  }
}
