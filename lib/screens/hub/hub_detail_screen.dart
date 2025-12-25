import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/premium/loading_state.dart';
import 'package:kattrick/widgets/premium/empty_state.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/core/providers/complex_providers.dart';
import 'package:kattrick/models/models.dart' hide Notification;
import 'package:kattrick/screens/social/hub_chat_screen.dart';
import 'package:kattrick/screens/hub/hub_events_tab.dart';
import 'package:kattrick/services/error_handler_service.dart';
import 'package:kattrick/models/hub_role.dart';
import 'package:kattrick/widgets/hub/hub_header.dart';
import 'package:kattrick/widgets/hub/hub_games_tab.dart';
import 'package:kattrick/widgets/hub/hub_polls_tab.dart';
import 'package:kattrick/widgets/hub/hub_admin_speed_dial.dart';
import 'package:kattrick/widgets/hub/hub_non_member_view.dart';
import 'package:kattrick/widgets/premium/skeleton_loader.dart';

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

    // ARCHITECTURAL FIX: Use unified hub state provider instead of direct repository call
    final currentUserId = ref.watch(currentUserIdProvider);
    final hubAsync = ref.watch(hubStreamProvider(widget.hubId));

    return hubAsync.when(
      data: (hub) {
        if (hub == null) {
          return AppScaffold(
            title: 'פרטי Hub',
            body: const Center(child: Text('Hub לא נמצא')),
          );
        }

        // Repositories (only used for non-member view)
        final venuesRepo = ref.read(venuesRepositoryProvider);
        final usersRepo = ref.read(usersRepositoryProvider);

        // Check user role for admin permissions
        final roleAsync = ref.watch(hubRoleProvider(widget.hubId));
        final role = roleAsync.valueOrNull ?? UserRole.none;
        final isMember = role != UserRole.none;

        // Check if join requests are enabled (use typed settings)
        final joinRequestsEnabled = hub.settings.allowJoinRequests;

        // If not a member, show non-member view
        if (!isMember && currentUserId != null) {
          return AppScaffold(
            title: hub.name,
            body: HubNonMemberView(
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

            // Fetch permissions asynchronously - this will properly load membership data
            final hubPermissionsAsync = currentUserId != null
                ? ref.watch(hubPermissionsProvider(
                    (hubId: widget.hubId, userId: currentUserId)))
                : null;

            final hubPermissions = hubPermissionsAsync?.valueOrNull;

            return AppScaffold(
              title: hub.name,
              floatingActionButton: null,
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: HubHeader(
                        hubId: widget.hubId,
                        hub: hub,
                        hubPermissions: hubPermissions,
                        isMember: isMember,
                        isAdminRole: isAdminRole,
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
                    HubGamesTab(hubId: widget.hubId),
                    // Polls tab (fourth)
                    HubPollsTab(hubId: widget.hubId, isManager: isAdminRole),
                  ],
                ),
              ),
            );
          },
          loading: () => AppScaffold(
            title: hub.name,
            body: const PremiumLoadingState(message: 'בודק הרשאות...'),
          ),
          error: (error, stack) => AppScaffold(
            title: hub.name,
            body: PremiumEmptyState(
              icon: Icons.error_outline,
              title: 'שגיאה בבדיקת הרשאות',
              message: error.toString(),
            ),
          ),
        );
      },
      loading: () => const _HubDetailSkeleton(),
      error: (error, stack) => AppScaffold(
        title: 'פרטי Hub',
        body: PremiumEmptyState(
          icon: Icons.error_outline,
          title: 'שגיאה בטעינת Hub',
          message: ErrorHandlerService().handleException(
            error,
            context: 'Hub detail screen - hub loading',
          ),
          action: ElevatedButton.icon(
            onPressed: () => ref.invalidate(hubStreamProvider(widget.hubId)),
            icon: const Icon(Icons.refresh),
            label: const Text('נסה שוב'),
          ),
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

class _HubDetailSkeleton extends StatelessWidget {
  const _HubDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '...',
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner Skeleton
            const SkeletonLoader(
                width: double.infinity, height: 180, borderRadius: 0),
            const SizedBox(height: 16),
            // Avatar & Info Skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const SkeletonLoader(width: 80, height: 80, borderRadius: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonLoader(width: 150, height: 24),
                        SizedBox(height: 8),
                        SkeletonLoader(width: 100, height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Tabs Skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  SkeletonLoader(width: 60, height: 40),
                  SkeletonLoader(width: 60, height: 40),
                  SkeletonLoader(width: 60, height: 40),
                  SkeletonLoader(width: 60, height: 40),
                ],
              ),
            ),
            const Divider(),
            // Content Skeleton
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  SkeletonLoader(width: double.infinity, height: 100),
                  SizedBox(height: 16),
                  SkeletonLoader(width: double.infinity, height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
