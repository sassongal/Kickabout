import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/futuristic/loading_state.dart';
import 'package:kattrick/widgets/futuristic/empty_state.dart';
import 'package:kattrick/widgets/futuristic/skeleton_loader.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/utils/geohash_utils.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:kattrick/data/repositories.dart';
import 'package:kattrick/models/models.dart' hide Notification;
import 'package:kattrick/models/notification.dart' as app_models;
import 'package:kattrick/screens/social/hub_chat_screen.dart';
import 'package:kattrick/screens/hub/add_manual_player_dialog.dart';
import 'package:kattrick/screens/hub/edit_manual_player_dialog.dart';
import 'package:kattrick/screens/hub/hub_events_tab.dart';
import 'package:kattrick/services/analytics_service.dart';
import 'package:kattrick/services/error_handler_service.dart';
import 'package:kattrick/models/hub_role.dart';
import 'package:kattrick/widgets/optimized_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/widgets/polls/polls_list_widget.dart';

/// Hub detail screen
class HubDetailScreen extends ConsumerStatefulWidget {
  final String hubId;

  const HubDetailScreen({super.key, required this.hubId});

  @override
  ConsumerState<HubDetailScreen> createState() => _HubDetailScreenState();
}

class _HubDetailScreenState extends ConsumerState<HubDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 4, vsync: this); // Events, Chat, Games, Polls
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Validate hubId before proceeding
    if (widget.hubId.isEmpty) {
      return AppScaffold(
        title: 'פרטי Hub',
        body: const Center(
          child: Text('שגיאה: מזהה Hub לא תקין'),
        ),
      );
    }

    // ConsumerState provides 'ref' automatically
    final currentUserId = ref.watch(currentUserIdProvider);
    // Use ref.read for repositories - they don't change, so no need to watch
    final hubsRepo = ref.read(hubsRepositoryProvider);
    final usersRepo = ref.read(usersRepositoryProvider);
    final venuesRepo = ref.read(venuesRepositoryProvider);

    final hubStream = hubsRepo.watchHub(widget.hubId);

    return StreamBuilder<Hub?>(
      stream: hubStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppScaffold(
            title: 'פרטי Hub',
            body: const FuturisticLoadingState(message: 'טוען פרטי Hub...'),
          );
        }

        if (snapshot.hasError) {
          return AppScaffold(
            title: 'פרטי Hub',
            body: FuturisticEmptyState(
              icon: Icons.error_outline,
              title: 'שגיאה בטעינת Hub',
              message: ErrorHandlerService().handleException(
                snapshot.error,
                context: 'Hub detail screen - hub loading',
              ),
              action: ElevatedButton.icon(
                onPressed: () {
                  // Retry by rebuilding - trigger rebuild via key change
                  // For ConsumerWidget, we can't use setState, so we'll just show the error
                },
                icon: const Icon(Icons.refresh),
                label: const Text('נסה שוב'),
              ),
            ),
          );
        }

        final hub = snapshot.data;
        if (hub == null) {
          return AppScaffold(
            title: 'פרטי Hub',
            body: const Center(child: Text('Hub לא נמצא')),
          );
        }

        // Check user role for admin permissions
        final roleAsync = ref.watch(hubRoleProvider(widget.hubId));
        final role = roleAsync.valueOrNull ?? UserRole.none;
        final isMember = role != UserRole.none;

        // Check if join requests are enabled
        final joinRequestsEnabled =
            hub.settings['allowJoinRequests'] as bool? ?? true;

        // If not a member, show non-member view
        if (!isMember && currentUserId != null) {
          return AppScaffold(
            title: hub.name,
            body: _NonMemberHubView(
              hub: hub,
              hubId: widget.hubId,
              venuesRepo: venuesRepo,
              usersRepo: usersRepo,
              joinRequestsEnabled: joinRequestsEnabled,
            ),
          );
        }

        return roleAsync.when(
          data: (role) {
            final isAdminRole = role == UserRole.admin;
            final hubPermissions = currentUserId != null
                ? HubPermissions(hub: hub, userId: currentUserId)
                : null;
            return AppScaffold(
              title: hub.name,
              floatingActionButton: hubPermissions != null &&
                      (hubPermissions.canCreateGames() ||
                          hubPermissions.canInvitePlayers())
                  ? _HubAdminSpeedDial(
                      hubId: widget.hubId, permissions: hubPermissions)
                  : null,
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Hub info card (compact)
                          Card(
                            margin: const EdgeInsets.all(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // User role badge (compact, top left)
                                  if (currentUserId != null) ...[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Builder(
                                          builder: (context) {
                                            final hubPermissions =
                                                HubPermissions(
                                                    hub: hub,
                                                    userId: currentUserId);
                                            final role =
                                                hubPermissions.userRole;
                                            final roleName = role.displayName;

                                            // Set icon based on actual role
                                            IconData roleIcon;
                                            switch (role) {
                                              case HubRole.manager:
                                                roleIcon =
                                                    Icons.admin_panel_settings;
                                                break;
                                              case HubRole.moderator:
                                                roleIcon = Icons.shield;
                                                break;
                                              case HubRole.veteran:
                                                roleIcon = Icons.star;
                                                break;
                                              case HubRole.member:
                                                roleIcon = Icons.person;
                                                break;
                                              case HubRole.guest:
                                                roleIcon = Icons.person_outline;
                                                break;
                                            }

                                            return Chip(
                                              label: Text(roleName),
                                              avatar: Icon(
                                                roleIcon,
                                                size: 16,
                                              ),
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .primaryContainer,
                                              labelStyle: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                              ),
                                            );
                                          },
                                        ),
                                        // Hub creation date (compact, top right)
                                        Text(
                                          'נוצר: ${DateFormat('dd/MM/yyyy', 'he').format(hub.createdAt)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                                fontSize: 11,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  // Compact member count
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.group,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${hub.memberCount} משתתפים',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontSize: 12,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Command Center - Compact Header (for managers/moderators)
                                  if (hubPermissions != null &&
                                      (hubPermissions.isManager() ||
                                          hubPermissions.isModerator())) ...[
                                    // Row 1: Top Actions (Manager Mode Toggle + IconButtons)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Manager Mode Toggle (left)
                                        Switch(
                                          value:
                                              false, // TODO: Implement manager mode state
                                          onChanged: (value) {
                                            // TODO: Implement manager mode toggle
                                          },
                                          activeThumbColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        // Right: Compact IconButtons
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Requests badge (Manager only)
                                            StreamBuilder<QuerySnapshot>(
                                              stream: FirebaseFirestore.instance
                                                  .collection('hubs')
                                                  .doc(widget.hubId)
                                                  .collection('requests')
                                                  .where('status',
                                                      isEqualTo: 'pending')
                                                  .snapshots(),
                                              builder: (context, snapshot) {
                                                final pendingCount = snapshot
                                                        .data?.docs.length ??
                                                    0;
                                                return Stack(
                                                  children: [
                                                    if (hubPermissions
                                                        .canManageMembers())
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.inbox,
                                                            size: 20),
                                                        tooltip:
                                                            'בקשות הצטרפות',
                                                        onPressed: () =>
                                                            context.push(
                                                                '/hubs/${hub.hubId}/requests'),
                                                        color: Colors.orange,
                                                      ),
                                                    if (pendingCount > 0)
                                                      Positioned(
                                                        right: 8,
                                                        top: 8,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(4),
                                                          decoration:
                                                              const BoxDecoration(
                                                            color: Colors.red,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          constraints:
                                                              const BoxConstraints(
                                                            minWidth: 16,
                                                            minHeight: 16,
                                                          ),
                                                          child: Text(
                                                            pendingCount > 9
                                                                ? '9+'
                                                                : '$pendingCount',
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                );
                                              },
                                            ),
                                            if (hubPermissions
                                                .canManageMembers())
                                              IconButton(
                                                icon: const Icon(Icons.gpp_bad,
                                                    size: 20),
                                                tooltip: 'משתמשים מנופים',
                                                onPressed: () => context.push(
                                                    '/hubs/${hub.hubId}/banned'),
                                                color: Colors.red,
                                              ),
                                            IconButton(
                                              icon: const Icon(Icons.share,
                                                  size: 20),
                                              tooltip: 'שתף ב-WhatsApp',
                                              onPressed: () =>
                                                  _shareHubOnWhatsApp(hub),
                                              color: Colors.green,
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.visibility,
                                                  size: 20),
                                              tooltip: 'סקאוטינג',
                                              onPressed: () => context.push(
                                                  '/hubs/${hub.hubId}/scouting'),
                                              color: Colors.blue,
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.analytics,
                                                  size: 20),
                                              tooltip: 'ניתוח',
                                              onPressed: () => context.push(
                                                  '/hubs/${hub.hubId}/analytics'),
                                              color: Colors.purple,
                                            ),
                                            if (hubPermissions.canCreatePosts())
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.person_search),
                                                    color: Colors.orange,
                                                    iconSize: 28,
                                                    onPressed: () => context.push(
                                                        '/hubs/${hub.hubId}/create-recruiting-post'),
                                                    tooltip: 'מחפש שחקנים',
                                                  ),
                                                  const Text(
                                                    'מחפש שחקנים',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.orange,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Row 2: Management Buttons (Settings & Roles)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Opacity(
                                            opacity: hubPermissions
                                                    .canManageSettings()
                                                ? 1.0
                                                : 0.5,
                                            child: OutlinedButton.icon(
                                              onPressed: hubPermissions
                                                      .canManageSettings()
                                                  ? () => context.push(
                                                      '/hubs/${hub.hubId}/settings')
                                                  : null,
                                              icon: const Icon(Icons.settings,
                                                  size: 18),
                                              label: const Text('הגדרות'),
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8),
                                                minimumSize: const Size(0, 36),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => context.push(
                                                '/hubs/${hub.hubId}/manage-roles'),
                                            icon: const Icon(
                                                Icons.admin_panel_settings,
                                                size: 18),
                                            label: const Text('תפקידים'),
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              minimumSize: const Size(0, 36),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Row 3: Home Venue
                                    _HomeVenueSelector(
                                      hubId: widget.hubId,
                                      venuesRepo: venuesRepo,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          // Venues list (compact) - outside Card
                          _VenuesList(
                              hubId: widget.hubId, venuesRepo: venuesRepo),
                          // Regular member actions
                          if (!isAdminRole &&
                              currentUserId != null &&
                              isMember) ...[
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => _toggleMembership(
                                  context, ref, hub, isMember),
                              icon: const Icon(Icons.exit_to_app, size: 18),
                              label: const Text('עזוב Hub'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onError,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Hub Members button (compact)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              context.push('/hubs/${hub.hubId}/players'),
                          icon: const Icon(Icons.groups_3, size: 20),
                          label: Text(
                            'חברי ההאב (${hub.memberCount})',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    // Share and Rules buttons (compact)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            // Share on WhatsApp button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _shareHubOnWhatsApp(hub),
                                icon: const Icon(Icons.share, size: 16),
                                label: const Text('שתף'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            // Rules button (if rules exist)
                            if (hub.hubRules != null &&
                                hub.hubRules!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    context.push('/hubs/${hub.hubId}/rules'),
                                icon: const Icon(Icons.rule, size: 16),
                                label: const Text('חוקים'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // TabBar (pinned)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          tabs: const [
                            Tab(icon: Icon(Icons.event), text: 'אירועים'),
                            Tab(icon: Icon(Icons.chat), text: 'צ\'אט'),
                            Tab(
                                icon: Icon(Icons.sports_soccer),
                                text: 'משחקים'),
                            Tab(icon: Icon(Icons.poll), text: 'סקרים'),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    // Events tab (first)
                    HubEventsTab(
                      hubId: widget.hubId,
                      hub: hub,
                      isManager: isAdminRole,
                    ),
                    // Chat tab (second)
                    HubChatScreen(hubId: widget.hubId),
                    // Games tab (third)
                    _GamesTab(hubId: widget.hubId),
                    // Polls tab (fourth)
                    _PollsTab(hubId: widget.hubId, isManager: isAdminRole),
                  ],
                ),
              ),
            );
          },
          loading: () => AppScaffold(
            title: hub.name,
            body: const FuturisticLoadingState(message: 'בודק הרשאות...'),
          ),
          error: (error, stack) => AppScaffold(
            title: hub.name,
            body: FuturisticEmptyState(
              icon: Icons.error_outline,
              title: 'שגיאה בבדיקת הרשאות',
              message: error.toString(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareHubOnWhatsApp(Hub hub) async {
    try {
      // Generate deep link
      final deepLink = 'kattrick://hub/${hub.hubId}';
      final webLink =
          'https://kattrick.app/hub/${hub.hubId}'; // Fallback web link

      final message =
          'בוא לשחק איתנו ב-${hub.name}!\nהצטרף כאן: $webLink\n\n$deepLink';

      final uri = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent(message)}',
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: copy to clipboard
        await Clipboard.setData(ClipboardData(text: message));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('הקישור הועתק ללוח'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error sharing hub on WhatsApp: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה בשיתוף'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleMembership(
    BuildContext context,
    WidgetRef ref,
    Hub hub,
    bool isMember,
  ) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    final hubsRepo = ref.read(hubsRepositoryProvider);

    try {
      if (isMember) {
        await hubsRepo.removeMember(widget.hubId, currentUserId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('עזבת את ה-Hub')),
          );
        }
      } else {
        await hubsRepo.addMember(widget.hubId, currentUserId);

        // Log analytics
        try {
          final analytics = AnalyticsService();
          await analytics.logHubJoined(hubId: widget.hubId);
        } catch (e) {
          debugPrint('Failed to log analytics: $e');
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('הצטרפת ל-Hub')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')),
        );
      }
    }
  }
}

/// Games tab widget
class _GamesTab extends ConsumerStatefulWidget {
  final String hubId;

  const _GamesTab({required this.hubId});

  @override
  ConsumerState<_GamesTab> createState() => _GamesTabState();
}

class _GamesTabState extends ConsumerState<_GamesTab> {
  @override
  Widget build(BuildContext context) {
    final gamesRepo = ref.watch(gamesRepositoryProvider);
    final gamesStream = gamesRepo.watchGamesByHub(widget.hubId);

    return StreamBuilder<List<Game>>(
      stream: gamesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SkeletonLoader(height: 80),
            ),
          );
        }

        if (snapshot.hasError) {
          return FuturisticEmptyState(
            icon: Icons.error_outline,
            title: 'שגיאה בטעינת משחקים',
            message: ErrorHandlerService().handleException(
              snapshot.error,
              context: 'Hub detail - games tab',
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

        final games = snapshot.data ?? [];
        final currentUserId = ref.watch(currentUserIdProvider);
        final hubPermissionsAsync = currentUserId != null
            ? ref.watch(hubPermissionsProvider(
                (hubId: widget.hubId, userId: currentUserId)))
            : null;
        final hubPermissions = hubPermissionsAsync?.valueOrNull;
        final canCreateGames = hubPermissions?.canCreateGames() ?? false;

        return Column(
          children: [
            // Coming Soon Placeholder - Futuristic Design
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Neon Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.sports_soccer,
                      size: 64,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    'Games Schedule',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // "Coming Soon" badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Coming Soon',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Subtext
                  Text(
                    'Track all hub matches and stats here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withValues(alpha: 0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Add game log button (for authorized users)
            if (canCreateGames)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/hubs/${widget.hubId}/log-past-game'),
                  icon: const Icon(Icons.add),
                  label: const Text('תיעוד משחק'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            // Games list
            Expanded(
              child: games.isEmpty
                  ? FuturisticEmptyState(
                      icon: Icons.sports_soccer,
                      title: 'אין משחקים עדיין',
                      message: canCreateGames
                          ? 'תעד משחק חדש כדי להתחיל'
                          : 'אין משחקים להצגה',
                    )
                  : ListView.builder(
                      itemCount: games.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        final game = games[index];
                        final isCompleted = game.status == GameStatus.completed;
                        final canEdit =
                            currentUserId == game.createdBy || canCreateGames;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              isCompleted
                                  ? Icons.check_circle
                                  : Icons.sports_soccer,
                              color: isCompleted ? Colors.green : null,
                            ),
                            title: Text(
                              '${game.gameDate.day}/${game.gameDate.month}/${game.gameDate.year} ${game.gameDate.hour}:${game.gameDate.minute.toString().padLeft(2, '0')}',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (game.legacyTeamAScore != null &&
                                    game.legacyTeamBScore != null)
                                  Text(
                                      'תוצאה: ${game.legacyTeamAScore} - ${game.legacyTeamBScore}'),
                                if (game.eventId != null)
                                  Text('אירוע: ${game.eventId}',
                                      style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (canEdit)
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => context.push(
                                        '/hubs/${widget.hubId}/games/${game.gameId}/edit'),
                                    tooltip: 'ערוך משחק',
                                  ),
                                const Icon(Icons.chevron_left),
                              ],
                            ),
                            onTap: () => context.push('/games/${game.gameId}'),
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

/// Members tab widget
class _MembersTab extends ConsumerStatefulWidget {
  final String hubId;
  final Hub hub;
  const _MembersTab({
    required this.hubId,
    required this.hub,
  });

  @override
  ConsumerState<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends ConsumerState<_MembersTab> {
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
          return FuturisticEmptyState(
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
          return FuturisticEmptyState(
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
          return FuturisticEmptyState(
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
            if (hubPermissions != null && hubPermissions.canManageMembers())
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
                      child: Center(child: CircularProgressIndicator()),
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
                  IconData roleIcon;
                  Color? roleColor;

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

/// Venues list widget
/// Home Venue Selector - allows managers to select the hub's home field
class _HomeVenueSelector extends ConsumerWidget {
  final String hubId;
  final VenuesRepository venuesRepo;

  const _HomeVenueSelector({
    required this.hubId,
    required this.venuesRepo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubsRepo = ref.read(hubsRepositoryProvider);
    final hubStream = hubsRepo.watchHub(hubId);

    return StreamBuilder<Hub?>(
      stream: hubStream,
      builder: (context, hubSnapshot) {
        final hub = hubSnapshot.data;
        if (hub == null) {
          return const SizedBox.shrink();
        }

        return _HomeVenueSelectorContent(
          hubId: hubId,
          hub: hub,
          venuesRepo: venuesRepo,
        );
      },
    );
  }
}

class _HomeVenueSelectorContent extends ConsumerStatefulWidget {
  final String hubId;
  final Hub hub;
  final VenuesRepository venuesRepo;

  const _HomeVenueSelectorContent({
    required this.hubId,
    required this.hub,
    required this.venuesRepo,
  });

  @override
  ConsumerState<_HomeVenueSelectorContent> createState() =>
      _HomeVenueSelectorContentState();
}

class _HomeVenueSelectorContentState
    extends ConsumerState<_HomeVenueSelectorContent> {
  bool _isLoading = false;
  String? _lastMainVenueId;

  @override
  void initState() {
    super.initState();
    _lastMainVenueId = widget.hub.mainVenueId ?? widget.hub.primaryVenueId;
  }

  @override
  void didUpdateWidget(_HomeVenueSelectorContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If mainVenueId changed, update the last known ID to trigger FutureBuilder refresh
    final newMainVenueId = widget.hub.mainVenueId ?? widget.hub.primaryVenueId;
    if (newMainVenueId != _lastMainVenueId) {
      _lastMainVenueId = newMainVenueId;
      // Force rebuild to reload venue
      setState(() {});
    }
  }

  Future<void> _selectHomeVenue() async {
    setState(() => _isLoading = true);

    try {
      // Navigate to discover venues screen
      final result = await context.push<dynamic>('/venues/discover');

      if (result != null && mounted) {
        final hubsRepo = ref.read(hubsRepositoryProvider);
        final currentUserId = ref.read(currentUserIdProvider);

        if (result is Venue) {
          // Existing venue selected - use setHubPrimaryVenue for transaction and hubCount update
          // This function already updates primaryVenueId, mainVenueId, and primaryVenueLocation
          await hubsRepo.setHubPrimaryVenue(widget.hubId, result.venueId);

          // Also update location and geohash for consistency (mainVenueId is already updated by setHubPrimaryVenue)
          final geohash = GeohashUtils.encode(
            result.location.latitude,
            result.location.longitude,
            precision: 8,
          );

          await hubsRepo.updateHub(widget.hubId, {
            'location': result.location,
            'geohash': geohash,
          });
        } else if (result is Map<String, dynamic>) {
          // Manual location selected
          final location = result['location'] as GeoPoint;
          final name = result['name'] as String? ?? 'מגרש הבית';

          // Create venue first
          final venuesRepo = widget.venuesRepo;
          final newVenue = await venuesRepo.createManualVenue(
            name: name,
            address: result['address'] as String?,
            location: location,
            hubId: widget.hubId,
            createdBy: currentUserId,
            isPublic: false, // Hub's private venue
          );

          // Update hub with new venue - use setHubPrimaryVenue for transaction and hubCount update
          await hubsRepo.setHubPrimaryVenue(widget.hubId, newVenue.venueId);

          // Also update mainVenueId, location, and geohash for consistency
          final geohash = GeohashUtils.encode(
            location.latitude,
            location.longitude,
            precision: 8,
          );

          await hubsRepo.updateHub(widget.hubId, {
            'mainVenueId': newVenue.venueId,
            'location': location,
            'geohash': geohash,
          });
        }

        if (mounted) {
          // Force rebuild to reload venue after save
          setState(() {
            _lastMainVenueId =
                widget.hub.mainVenueId ?? widget.hub.primaryVenueId;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('מגרש הבית עודכן בהצלחה!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בעדכון מגרש הבית: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use primaryVenueId if mainVenueId is not set (for backward compatibility)
    final venueIdToLoad = widget.hub.mainVenueId ?? widget.hub.primaryVenueId;

    // Update last known ID to track changes and force rebuild if changed
    if (venueIdToLoad != _lastMainVenueId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _lastMainVenueId = venueIdToLoad;
          });
        }
      });
    }

    return FutureBuilder<Venue?>(
      key: ValueKey(
          'home_venue_${venueIdToLoad ?? 'none'}'), // Force rebuild when venueId changes
      future: venueIdToLoad != null && venueIdToLoad.isNotEmpty
          ? widget.venuesRepo.getVenue(venueIdToLoad)
          : Future.value(null),
      builder: (context, snapshot) {
        final homeVenue = snapshot.data;

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.sports_soccer,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'מגרש בית',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        homeVenue != null ? homeVenue.name : 'לא נבחר',
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (homeVenue?.address != null)
                        Text(
                          homeVenue!.address!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: _selectHomeVenue,
                    tooltip:
                        homeVenue != null ? 'ערוך מגרש בית' : 'בחר מגרש בית',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VenuesList extends ConsumerWidget {
  final String hubId;
  final VenuesRepository venuesRepo;

  const _VenuesList({
    required this.hubId,
    required this.venuesRepo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesStream = venuesRepo.watchVenuesByHub(hubId);

    return StreamBuilder<List<Venue>>(
      stream: venuesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SkeletonLoader(height: 60),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'שגיאה בטעינת מגרשים',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              ],
            ),
          );
        }

        final venues = snapshot.data ?? [];

        if (venues.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.location_off,
                  size: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  'אין מגרשים רשומים',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'מגרשים (${venues.length})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...venues.map((venue) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              venue.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            if (venue.address != null &&
                                venue.address!.isNotEmpty)
                              Text(
                                venue.address ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }
}

/// Non-member hub view - shows hub info for users who are not members
class _NonMemberHubView extends ConsumerStatefulWidget {
  final Hub hub;
  final String hubId;
  final VenuesRepository venuesRepo;
  final UsersRepository usersRepo;
  final bool joinRequestsEnabled;

  const _NonMemberHubView({
    required this.hub,
    required this.hubId,
    required this.venuesRepo,
    required this.usersRepo,
    required this.joinRequestsEnabled,
  });

  @override
  ConsumerState<_NonMemberHubView> createState() => _NonMemberHubViewState();
}

class _NonMemberHubViewState extends ConsumerState<_NonMemberHubView> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _showJoinRequestDialog(BuildContext context) async {
    final messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('בקשת הצטרפות ל-${widget.hub.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'הוסף הודעה למנהל ההאב... (אופציונלי)',
                border: OutlineInputBorder(),
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
            child: const Text('שלח בקשה'),
          ),
        ],
      ),
    );

    if (result == true) {
      _messageController.text = messageController.text;
      await _sendJoinRequest();
    }

    messageController.dispose();
  }

  Future<void> _sendJoinRequest() async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא להתחבר')),
      );
      return;
    }

    final message = _messageController.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final notificationsRepo = ref.read(notificationsRepositoryProvider);
      final usersRepo = ref.read(usersRepositoryProvider);
      final firestore = FirebaseFirestore.instance;

      // Get current user for notification
      final requestingUser = await usersRepo.getUser(currentUserId);
      if (requestingUser == null) {
        throw Exception('לא ניתן למצוא את פרטי המשתמש');
      }

      // Get hub manager (creator)
      final managerId = widget.hub.createdBy;

      // 1. Save join request to Firestore: hubs/{hubId}/requests/{userId}
      await firestore
          .collection('hubs')
          .doc(widget.hubId)
          .collection('requests')
          .doc(currentUserId)
          .set({
        'userId': currentUserId,
        'hubId': widget.hubId,
        'message': message.isNotEmpty ? message : null,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'userName': requestingUser.name,
        'userPhotoUrl': requestingUser.photoUrl,
      });

      // 2. Create notification for hub manager
      final notification = app_models.Notification(
        notificationId: '', // Will be generated by createNotification
        userId: managerId,
        type: 'join_request',
        title: 'בקשת הצטרפות ל-${widget.hub.name}',
        body: message.isNotEmpty
            ? '${requestingUser.name} מבקש להצטרף: $message'
            : '${requestingUser.name} מבקש להצטרף להאב',
        read: false,
        createdAt: DateTime.now(),
        data: {
          'hubId': widget.hubId,
          'requestingUserId': currentUserId,
          'requestId': currentUserId, // Use userId as requestId
        },
      );

      await notificationsRepo.createNotification(notification);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הבקשה להצטרפות נשלחה למנהל ההאב'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear message field
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשליחת הבקשה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final venuesStream = widget.venuesRepo.watchVenuesByHub(widget.hubId);
    final showManagerContact =
        widget.hub.settings['showManagerContactInfo'] as bool? ?? true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hub profile image
          Center(
            child: widget.hub.profileImageUrl != null
                ? OptimizedImage(
                    imageUrl: widget.hub.profileImageUrl ?? '',
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(16),
                    errorWidget: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.group, size: 80),
                    ),
                  )
                : Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.group, size: 80),
                  ),
          ),
          const SizedBox(height: 24),

          // Hub name
          Center(
            child: Text(
              widget.hub.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // Number of participants
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.group,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.hub.memberCount} משתתפים',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          if (widget.hub.description != null &&
              widget.hub.description!.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.hub.description ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Contact Manager button
          if (showManagerContact) ...[
            _ContactManagerButton(
              hub: widget.hub,
              usersRepo: widget.usersRepo,
            ),
            const SizedBox(height: 16),
          ],

          // Venues list
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'מגרשים',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<Venue>>(
                    stream: venuesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final venues = snapshot.data ?? [];
                      if (venues.isEmpty) {
                        return Text(
                          'אין מגרשים רשומים',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        );
                      }

                      return Column(
                        children: venues.map((venue) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        venue.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                      if (venue.address != null &&
                                          venue.address!.isNotEmpty)
                                        Text(
                                          venue.address ?? '',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Join request section
          if (widget.joinRequestsEnabled) ...[
            // If hub is private, show "Request to Join" button that opens a dialog
            if (widget.hub.isPrivate) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => _showJoinRequestDialog(context),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add),
                  label: Text(_isSubmitting ? 'שולח...' : 'בקש להצטרף'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ] else ...[
              // If hub is not private, show the full form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'הודעה (אופציונלי)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _messageController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'כתוב הודעה למנהל ההאב...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _sendJoinRequest,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                              _isSubmitting ? 'שולח...' : 'שלח בקשת הצטרפות'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ] else ...[
            Card(
              color: Colors.grey[200],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'האב סגור',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[700],
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Contact Manager button widget
class _ContactManagerButton extends ConsumerWidget {
  final Hub hub;
  final UsersRepository usersRepo;

  const _ContactManagerButton({
    required this.hub,
    required this.usersRepo,
  });

  Future<void> _contactManager(BuildContext context) async {
    try {
      // Get manager user (hub creator)
      final manager = await usersRepo.getUser(hub.createdBy);
      if (manager == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('לא ניתן למצוא את מנהל ההאב')),
          );
        }
        return;
      }

      if (!context.mounted) return;
      // Show dialog with contact options
      final contactMethod = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('צור קשר עם ${manager.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (manager.phoneNumber != null &&
                  manager.phoneNumber!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.green),
                  title: const Text('WhatsApp'),
                  subtitle: Text(manager.phoneNumber!),
                  onTap: () => Navigator.pop(context, 'whatsapp'),
                ),
              if (manager.email.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.blue),
                  title: const Text('אימייל'),
                  subtitle: Text(manager.email),
                  onTap: () => Navigator.pop(context, 'email'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול'),
            ),
          ],
        ),
      );

      if (contactMethod == null) return;

      if (contactMethod == 'whatsapp' && manager.phoneNumber != null) {
        // Open WhatsApp
        final phone = manager.phoneNumber!.replaceAll(RegExp(r'[-\s]'), '');
        final url = Uri.parse('https://wa.me/$phone');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('לא ניתן לפתוח WhatsApp')),
            );
          }
        }
      } else if (contactMethod == 'email') {
        // Open email
        final url = Uri.parse(
            'mailto:${manager.email}?subject=בקשה להצטרפות ל-${hub.name}');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('לא ניתן לפתוח אפליקציית אימייל')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'צור קשר עם מנהל ההאב',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _contactManager(context),
                icon: const Icon(Icons.contact_support),
                label: const Text('צור קשר'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SliverAppBarDelegate for TabBar in NestedScrollView
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

class _HubAdminSpeedDial extends StatelessWidget {
  final String hubId;
  final HubPermissions permissions;

  const _HubAdminSpeedDial({required this.hubId, required this.permissions});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: primaryColor,
      foregroundColor: onPrimaryColor,
      spacing: 12,
      spaceBetweenChildren: 8,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      children: [
        if (permissions.canCreateGames())
          SpeedDialChild(
            child: const Icon(Icons.event, color: Colors.black),
            backgroundColor: const Color(0xFFFF6B35), // Vibrant orange
            foregroundColor: Colors.black,
            label: 'צור משחק',
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            labelBackgroundColor: Colors.black87,
            onTap: () => context.push('/games/create?hubId=$hubId'),
          ),
        if (permissions.canInvitePlayers())
          SpeedDialChild(
            child: const Icon(Icons.person_search, color: Colors.black),
            backgroundColor: const Color(0xFF39FF14), // Neon green
            foregroundColor: Colors.black,
            label: 'חפש שחקנים',
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            labelBackgroundColor: Colors.black87,
            onTap: () => context.push('/hubs/$hubId/scouting'),
          ),
      ],
    );
  }
}

/// Polls Tab Widget
class _PollsTab extends StatelessWidget {
  final String hubId;
  final bool isManager;

  const _PollsTab({
    required this.hubId,
    required this.isManager,
  });

  @override
  Widget build(BuildContext context) {
    return PollsListWidget(
      hubId: hubId,
      showCreateButton: isManager,
    );
  }
}
