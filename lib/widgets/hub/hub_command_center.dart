import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/services/hub_permissions_service.dart';
import 'package:kattrick/utils/hub_sharing_utils.dart';

class HubCommandCenter extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (!hubPermissions.isManager && !hubPermissions.isModerator) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Row 1: Top Actions (Manager Mode Toggle + IconButtons)
        Row(
          children: [
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Requests badge (Manager only)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('hubs')
                        .doc(hubId)
                        .collection('requests')
                        .where('status', isEqualTo: 'pending')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final pendingCount = snapshot.data?.docs.length ?? 0;
                      return Stack(
                        children: [
                          if (hubPermissions.canManageMembers)
                            IconButton(
                              icon: const Icon(Icons.inbox, size: 20),
                              tooltip: 'בקשות הצטרפות',
                              onPressed: () =>
                                  context.push('/hubs/${hub.hubId}/requests'),
                              color: Colors.orange,
                            ),
                          if (pendingCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  pendingCount > 9 ? '9+' : '$pendingCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  if (hubPermissions.canManageMembers)
                    IconButton(
                      icon: const Icon(Icons.gpp_bad, size: 20),
                      tooltip: 'משתמשים מנופים',
                      onPressed: () =>
                          context.push('/hubs/${hub.hubId}/banned'),
                      color: Colors.red,
                    ),
                  IconButton(
                    icon: const Icon(Icons.share, size: 20),
                    tooltip: 'שתף ב-WhatsApp',
                    onPressed: () =>
                        HubSharingUtils.shareHubOnWhatsApp(context, hub),
                    color: Colors.green,
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 20),
                    tooltip: 'סקאוטינג',
                    onPressed: () =>
                        context.push('/hubs/${hub.hubId}/scouting'),
                    color: Colors.blue,
                  ),
                  IconButton(
                    icon: const Icon(Icons.analytics, size: 20),
                    tooltip: 'ניתוח',
                    onPressed: () =>
                        context.push('/hubs/${hub.hubId}/analytics'),
                    color: Colors.purple,
                  ),
                  if (hubPermissions.canCreatePosts)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.person_search),
                          color: Colors.orange,
                          iconSize: 28,
                          onPressed: () => context.push(
                              '/hubs/${hub.hubId}/create-recruiting-post'),
                          tooltip: 'מחפש שחקנים',
                        ),
                        const Text(
                          'מחפש שחקנים',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Row 2: Management Buttons (Settings & Roles)
        Row(
          children: [
            Expanded(
              child: Opacity(
                opacity: hubPermissions.canManageSettings ? 1.0 : 0.5,
                child: OutlinedButton.icon(
                  onPressed: hubPermissions.canManageSettings
                      ? () => context.push('/hubs/${hub.hubId}/settings')
                      : null,
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('הגדרות'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push('/hubs/${hub.hubId}/manage-roles'),
                icon: const Icon(Icons.admin_panel_settings, size: 18),
                label: const Text('תפקידים'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
