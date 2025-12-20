import 'package:flutter/material.dart';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/models/hub_role.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/services/error_handler_service.dart';
import 'package:kattrick/services/hub_permissions_service.dart';
import 'package:kattrick/widgets/premium/empty_state.dart';
import 'package:kattrick/widgets/premium/skeleton_loader.dart';
import 'package:kattrick/screens/hub/add_manual_player_dialog.dart';
import 'package:kattrick/screens/hub/edit_manual_player_dialog.dart';

class HubMembersTab extends ConsumerStatefulWidget {
  final String hubId;
  final Hub hub;
  const HubMembersTab({
    super.key,
    required this.hubId,
    required this.hub,
  });

  @override
  ConsumerState<HubMembersTab> createState() => _HubMembersTabState();
}

class _HubMembersTabState extends ConsumerState<HubMembersTab> {
  // Pagination state
  final ScrollController _scrollController = ScrollController();
  List<User> _displayedUsers = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreUsers();
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    // Fetch member IDs from subcollection (Strategy B)
    final hubsRepo = ref.read(hubsRepositoryProvider);
    final usersRepo = ref.read(usersRepositoryProvider);
    final memberIds = await hubsRepo.getHubMemberIds(widget.hubId);
    final allUsers = await usersRepo.getUsers(memberIds);

    final nextIndex = _displayedUsers.length;
    final endIndex = (nextIndex + _pageSize).clamp(0, allUsers.length);

    if (nextIndex < allUsers.length) {
      setState(() {
        _displayedUsers.addAll(allUsers.sublist(nextIndex, endIndex));
        _hasMore = endIndex < allUsers.length;
        _isLoadingMore = false;
      });
    } else {
      setState(() {
        _hasMore = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final isHubManager = currentUserId == widget.hub.createdBy;
    final roleAsync = ref.watch(hubRoleProvider(widget.hubId));
    final isAdmin = roleAsync.valueOrNull == UserRole.admin;

    // Check if user is manager/admin (creator or has admin role)
    final isManagerOrAdmin = isHubManager || isAdmin;

    // Debug: Log member count to help diagnose issues
    debugPrint('🔍 Members Tab - hub.memberCount: ${widget.hub.memberCount}');

    return FutureBuilder<List<User>>(
      future: () async {
        final hubsRepo = ref.read(hubsRepositoryProvider);
        final usersRepo = ref.read(usersRepositoryProvider);
        final memberIds = await hubsRepo.getHubMemberIds(widget.hubId);
        return usersRepo.getUsers(memberIds);
      }(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SkeletonLoader(height: 60),
            ),
          );
        }

        if (snapshot.hasError) {
          return PremiumEmptyState(
            icon: Icons.error_outline,
            title: 'שגיאה בטעינת חברים',
            message: ErrorHandlerService().handleException(
              snapshot.error,
              context: 'Hub detail screen - members loading',
            ),
            action: ElevatedButton.icon(
              onPressed: () {
                // Retry by rebuilding - trigger rebuild via key change
                // For ConsumerWidget, we can't use setState, so we'll just show the error
              },
              icon: const Icon(Icons.refresh),
              label: const Text('נסה שוב'),
            ),
          );
        }

        final allUsers = snapshot.data!;

        // Initialize displayed users on first load or when data changes
        if (_displayedUsers.isEmpty ||
            _displayedUsers.length != allUsers.length ||
            (_displayedUsers.isNotEmpty &&
                _displayedUsers.first.uid != allUsers.first.uid)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _displayedUsers = allUsers.take(_pageSize).toList();
                _hasMore = allUsers.length > _pageSize;
              });
            }
          });
        }

        // Use displayed users if available, otherwise use first page
        final usersToShow = _displayedUsers.isNotEmpty
            ? _displayedUsers
            : allUsers.take(_pageSize).toList();
        final hasMoreToShow =
            _displayedUsers.isNotEmpty ? _hasMore : allUsers.length > _pageSize;

        // Debug: Log users found
        debugPrint('🔍 Members Tab - users found: ${allUsers.length}');
        // If memberCount > 0 but no users found, show error
        if (snapshot.hasError ||
            (snapshot.hasData &&
                snapshot.data!.isEmpty &&
                widget.hub.memberCount > 0)) {
          // If member count exists but no users found, show error with more info
          debugPrint(
              '⚠️ Members Tab - memberCount > 0 but no users found. memberCount: ${widget.hub.memberCount}');
          return PremiumEmptyState(
            icon: Icons.error_outline,
            title: 'שגיאה בטעינת החברים',
            message:
                'נמצאו ${widget.hub.memberCount} חברים ברשימה, אך לא ניתן לטעון את הפרטים שלהם',
            action: ElevatedButton.icon(
              onPressed: () {
                // Force rebuild by invalidating provider
                ref.invalidate(hubRoleProvider(widget.hubId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('נסה שוב'),
            ),
          );
        }

        if (usersToShow.isEmpty && allUsers.isEmpty) {
          return PremiumEmptyState(
            icon: Icons.people_outline,
            title: 'אין חברים',
            message: 'עדיין אין חברים ב-Hub זה',
          );
        }

        final hubPermissions = currentUserId != null
            ? HubPermissions(hub: widget.hub, userId: currentUserId)
            : null;

        return Column(
          children: [
            // Add manual player button (for managers/moderators)
            if (hubPermissions != null && hubPermissions.canManageMembers)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) =>
                            AddManualPlayerDialog(hubId: widget.hubId),
                      );
                      if (result == true && context.mounted) {
                        // Refresh will happen automatically via StreamBuilder
                        ref.invalidate(usersRepositoryProvider);
                      }
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('הוסף שחקן ידנית'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: usersToShow.length + (hasMoreToShow ? 1 : 0),
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  // Show loading indicator at the bottom if pagination is active
                  if (hasMoreToShow && index == usersToShow.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: KineticLoadingAnimation(size: 24)),
                    );
                  }

                  final user = usersToShow[index];
                  final isManualPlayer = user.email.startsWith('manual_');

                  // Get first and last name - prefer firstName/lastName if available, otherwise split name
                  String firstName;
                  String lastName = '';

                  if (user.firstName != null && user.firstName!.isNotEmpty) {
                    firstName = user.firstName!;
                  } else if (user.name.isNotEmpty && user.name.contains(' ')) {
                    final nameParts = user.name.split(' ');
                    firstName = nameParts.first;
                    if (nameParts.length > 1) {
                      lastName = nameParts.sublist(1).join(' ');
                    }
                  } else {
                    firstName =
                        user.name.isNotEmpty ? user.name : 'משתמש לא ידוע';
                    lastName = '';
                  }

                  if (user.lastName != null && user.lastName!.isNotEmpty) {
                    lastName = user.lastName!;
                  }

                  // Get user role in hub
                  final hubPermissions =
                      HubPermissions(hub: widget.hub, userId: user.uid);
                  String roleDisplayName;
                  IconData roleIcon = Icons.person_outline;
                  Color roleColor = Colors.grey.shade400;

                  try {
                    final role = hubPermissions.userRole;
                    // Use the actual role display name from HubRole enum
                    roleDisplayName = role.displayName;

                    // Set icon and color based on actual role
                    switch (role) {
                      case HubRole.manager:
                        roleIcon = Icons.admin_panel_settings;
                        roleColor = Colors.blue;
                        break;
                      case HubRole.moderator:
                        roleIcon = Icons.shield;
                        roleColor = Colors.purple;
                        break;
                      case HubRole.veteran:
                        roleIcon = Icons.star;
                        roleColor = Colors.amber;
                        break;
                      case HubRole.member:
                        roleIcon = Icons.person;
                        roleColor = Colors.grey;
                        break;
                      case HubRole.guest:
                        roleIcon = Icons.person_outline;
                        roleColor = Colors.grey.shade400;
                        break;
                    }
                  } catch (e) {
                    // User is not a member, show as guest
                    roleIcon = Icons.person_outline;
                    roleColor = Colors.grey.shade400;
                    roleDisplayName = 'אורח';
                  }

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        backgroundImage:
                            user.photoUrl != null && user.photoUrl!.isNotEmpty
                                ? NetworkImage(user.photoUrl!)
                                : null,
                        child: user.photoUrl == null || user.photoUrl!.isEmpty
                            ? Text(
                                // Use initials from firstName/lastName or name
                                (user.firstName != null &&
                                        user.lastName != null)
                                    ? '${user.firstName![0]}${user.lastName![0]}'
                                    : (firstName.isNotEmpty &&
                                            lastName.isNotEmpty)
                                        ? '${firstName[0]}${lastName[0]}'
                                        : firstName.isNotEmpty
                                            ? firstName[0]
                                            : '?',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              firstName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (lastName.isNotEmpty)
                            Text(
                              lastName,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          if (isManualPlayer)
                            Text(
                              'שחקן ידני - ללא אפליקציה',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isManualPlayer && isManagerOrAdmin)
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                final result = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => EditManualPlayerDialog(
                                    player: user,
                                    hubId: widget.hubId,
                                  ),
                                );
                                if (result == true && context.mounted) {
                                  // Refresh will happen automatically via StreamBuilder
                                }
                              },
                              tooltip: 'ערוך שחקן',
                            ),
                          // Show role badge with proper display name
                          Chip(
                            label: Text(roleDisplayName),
                            backgroundColor: roleColor.withValues(alpha: 0.2),
                            avatar: Icon(
                              roleIcon,
                              size: 16,
                              color: roleColor,
                            ),
                          ),
                        ],
                      ),
                      onTap: isManualPlayer
                          ? (isManagerOrAdmin
                              ? () async {
                                  final result = await showDialog<bool>(
                                    context: context,
                                    builder: (context) =>
                                        EditManualPlayerDialog(
                                      player: user,
                                      hubId: widget.hubId,
                                    ),
                                  );
                                  if (result == true && context.mounted) {
                                    // Refresh will happen automatically via StreamBuilder
                                  }
                                }
                              : null)
                          : () => context.push('/profile/${user.uid}'),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
