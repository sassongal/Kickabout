import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickabout/widgets/app_scaffold.dart';
import 'package:kickabout/utils/snackbar_helper.dart';
import 'package:kickabout/data/repositories_providers.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/core/constants.dart';
import 'package:kickabout/screens/social/feed_screen.dart';
import 'package:kickabout/screens/social/hub_chat_screen.dart';
import 'package:kickabout/screens/game/game_list_screen.dart';
import 'package:kickabout/data/users_repository.dart';

/// Hub detail screen
class HubDetailScreen extends ConsumerStatefulWidget {
  final String hubId;

  const HubDetailScreen({super.key, required this.hubId});

  @override
  ConsumerState<HubDetailScreen> createState() => _HubDetailScreenState();
}

class _HubDetailScreenState extends ConsumerState<HubDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _currentTab = _tabController.index;
        });
      }
    });
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
            title: 'פרטי הוב',
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return AppScaffold(
            title: 'פרטי הוב',
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
            title: 'פרטי הוב',
            body: const Center(child: Text('הוב לא נמצא')),
          );
        }

        final isMember = currentUserId != null && hub.memberIds.contains(currentUserId);
        final isHubManager = currentUserId == hub.createdBy;

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
                                onPressed: () => _editHubSettings(context, ref, hub),
                                icon: const Icon(Icons.settings, size: 18),
                                label: const Text('הגדרות'),
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
                      ] else if (currentUserId != null) ...[
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _toggleMembership(context, ref, hub, isMember),
                          icon: Icon(isMember ? Icons.exit_to_app : Icons.person_add),
                          label: Text(isMember ? 'עזוב הוב' : 'הצטרף להוב'),
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
            const SnackBar(content: Text('עזבת את ההוב')),
          );
        }
      } else {
        await hubsRepo.addMember(widget.hubId, currentUserId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('הצטרפת להוב')),
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

  Future<void> _editHubSettings(
    BuildContext context,
    WidgetRef ref,
    Hub hub,
  ) async {
    final currentRatingMode = hub.settings['ratingMode'] as String? ?? 'basic';

    final newRatingMode = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ערוך הגדרות הוב'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('בחר מצב דירוג:'),
            const SizedBox(height: 16),
            RadioListTile<String>(
              title: const Text('דירוג בסיסי (1-7)'),
              subtitle: const Text('ציון יחיד לכל שחקן'),
              value: 'basic',
              groupValue: currentRatingMode,
              onChanged: (value) => Navigator.of(context).pop(value),
            ),
            RadioListTile<String>(
              title: const Text('דירוג מתקדם (1-10)'),
              subtitle: const Text('8 קטגוריות דירוג'),
              value: 'advanced',
              groupValue: currentRatingMode,
              onChanged: (value) => Navigator.of(context).pop(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );

    if (newRatingMode != null && newRatingMode != currentRatingMode) {
      try {
        final hubsRepo = ref.read(hubsRepositoryProvider);
        await hubsRepo.updateHub(hub.hubId, {
          'settings': {
            ...hub.settings,
            'ratingMode': newRatingMode,
          },
        });

        if (context.mounted) {
          SnackbarHelper.showSuccess(context, 'ההגדרות עודכנו בהצלחה');
        }
      } catch (e) {
        if (context.mounted) {
          SnackbarHelper.showErrorFromException(context, e);
        }
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
    if (hub.memberIds.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('אין חברים'),
        ),
      );
    }

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
                title: Text(user.name),
                subtitle: Text(user.email),
                trailing: user.uid == hub.createdBy
                    ? Chip(
                        label: const Text('יוצר'),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      )
                    : null,
                onTap: () => context.push('/profile/${user.uid}'),
              ),
            );
          },
        );
      },
    );
  }
}
