import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/features/hubs/domain/models/hub_role.dart';
import 'package:kattrick/features/hubs/domain/models/hub.dart';
import 'package:kattrick/core/providers/complex_providers.dart';
import 'package:kattrick/widgets/common/home_logo_button.dart';

/// Custom Permissions Management Screen
/// Allows managers to grant special permissions to specific users
class CustomPermissionsScreen extends ConsumerStatefulWidget {
  final String hubId;

  const CustomPermissionsScreen({
    super.key,
    required this.hubId,
  });

  @override
  ConsumerState<CustomPermissionsScreen> createState() =>
      _CustomPermissionsScreenState();
}

class _CustomPermissionsScreenState
    extends ConsumerState<CustomPermissionsScreen> {
  // Available permission types
  static const Map<String, String> permissionTypes = {
    'canCreateEvents': 'Create Events',
    'canCreatePosts': 'Create Posts',
    'canRecordResults': 'Record Game Results',
    'canInvitePlayers': 'Invite Players',
    'canViewAnalytics': 'View Analytics',
    'canModerateChat': 'Moderate Chat',
  };

  @override
  Widget build(BuildContext context) {
    // Check admin permissions
    final roleAsync = ref.watch(hubRoleProvider(widget.hubId));
    final canPop = Navigator.of(context).canPop();

    return roleAsync.when(
      data: (role) {
        if (role != UserRole.admin) {
          return Scaffold(
            appBar: AppBar(
              leadingWidth: AppBarHomeLogo.leadingWidth(showBackButton: canPop),
              leading: AppBarHomeLogo(showBackButton: canPop),
              title: const Text('Custom Permissions'),
              elevation: 0,
              automaticallyImplyLeading: false,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Access Denied',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Only hub admins can manage custom permissions',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final hubAsync = ref.watch(hubStreamProvider(widget.hubId));

        return hubAsync.when(
          data: (hub) {
            if (hub == null) {
              return Scaffold(
                appBar: AppBar(
                  leadingWidth: AppBarHomeLogo.leadingWidth(showBackButton: canPop),
                  leading: AppBarHomeLogo(showBackButton: canPop),
                  title: const Text('Custom Permissions'),
                  elevation: 0,
                  automaticallyImplyLeading: false,
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Hub not found'),
                    ],
                  ),
                ),
              );
            }
            return _buildContent(context, hub, canPop);
          },
          loading: () => Scaffold(
            appBar: AppBar(
              leadingWidth: AppBarHomeLogo.leadingWidth(showBackButton: canPop),
              leading: AppBarHomeLogo(showBackButton: canPop),
              title: const Text('Custom Permissions'),
              elevation: 0,
              automaticallyImplyLeading: false,
            ),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Scaffold(
            appBar: AppBar(
              leadingWidth: AppBarHomeLogo.leadingWidth(showBackButton: canPop),
              leading: AppBarHomeLogo(showBackButton: canPop),
              title: const Text('Custom Permissions'),
              elevation: 0,
              automaticallyImplyLeading: false,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Error loading hub: $error'),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarHomeLogo.leadingWidth(showBackButton: canPop),
          leading: AppBarHomeLogo(showBackButton: canPop),
          title: const Text('Custom Permissions'),
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarHomeLogo.leadingWidth(showBackButton: canPop),
          leading: AppBarHomeLogo(showBackButton: canPop),
          title: const Text('Custom Permissions'),
          automaticallyImplyLeading: false,
        ),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Hub hub, bool canPop) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBarHomeLogo.leadingWidth(showBackButton: canPop),
        leading: AppBarHomeLogo(showBackButton: canPop),
        title: const Text('Custom Permissions'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'About Custom Permissions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Grant specific permissions to individual users without changing their role. '
                    'Use sparingly - most users should get permissions from their role.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Permission types
          ...permissionTypes.entries.map((entry) {
            final permissionKey = entry.key;
            final permissionName = entry.value;
            final userIds = (hub.permissions[permissionKey]
                        as List<dynamic>?)
                    ?.cast<String>() ??
                [];

            return _PermissionCard(
              hubId: widget.hubId,
              permissionKey: permissionKey,
              permissionName: permissionName,
              userCount: userIds.length,
            );
          }),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final String hubId;
  final String permissionKey;
  final String permissionName;
  final int userCount;

  const _PermissionCard({
    required this.hubId,
    required this.permissionKey,
    required this.permissionName,
    required this.userCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          permissionName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$userCount user(s) with custom permission'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () => _showAddUserDialog(context),
              tooltip: 'Add User',
            ),
            IconButton(
              icon: const Icon(Icons.manage_accounts),
              onPressed: () => _showManageUsersDialog(context),
              tooltip: 'Manage Users',
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feature in development - User management coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showManageUsersDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feature in development - User management coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
