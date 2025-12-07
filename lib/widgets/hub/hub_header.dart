import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/models/hub_role.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/services/analytics_service.dart';
import 'package:kattrick/services/hub_permissions_service.dart';
import 'package:kattrick/utils/hub_sharing_utils.dart';
import 'package:kattrick/widgets/hub/hub_command_center.dart';
import 'package:kattrick/widgets/hub/hub_home_venue_selector.dart';
import 'package:kattrick/widgets/hub/hub_venues_list.dart';

class HubHeader extends ConsumerWidget {
  final String hubId;
  final Hub hub;
  final HubPermissions? hubPermissions;
  final bool isMember;
  final bool isAdminRole; // Based on HubRole enum (legacy/simplified check)

  const HubHeader({
    super.key,
    required this.hubId,
    required this.hub,
    required this.hubPermissions,
    required this.isMember,
    required this.isAdminRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final venuesRepo = ref.read(venuesRepositoryProvider);

    return Column(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(
                        builder: (context) {
                          // Use passed permissions or create new if null (shouldn't happen for logged in)
                          final permissions = hubPermissions ??
                              HubPermissions(hub: hub, userId: currentUserId);
                          final role = permissions.userRole;
                          final roleName = role.displayName;

                          // Set icon based on actual role
                          IconData roleIcon = Icons.person_outline;
                          switch (role) {
                            case HubRole.manager:
                              roleIcon = Icons.admin_panel_settings;
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
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Command Center - Compact Header (for managers/moderators)
                if (hubPermissions != null)
                  HubCommandCenter(
                    hubId: hubId,
                    hub: hub,
                    hubPermissions: hubPermissions!,
                  ),

                if (hubPermissions != null &&
                        (hubPermissions!.isManager ||
                            hubPermissions!.isModerator) ||
                    isAdminRole) ...[
                  const SizedBox(height: 8),
                  // Row 3: Home Venue (Only for authorized)
                  // Actually in original code it was inside the if(manager/moderator) block
                  HubHomeVenueSelector(
                    hubId: hubId,
                    venuesRepo: venuesRepo,
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
        // Venues list (compact) - outside Card
        HubVenuesList(hubId: hubId, venuesRepo: venuesRepo),

        // Regular member actions
        if (!isAdminRole && currentUserId != null && isMember) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _toggleMembership(context, ref, hub, isMember),
            icon: const Icon(Icons.exit_to_app, size: 18),
            label: const Text('עזוב Hub'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ],

        // Hub Members button (compact)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ElevatedButton.icon(
            onPressed: () => context.push('/hubs/${hub.hubId}/players'),
            icon: const Icon(Icons.groups_3, size: 20),
            label: Text(
              'חברי ההאב (${hub.memberCount})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),

        // Share and Rules buttons (compact)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // Share on WhatsApp button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      HubSharingUtils.shareHubOnWhatsApp(context, hub),
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('שתף'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              // Rules button (if rules exist)
              if (hub.hubRules != null && hub.hubRules!.isNotEmpty) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => context.push('/hubs/${hub.hubId}/rules'),
                  icon: const Icon(Icons.rule, size: 16),
                  label: const Text('חוקים'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
        await hubsRepo.removeMember(hub.hubId, currentUserId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('עזבת את ה-Hub')),
          );
        }
      } else {
        await hubsRepo.addMember(hub.hubId, currentUserId);

        // Log analytics
        try {
          final analytics = AnalyticsService();
          await analytics.logHubJoined(hubId: hub.hubId);
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
