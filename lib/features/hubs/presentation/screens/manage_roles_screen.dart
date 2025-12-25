import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:kattrick/widgets/common/premium_scaffold.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/models/hub_role.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/widgets/player_avatar.dart';

/// Screen for managing hub roles (managers only)
class ManageRolesScreen extends ConsumerStatefulWidget {
  final String hubId;

  const ManageRolesScreen({
    super.key,
    required this.hubId,
  });

  @override
  ConsumerState<ManageRolesScreen> createState() => _ManageRolesScreenState();
}

class _ManageRolesScreenState extends ConsumerState<ManageRolesScreen> {
  @override
  Widget build(BuildContext context) {
    final hubsRepo = ref.watch(hubsRepositoryProvider);
    final usersRepo = ref.watch(usersRepositoryProvider);
    final hubStream = hubsRepo.watchHub(widget.hubId);

    return PremiumScaffold(
      title: 'ניהול תפקידים',
      body: StreamBuilder<Hub?>(
        stream: hubStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final hub = snapshot.data;
          if (hub == null) {
            return const Center(child: Text('הוב לא נמצא'));
          }

          if (hub.memberCount == 0) {
            return const Center(child: Text('אין חברים בהוב'));
          }

          return FutureBuilder<Map<String, dynamic>>(
            future: () async {
              // 1. Fetch all active members
              final members = await hubsRepo.getHubMembers(hub.hubId);

              // 2. Extract user IDs
              final memberIds = members.map((m) => m.userId).toList();

              // 3. Fetch user details
              final users = await usersRepo.getUsers(memberIds);

              // 4. Create a map of userId -> role
              final rolesMap = {for (var m in members) m.userId: m.role};

              return {
                'users': users,
                'roles': rolesMap,
              };
            }(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                    child: Text('שגיאה בטעינת נתונים: ${snapshot.error}'));
              }

              final data = snapshot.data;
              final users = (data?['users'] as List<User>?) ?? [];
              final rolesMap = (data?['roles'] as Map<String, String>?) ?? {};

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isCreator = user.uid == hub.createdBy;
                  final currentRole = isCreator
                      ? HubRole.manager
                      : HubRole.fromFirestore(rolesMap[user.uid] ?? 'member');

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: PlayerAvatar(user: user, radius: 24),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isCreator)
                            DropdownButton<HubRole>(
                              value: currentRole,
                              items: HubRole.values.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Text(role.displayName),
                                );
                              }).toList(),
                              onChanged: (newRole) async {
                                if (newRole == null) return;

                                try {
                                  final currentUserId = auth.FirebaseAuth
                                          .instance.currentUser?.uid ??
                                      '';
                                  await hubsRepo.updateMemberRole(
                                    widget.hubId,
                                    user.uid,
                                    newRole.firestoreValue,
                                    currentUserId,
                                  );

                                  if (!context.mounted) return;
                                  SnackbarHelper.showSuccess(
                                    context,
                                    'תפקיד עודכן בהצלחה',
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  SnackbarHelper.showErrorFromException(
                                      context, e);
                                }
                              },
                            )
                          else
                            Chip(
                              label: const Text('יוצר'),
                              backgroundColor: Colors.blue,
                            ),
                          if (!isCreator) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('מחיקת משתמש'),
                                    content: Text(
                                        'האם אתה בטוח שברצונך להסיר את ${user.name} מההאב?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('ביטול'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('הסר'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  try {
                                    await hubsRepo.removeMember(
                                        widget.hubId, user.uid);
                                    if (!context.mounted) return;
                                    SnackbarHelper.showSuccess(
                                      context,
                                      'משתמש הוסר בהצלחה',
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    SnackbarHelper.showErrorFromException(
                                        context, e);
                                  }
                                }
                              },
                              tooltip: 'הסר משתמש מההאב',
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
