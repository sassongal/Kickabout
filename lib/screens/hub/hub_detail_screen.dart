import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickabout/widgets/app_scaffold.dart';
import 'package:kickabout/utils/snackbar_helper.dart';
import 'package:kickabout/data/repositories_providers.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/core/constants.dart';

/// Hub detail screen
class HubDetailScreen extends ConsumerWidget {
  final String hubId;

  const HubDetailScreen({super.key, required this.hubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final hubsRepo = ref.watch(hubsRepositoryProvider);
    final usersRepo = ref.watch(usersRepositoryProvider);

    final hubStream = hubsRepo.watchHub(hubId);

    return AppScaffold(
      title: 'פרטי הוב',
      body: StreamBuilder<Hub?>(
        stream: hubStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('שגיאה: ${snapshot.error}'),
                ],
              ),
            );
          }

          final hub = snapshot.data;
          if (hub == null) {
            return const Center(child: Text('הוב לא נמצא'));
          }

          final isMember = currentUserId != null && hub.memberIds.contains(currentUserId);
          final isHubManager = currentUserId == hub.createdBy;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hub info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hub.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (hub.description != null && hub.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            hub.description!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 16),
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
                        Row(
                          children: [
                            Icon(
                              Icons.settings,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'מצב דירוג: ${hub.settings['ratingMode'] == 'advanced' ? 'מתקדם (1-10)' : 'בסיסי (1-7)'}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Hub manager actions
                if (isHubManager) ...[
                  ElevatedButton.icon(
                    onPressed: () => _editHubSettings(context, ref, hub),
                    icon: const Icon(Icons.settings),
                    label: const Text('ערוך הגדרות'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/games/create?hubId=${hub.hubId}'),
                    icon: const Icon(Icons.add),
                    label: const Text('צור מחזור חדש'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Join/Leave button
                if (currentUserId != null && !isHubManager)
                  ElevatedButton.icon(
                    onPressed: () => _toggleMembership(context, ref, hub, isMember),
                    icon: Icon(isMember ? Icons.exit_to_app : Icons.person_add),
                    label: Text(isMember ? 'עזוב הוב' : 'הצטרף להוב'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isMember
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                      foregroundColor: isMember
                          ? Theme.of(context).colorScheme.onError
                          : Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                if (currentUserId != null && !isHubManager) const SizedBox(height: 24),

                // Members section
                Text(
                  'חברים',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Members list
                if (hub.memberIds.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('אין חברים'),
                    ),
                  )
                else
                  FutureBuilder<List<User>>(
                    future: usersRepo.getUsers(hub.memberIds),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final users = snapshot.data ?? [];

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return ListTile(
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
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
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
        await hubsRepo.removeMember(hubId, currentUserId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('עזבת את ההוב')),
          );
        }
      } else {
        await hubsRepo.addMember(hubId, currentUserId);
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
