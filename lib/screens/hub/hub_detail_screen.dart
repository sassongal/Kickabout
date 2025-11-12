import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickabout/widgets/app_scaffold.dart';
import 'package:kickabout/utils/snackbar_helper.dart';
import 'package:kickabout/data/repositories_providers.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/screens/social/feed_screen.dart';
import 'package:kickabout/screens/social/hub_chat_screen.dart';
import 'package:kickabout/data/users_repository.dart';
import 'package:kickabout/screens/hub/add_manual_player_dialog.dart';
import 'package:kickabout/screens/hub/manage_roles_screen.dart';
import 'package:kickabout/screens/hub/hub_events_tab.dart';
import 'package:kickabout/models/hub_role.dart';

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
    // ConsumerState provides 'ref' automatically
    final currentUserId = ref.watch(currentUserIdProvider);
    final hubsRepo = ref.watch(hubsRepositoryProvider);
    final usersRepo = ref.watch(usersRepositoryProvider);

    final hubStream = hubsRepo.watchHub(widget.hubId);

    return StreamBuilder<Hub?>(
      stream: hubStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppScaffold(
            title: 'פרטי Hub',
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return AppScaffold(
            title: 'פרטי Hub',
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('שגיאה: ${snapshot.error}'),
                ],
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
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${hub.memberIds.length} חברים',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
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
                        ElevatedButton.icon(
                          icon: const Icon(Icons.search),
                          label: const Text('גיוס שחקנים (AI)'),
                          onPressed: () => context.push('/hubs/${hub.hubId}/scouting'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
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
                    // Members tab
                    _MembersTab(hubId: widget.hubId, hub: hub, usersRepo: usersRepo),
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
class _GamesTab extends ConsumerWidget {
  final String hubId;

  const _GamesTab({required this.hubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesRepo = ref.watch(gamesRepositoryProvider);
    final gamesStream = gamesRepo.watchGamesByHub(hubId);

    return StreamBuilder<List<Game>>(
      stream: gamesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final games = snapshot.data ?? [];

        if (games.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('אין משחקים עדיין'),
              ],
            ),
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

  const _MembersTab({
    required this.hubId,
    required this.hub,
    required this.usersRepo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final isHubManager = currentUserId == hub.createdBy;

    return Column(
      children: [
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
        // Members list
        Expanded(
          child: hub.memberIds.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('אין חברים'),
                  ),
                )
              : _buildMembersList(context, ref),
        ),
      ],
    );
  }

  Widget _buildMembersList(BuildContext context, WidgetRef ref) {

    return FutureBuilder<List<User>>(
      future: usersRepo.getUsers(hub.memberIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];

        return ListView.builder(
          itemCount: users.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final user = users[index];
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
                  ],
                ),
                trailing: user.uid == hub.createdBy
                    ? Chip(
                        label: const Text('יוצר'),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      )
                    : null,
                onTap: isManualPlayer
                    ? null
                    : () => context.push('/profile/${user.uid}'),
              ),
            );
          },
        );
      },
    );
  }
}
