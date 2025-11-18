import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
import 'package:kickadoor/services/error_handler_service.dart';
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

        final isMember = currentUserId != null && hub.memberIds.contains(currentUserId);
        final hubPermissions = currentUserId != null
            ? HubPermissions(hub: hub, userId: currentUserId)
            : null;
        final isHubManager = hubPermissions?.isManager() ?? (currentUserId == hub.createdBy);
        
        // Check if join requests are enabled
        final joinRequestsEnabled = hub.settings['joinRequestsEnabled'] as bool? ?? true;

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

        // Check user role for admin permissions
        final roleAsync = ref.watch(hubRoleProvider(widget.hubId));
        final isAdmin = roleAsync.valueOrNull == UserRole.admin;
        // isHubManager is already defined above (line 107)

        return roleAsync.when(
          data: (role) {
            final isAdminRole = role == UserRole.admin;
            return AppScaffold(
              title: hub.name,
              floatingActionButton: isAdminRole
                  ? FloatingActionButton.extended(
                      onPressed: () => context.push('/games/create?hubId=${widget.hubId}'),
                      icon: const Icon(Icons.add),
                      label: const Text('צור משחק'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    )
                  : null,
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
                      // User role badge (top left)
                      if (currentUserId != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Builder(
                              builder: (context) {
                                final hubPermissions = HubPermissions(hub: hub, userId: currentUserId);
                                final roleName = hubPermissions.getRoleDisplayName();
                                return Chip(
                                  label: Text(roleName),
                                  avatar: Icon(
                                    roleName == 'מנהל' 
                                      ? Icons.admin_panel_settings
                                      : roleName == 'מנחה'
                                        ? Icons.shield
                                        : Icons.person,
                                    size: 18,
                                  ),
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Hub creation date (centered at top)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'האב נוצר ב- ${DateFormat('dd/MM/yyyy', 'he').format(hub.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                      // Hub profile image
                      if (hub.profileImageUrl != null) ...[
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              hub.profileImageUrl ?? '',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.group, size: 60),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (hub.description != null && hub.description!.isNotEmpty) ...[
                        Text(
                          hub.description ?? '',
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
                            '${hub.memberIds.length} משתתפים',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Venues list
                      _VenuesList(hubId: widget.hubId, venuesRepo: venuesRepo),
                      const SizedBox(height: 8),
                      // Actions
                      if (isAdminRole) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.push('/hubs/${hub.hubId}/settings'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  minimumSize: const Size(0, 40),
                                ),
                                child: const Text(
                                  'הגדרות',
                                  style: TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.push('/hubs/${hub.hubId}/manage-roles'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  minimumSize: const Size(0, 40),
                            ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'ניהול',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'תפקידים',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => context.push('/hubs/${hub.hubId}/scouting'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  minimumSize: const Size(0, 40),
                                ),
                                child: const Text(
                                  'גיוס שחקנים (AI)',
                                  style: TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('בקרוב'),
                                      duration: Duration(seconds: 2),
                                  ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  minimumSize: const Size(0, 40),
                                ),
                                child: const Text(
                                  'אנליטיקס',
                                  style: TextStyle(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => context.push('/hubs/${hub.hubId}/log-past-game'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            minimumSize: const Size(0, 40),
                          ),
                          child: const Text(
                            'תיעוד משחק עבר',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ] else if (currentUserId != null && isMember) ...[
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _toggleMembership(context, ref, hub, isMember),
                          icon: const Icon(Icons.exit_to_app),
                          label: const Text('עזוב Hub'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                            foregroundColor: Theme.of(context).colorScheme.onError,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Rules button (if rules exist)
              if (hub.hubRules != null && hub.hubRules!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/hubs/${hub.hubId}/rules'),
                    icon: const Icon(Icons.rule, size: 18),
                    label: const Text('חוקי ההאב'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
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
                      isManager: isAdminRole,
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
            ? ref.watch(hubPermissionsProvider((hubId: widget.hubId, userId: currentUserId)))
            : null;
        final hubPermissions = hubPermissionsAsync?.valueOrNull;
        final canCreateGames = hubPermissions?.canCreateGames() ?? false;

        return Column(
          children: [
            // Add game log button (for authorized users)
            if (canCreateGames)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/hubs/${widget.hubId}/log-past-game'),
                  icon: const Icon(Icons.add),
                  label: const Text('תיעוד משחק'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        final canEdit = currentUserId == game.createdBy || canCreateGames;
                        
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                            leading: Icon(
                              isCompleted ? Icons.check_circle : Icons.sports_soccer,
                              color: isCompleted ? Colors.green : null,
                            ),
                            title: Text(
                              '${game.gameDate.day}/${game.gameDate.month}/${game.gameDate.year} ${game.gameDate.hour}:${game.gameDate.minute.toString().padLeft(2, '0')}',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (game.teamAScore != null && game.teamBScore != null)
                                  Text('תוצאה: ${game.teamAScore} - ${game.teamBScore}'),
                                if (game.eventId != null)
                                  Text('אירוע: ${game.eventId}', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (canEdit)
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => context.push('/hubs/${widget.hubId}/games/${game.gameId}/edit'),
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
    final roleAsync = ref.watch(hubRoleProvider(hubId));
    final isAdmin = roleAsync.valueOrNull == UserRole.admin;
    
    // Check if user is manager/admin (creator or has admin role)
    final isManagerOrAdmin = isHubManager || isAdmin;

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
        // Add manual player button (for managers/admins)
        if (isManagerOrAdmin)
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
    final roleAsync = ref.watch(hubRoleProvider(hubId));
    final isAdmin = roleAsync.valueOrNull == UserRole.admin;
    final isManagerOrAdmin = isHubManager || isAdmin;

    // Debug: Log memberIds to help diagnose issues
    debugPrint('🔍 Members Tab - hub.memberIds: ${hub.memberIds}');
    debugPrint('🔍 Members Tab - memberIds.length: ${hub.memberIds.length}');

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

        final users = snapshot.data ?? [];
        
        // Debug: Log users found
        debugPrint('🔍 Members Tab - users found: ${users.length}');
        if (users.isEmpty && hub.memberIds.isNotEmpty) {
          // If memberIds exist but no users found, show error with more info
          debugPrint('⚠️ Members Tab - memberIds exist but no users found. memberIds: ${hub.memberIds}');
          return FuturisticEmptyState(
            icon: Icons.error_outline,
            title: 'שגיאה בטעינת חברים',
            message: 'נמצאו ${hub.memberIds.length} חברים ברשימה, אך לא ניתן לטעון את הפרטים שלהם',
            action: ElevatedButton.icon(
              onPressed: () {
                // Force rebuild by invalidating provider
                ref.invalidate(hubRoleProvider(hubId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('נסה שוב'),
            ),
          );
        }
        
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
            
            // Split name into first and last name
            final nameParts = user.name.split(' ');
            final firstName = nameParts.isNotEmpty ? nameParts.first : user.name;
            final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                        )
                      : null,
                ),
                title: Text(
                  firstName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                      ),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
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
                              hubId: hubId,
                            ),
                          );
                          if (result == true && context.mounted) {
                            // Refresh will happen automatically via StreamBuilder
                          }
                        },
                        tooltip: 'ערוך שחקן',
                      ),
                    // Show role badge - prioritize admin/manager, then creator
                    if (hub.roles[user.uid] == 'admin' || hub.roles[user.uid] == 'manager' || user.uid == hub.createdBy)
                      Chip(
                        label: const Text('מנהל'),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        avatar: Icon(
                          Icons.admin_panel_settings,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
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
                            venue.address ?? '',
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

  Future<void> _sendJoinRequest() async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא להתחבר')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      
      // For now, we'll add them directly (in production, you'd create a join request)
      // TODO: Implement proper join request system
      await hubsRepo.addMember(widget.hubId, currentUserId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הבקשה להצטרפות נשלחה')),
        );
        // Refresh the screen
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hub profile image
          Center(
            child: widget.hub.profileImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.hub.profileImageUrl ?? '',
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.group, size: 80),
                      ),
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
                    '${widget.hub.memberIds.length} משתתפים',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Description
          if (widget.hub.description != null && widget.hub.description!.isNotEmpty) ...[
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        venue.name,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (venue.address != null && venue.address!.isNotEmpty)
                                        Text(
                                          venue.address ?? '',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: Text(_isSubmitting ? 'שולח...' : 'שלח בקשת הצטרפות'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

/// Rules tab widget - displays hub rules (read-only)
class _RulesTab extends StatelessWidget {
  final Hub hub;

  const _RulesTab({required this.hub});

  @override
  Widget build(BuildContext context) {
    if (hub.hubRules == null || hub.hubRules!.isEmpty) {
      return FuturisticEmptyState(
        icon: Icons.rule,
        title: 'אין חוקים מוגדרים',
        message: 'מנהל ה-Hub עדיין לא הגדיר חוקים',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.rule,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'חוקי האב',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                hub.hubRules ?? '',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
