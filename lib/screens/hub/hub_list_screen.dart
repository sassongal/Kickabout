import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/widgets/futuristic/skeleton_loader.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/core/constants.dart';
import 'package:kickadoor/services/error_handler_service.dart';

/// Hub list screen - lists hubs of user
class HubListScreen extends ConsumerStatefulWidget {
  const HubListScreen({super.key});

  @override
  ConsumerState<HubListScreen> createState() => _HubListScreenState();
}

class _HubListScreenState extends ConsumerState<HubListScreen> {

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final hubsRepo = ref.watch(hubsRepositoryProvider);

    if (currentUserId == null) {
      return AppScaffold(
        title: 'הובס',
        body: const Center(
          child: Text('נא להתחבר'),
        ),
      );
    }

    final hubsStream = hubsRepo.watchHubsByMember(currentUserId);

    return AppScaffold(
      title: 'הובס',
      actions: [
        StreamBuilder<int>(
          stream: ref.read(notificationsRepositoryProvider).watchUnreadCount(currentUserId),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Badge(
              label: count > 0 ? Text('$count') : null,
              child: IconButton(
                icon: const Icon(Icons.notifications),
                tooltip: 'התראות',
                onPressed: () => context.push('/notifications'),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.map),
          tooltip: 'מפה',
          onPressed: () => context.push('/map'),
        ),
        IconButton(
          icon: const Icon(Icons.explore),
          tooltip: 'גלה הובים',
          onPressed: () => context.push('/discover'),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'התנתק',
          onPressed: () async {
            final authService = ref.read(authServiceProvider);
            try {
              await authService.signOut();
              if (context.mounted) {
                context.go('/auth');
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('שגיאה בהתנתקות: $e')),
                );
              }
            }
          },
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/hubs/create'),
        icon: const Icon(Icons.add),
        label: const Text('צור הוב'),
      ),
      body: StreamBuilder<List<Hub>>(
        stream: hubsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SkeletonLoader(height: 100),
              ),
            );
          }

          if (snapshot.hasError) {
            return FuturisticEmptyState(
              icon: Icons.error_outline,
              title: 'שגיאה בטעינת הובים',
              message: ErrorHandlerService().handleException(
                snapshot.error,
                context: 'Hub list screen',
              ),
              action: ElevatedButton.icon(
                onPressed: () {
                  // Retry by rebuilding
                  setState(() {});
                },
                icon: const Icon(Icons.refresh),
                label: const Text('נסה שוב'),
              ),
            );
          }

          final hubs = snapshot.data ?? [];

          if (hubs.isEmpty) {
            return FuturisticEmptyState(
              icon: Icons.group_outlined,
              title: 'אין הובס',
              message: 'צור הוב חדש כדי להתחיל',
              action: ElevatedButton.icon(
                onPressed: () => context.push('/hubs/create'),
                icon: const Icon(Icons.add),
                label: const Text('צור הוב'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: hubs.length,
            itemBuilder: (context, index) {
              final hub = hubs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.group,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    hub.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hub.description != null && hub.description!.isNotEmpty)
                        Text(
                          hub.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${hub.memberIds.length} חברים',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => context.push('/hubs/${hub.hubId}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
