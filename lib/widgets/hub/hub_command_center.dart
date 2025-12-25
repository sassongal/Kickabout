import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/features/hubs/domain/services/hub_permissions_service.dart';
import 'package:kattrick/data/repositories_providers.dart';

/// Hub Command Center - Manager/Moderator controls
///
/// Displays pending join requests badge and quick access buttons for:
/// - Hub settings (managers only)
/// - Role management (managers/moderators)
///
/// ARCHITECTURAL FIX: Now uses repository method instead of direct Firestore access
class HubCommandCenter extends ConsumerWidget {
  final String hubId;
  final Hub hub;
  final HubPermissions hubPermissions;

  const HubCommandCenter({
    super.key,
    required this.hubId,
    required this.hub,
    required this.hubPermissions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hubPermissions.isManager && !hubPermissions.isModerator) {
      return const SizedBox.shrink();
    }

    // Watch pending join requests count from repository (not direct Firestore)
    final hubsRepo = ref.watch(hubsRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pending join requests pill
        StreamBuilder<int>(
          stream: hubsRepo.watchPendingJoinRequestsCount(hubId),
          builder: (context, snapshot) {
            final pendingCount = snapshot.data ?? 0;
            if (!hubPermissions.canManageMembers) {
              return const SizedBox.shrink();
            }
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/hubs/${hub.hubId}/requests'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inbox, size: 18, color: Colors.orange),
                    const SizedBox(width: 6),
                    const Text(
                      'בקשות הצטרפות',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.orange,
                      ),
                    ),
                    if (pendingCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          pendingCount > 9 ? '9+' : '$pendingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Modern buttons for settings and roles
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: hubPermissions.canManageSettings
                    ? () => context.push('/hubs/${hub.hubId}/settings')
                    : null,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('הגדרות'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    context.push('/hubs/${hub.hubId}/manage-roles'),
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('ניהול תפקידים'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
