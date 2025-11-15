import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/models/hub_role.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/widgets/player_avatar.dart';

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

    return FuturisticScaffold(
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

          if (hub.memberIds.isEmpty) {
            return const Center(child: Text('אין חברים בהוב'));
          }

          return FutureBuilder<List<User>>(
            future: usersRepo.getUsers(hub.memberIds),
            builder: (context, usersSnapshot) {
              if (usersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = usersSnapshot.data ?? [];
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isCreator = user.uid == hub.createdBy;
                  final currentRole = isCreator 
                      ? HubRole.manager 
                      : HubRole.fromFirestore(hub.roles[user.uid] ?? 'member');
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: PlayerAvatar(user: user, radius: 24),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      trailing: isCreator
                          ? Chip(
                              label: const Text('יוצר'),
                              backgroundColor: Colors.blue,
                            )
                          : DropdownButton<HubRole>(
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
                                  await hubsRepo.updateMemberRole(
                                    widget.hubId,
                                    user.uid,
                                    newRole.firestoreValue,
                                  );
                                  
                                  if (!context.mounted) return;
                                  SnackbarHelper.showSuccess(
                                    context,
                                    'תפקיד עודכן בהצלחה',
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  SnackbarHelper.showErrorFromException(context, e);
                                }
                              },
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

