import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/widgets/futuristic/skeleton_loader.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/data/repositories.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/screens/social/feed_screen.dart';
import 'package:kickadoor/screens/social/hub_chat_screen.dart';
import 'package:kickadoor/screens/hub/add_manual_player_dialog.dart';
import 'package:kickadoor/screens/hub/edit_manual_player_dialog.dart';
import 'package:kickadoor/screens/hub/hub_events_tab.dart';
import 'package:kickadoor/screens/hub/hub_analytics_screen.dart';
import 'package:kickadoor/services/analytics_service.dart';
import 'package:kickadoor/models/hub_role.dart';

/// Hub detail screen
class HubDetailScreen extends ConsumerStatefulWidget {
  final String hubId;

  const HubDetailScreen({super.key, required this.hubId});

  @override
  ConsumerState<HubDetailScreen> createState() => _HubDetailScreenState();
}

class _HubDetailScreenState extends ConsumerState<HubDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
              message: snapshot.error.toString(),
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

        final isMember = currentUserId != null && hub.memberIds.contains(currentUserId);
        final hubPermissions = currentUserId != null
            ? HubPermissions(hub: hub, userId: currentUserId)
            : null;
        final isHubManager = hubPermissions?.isManager() ?? (currentUserId == hub.createdBy);

        return AppScaffold(
          title: hub.name,
          body: Column(
            children: [
              // Hub info card
              Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hub.description != null && hub.description!.isNotEmpty) ...[
                        Text(
                          hub.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Icon(
                            Icons.group,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${hub.memberIds.length} חברים',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Venues list
                      _VenuesList(hubId: widget.hubId, venuesRepo: venuesRepo),
                      const SizedBox(height: 8),
                      // Actions
                      if (isHubManager) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.push('/hubs/${hub.hubId}/settings'),
                                icon: const Icon(Icons.settings, size: 18),
                                label: const Text('הגדרות'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.push('/hubs/${hub.hubId}/manage-roles'),
                                icon: const Icon(Icons.admin_panel_settings, size: 18),
                                label: const Text('ניהול תפקידים'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => context.push('/games/create?hubId=${hub.hubId}'),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('משחק חדש'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.search),
                                label: const Text('גיוס שחקנים (AI)'),
                                onPressed: () => context.push('/hubs/${hub.hubId}/scouting'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.analytics),
                                label: const Text('אנליטיקס'),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HubAnalyticsScreen(hubId: hub.hubId),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (currentUserId != null) ...[
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _toggleMembership(context, ref, hub, isMember),
                          icon: Icon(isMember ? Icons.exit_to_app : Icons.person_add),
                          label: Text(isMember ? 'עזוב Hub' : 'הצטרף ל-Hub'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isMember
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                            foregroundColor: isMember
                                ? Theme.of(context).colorScheme.onError
                                : Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.sports_soccer), text: 'משחקים'),
                  Tab(icon: Icon(Icons.event), text: 'אירועים'),
                  Tab(icon: Icon(Icons.feed), text: 'פיד'),
                  Tab(icon: Icon(Icons.chat), text: 'צ\'אט'),
                  Tab(icon: Icon(Icons.group), text: 'חברים'),
                ],
              ),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Games tab
                    _GamesTab(hubId: widget.hubId),
                    // Events tab
                    HubEventsTab(
                      hubId: widget.hubId,
                      hub: hub,
                      isManager: isHubManager,
                    ),
                    // Feed tab
                    FeedScreen(hubId: widget.hubId),
                    // Chat tab
                    HubChatScreen(hubId: widget.hubId),
                    // Members tab - with button to full screen
                    _MembersTab(
                      hubId: widget.hubId,
                      hub: hub,
                      usersRepo: usersRepo,
                      onViewAll: () => context.push('/hubs/${hub.hubId}/players'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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
            message: snapshot.error.toString(),
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

        if (games.isEmpty) {
          return FuturisticEmptyState(
            icon: Icons.sports_soccer,
            title: 'אין משחקים עדיין',
            message: 'צור משחק חדש כדי להתחיל',
          );
        }

        return ListView.builder(
          itemCount: games.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final game = games[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.sports_soccer),
                title: Text('${game.gameDate.day}/${game.gameDate.month}/${game.gameDate.year}'),
                subtitle: Text('${game.gameDate.hour}:${game.gameDate.minute.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => context.push('/games/${game.gameId}'),
              ),
            );
          },
        );
      },
    );
  }
}

/// Members tab widget
class _MembersTab extends ConsumerWidget {
  final String hubId;
  final Hub hub;
  final UsersRepository usersRepo;
  final VoidCallback? onViewAll;

  const _MembersTab({
    required this.hubId,
    required this.hub,
    required this.usersRepo,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final isHubManager = currentUserId == hub.createdBy;

    return Column(
      children: [
        // Header with view all button
        if (hub.memberIds.isNotEmpty && onViewAll != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${hub.memberIds.length} שחקנים',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: onViewAll,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('צפה בכולם'),
                ),
              ],
            ),
          ),
        // Add manual player button (for managers)
        if (isHubManager)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => AddManualPlayerDialog(hubId: hubId),
                );
                if (result == true && context.mounted) {
                  // Refresh will happen automatically via StreamBuilder
                }
              },
              icon: const Icon(Icons.person_add),
              label: const Text('הוסף שחקן ידנית'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ),
        // Members list (limited to 10 in tab view)
        Expanded(
          child: hub.memberIds.isEmpty
              ? FuturisticEmptyState(
                  icon: Icons.people_outline,
                  title: 'אין חברים',
                  message: 'עדיין אין חברים ב-Hub זה',
                )
              : _buildMembersList(context, ref, limit: 10),
        ),
      ],
    );
  }

  Widget _buildMembersList(BuildContext context, WidgetRef ref, {int? limit}) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final isHubManager = currentUserId == hub.createdBy;

    return FutureBuilder<List<User>>(
      future: usersRepo.getUsers(hub.memberIds),
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
            message: snapshot.error.toString(),
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

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return FuturisticEmptyState(
            icon: Icons.people_outline,
            title: 'אין חברים',
            message: 'עדיין אין חברים ב-Hub זה',
          );
        }

        final displayUsers = limit != null && users.length > limit
            ? users.take(limit).toList()
            : users;

        return ListView.builder(
          itemCount: displayUsers.length + (limit != null && users.length > limit ? 1 : 0),
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            if (limit != null && users.length > limit && index == displayUsers.length) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: TextButton.icon(
                    onPressed: onViewAll,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text('צפה ב-${users.length - limit} נוספים'),
                  ),
                ),
              );
            }
            final user = displayUsers[index];
            final isManualPlayer = user.email.startsWith('manual_');
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: user.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            user.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                ),
                title: Row(
                  children: [
                    Text(user.name),
                    if (isManualPlayer) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.edit_note,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isManualPlayer) Text(user.email),
                    if (isManualPlayer) Text('שחקן ידני - ללא אפליקציה'),
                    if (user.city != null) Text('עיר: ${user.city}'),
                    if (user.preferredPosition.isNotEmpty)
                      Text('עמדה: ${user.preferredPosition}'),
                    Text('דירוג: ${user.currentRankScore.toStringAsFixed(1)}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isManualPlayer && isHubManager)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (context) => EditManualPlayerDialog(
                              player: user,
                              hubId: hubId,
                            ),
                          );
                          if (result == true && context.mounted) {
                            // Refresh will happen automatically via StreamBuilder
                          }
                        },
                        tooltip: 'ערוך שחקן',
                      ),
                    if (user.uid == hub.createdBy)
                      Chip(
                        label: const Text('יוצר'),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      ),
                  ],
                ),
                onTap: isManualPlayer
                    ? (isHubManager
                        ? () async {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (context) => EditManualPlayerDialog(
                                player: user,
                                hubId: hubId,
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
        );
      },
    );
  }
}

/// Venues list widget
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  'אין מגרשים רשומים',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (venue.address != null && venue.address!.isNotEmpty)
                          Text(
                            venue.address!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
