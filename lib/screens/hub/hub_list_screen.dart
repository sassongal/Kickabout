import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/l10n/app_localizations.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/futuristic/empty_state.dart';
import 'package:kattrick/widgets/futuristic/skeleton_loader.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/core/constants.dart';
import 'package:kattrick/services/error_handler_service.dart';

/// Hub list screen - lists hubs of user
class HubListScreen extends ConsumerStatefulWidget {
  const HubListScreen({super.key});

  @override
  ConsumerState<HubListScreen> createState() => _HubListScreenState();
}

class _HubListScreenState extends ConsumerState<HubListScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = ref.watch(currentUserIdProvider);
    final hubsRepo = ref.watch(hubsRepositoryProvider);

    if (currentUserId == null) {
      return AppScaffold(
        title: l10n.yourHubsTitle,
        body: Center(
          child: Text(l10n.pleaseLogin),
        ),
      );
    }

    final hubsStream = hubsRepo.watchHubsByMember(currentUserId);

    return AppScaffold(
      title: l10n.yourHubsTitle,
      actions: [
        StreamBuilder<int>(
          stream: ref
              .read(notificationsRepositoryProvider)
              .watchUnreadCount(currentUserId),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Badge(
              label: count > 0 ? Text('$count') : null,
              child: IconButton(
                icon: const Icon(Icons.notifications),
                tooltip: l10n.notificationsTooltip,
                onPressed: () => context.push('/notifications'),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.map),
          tooltip: l10n.mapTooltip,
          onPressed: () => context.push('/map'),
        ),
        IconButton(
          icon: const Icon(Icons.explore),
          tooltip: l10n.discoverHubsTooltip,
          onPressed: () => context.push('/discover'),
        ),
        IconButton(
          icon: const Icon(Icons.home),
          tooltip: l10n.backToHomeTooltip,
          onPressed: () => context.go('/'),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/hubs/create'),
        icon: const Icon(Icons.add),
        label: Text(l10n.createHub),
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
              title: l10n.errorLoadingHubs,
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
                label: Text(l10n.tryAgain),
              ),
            );
          }

          final hubs = snapshot.data ?? [];

          if (hubs.isEmpty) {
            return FuturisticEmptyState(
              icon: Icons.group_outlined,
              title: l10n.noHubs,
              message: l10n.createHubToStart,
              action: ElevatedButton.icon(
                onPressed: () => context.push('/hubs/create'),
                icon: const Icon(Icons.add),
                label: Text(l10n.createHub),
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
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
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
                      if (hub.description != null &&
                          hub.description!.isNotEmpty)
                        Text(
                          hub.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.memberCount(hub.memberCount),
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
