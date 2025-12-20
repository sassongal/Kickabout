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
import 'package:kattrick/widgets/hub/hub_city_selector.dart';
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
        // Premium Hub Banner
        Stack(
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                image: hub.bannerUrl != null
                    ? DecorationImage(
                        image: NetworkImage(hub.bannerUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: hub.bannerUrl == null
                  ? Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.3),
                      ),
                    )
                  : null,
            ),
            // Gradient Overlay for readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
            // Hub Profile Image (Overlapping)
            Positioned(
              left: 16,
              bottom: 16,
              child: Hero(
                tag: 'hub_avatar_${hub.hubId}',
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: hub.profileImageUrl != null
                        ? NetworkImage(hub.profileImageUrl!)
                        : null,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: hub.profileImageUrl == null
                        ? const Icon(Icons.group, size: 40, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ),
            // Hub Name & Summary (Overlapping)
            Positioned(
              left: 110,
              bottom: 24,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hub.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  if (hub.region != null)
                    Text(
                      hub.region!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        // Hub info card (compact)
        Transform.translate(
          offset: const Offset(0, -10),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User role badge & Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (currentUserId != null)
                        Builder(
                          builder: (context) {
                            final permissions = hubPermissions ??
                                HubPermissions(hub: hub, userId: currentUserId);
                            final role = permissions.userRole;
                            final roleName = role.displayName;

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

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(roleIcon,
                                      size: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer),
                                  const SizedBox(width: 6),
                                  Text(
                                    roleName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      Text(
                        'נוצר: ${DateFormat('dd/MM/yyyy', 'he').format(hub.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Member count
                  Row(
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${hub.memberCount} משתתפים פעילים',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  if (hub.description != null &&
                      hub.description!.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(),
                    ),
                    Text(
                      hub.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Command Center
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
                    const SizedBox(height: 12),
                    // City and Home Venue in one row
                    Row(
                      children: [
                        Expanded(
                          child: HubCitySelector(
                            hubId: hubId,
                            hub: hub,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: HubHomeVenueSelector(
                            hubId: hubId,
                            venuesRepo: venuesRepo,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
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
