import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/core/providers/repositories_providers.dart';
import 'package:kattrick/core/providers/complex_providers.dart';
import 'package:kattrick/core/providers/auth_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:go_router/go_router.dart';

/// Screen for managing hub roles - Only accessible to Hub Creator (Admin)
/// Allows toggling Manager and Moderator roles for members
class HubRolesScreen extends ConsumerStatefulWidget {
  final String hubId;

  const HubRolesScreen({
    super.key,
    required this.hubId,
  });

  @override
  ConsumerState<HubRolesScreen> createState() => _HubRolesScreenState();
}

class _HubRolesScreenState extends ConsumerState<HubRolesScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hubAsync = ref.watch(hubStreamProvider(widget.hubId));

    return hubAsync.when(
      data: (hub) {
        if (hub == null) {
          return AppScaffold(
            title: 'ניהול תפקידים',
            body: const Center(child: Text('הוב לא נמצא')),
          );
        }
        return _buildContent(context, hub);
      },
      loading: () => AppScaffold(
        title: 'ניהול תפקידים',
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => AppScaffold(
        title: 'ניהול תפקידים',
        body: const Center(child: Text('שגיאה בטעינת הנתונים')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Hub hub) {
    final hubsRepo = ref.watch(hubsRepositoryProvider);
    final usersRepo = ref.watch(usersRepositoryProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    // Check if current user is the creator (super-admin)
    final isCreator = currentUserId != null && currentUserId == hub.createdBy;
    if (!isCreator) {
      return AppScaffold(
        title: 'ניהול תפקידים',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'גישה מוגבלת',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('רק יוצר ההאב יכול לנהל תפקידים'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('חזור'),
              ),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'ניהול תפקידים',
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'חפש חבר...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // Members list
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: () async {
                // 1. Fetch all active members
                final members = await hubsRepo.getHubMembers(widget.hubId);

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
                    child: Text('שגיאה בטעינת נתונים: ${snapshot.error}'),
                  );
                }

                final data = snapshot.data;
                final users = (data?['users'] as List<User>?) ?? [];
                final rolesMap = (data?['roles'] as Map<String, HubMemberRole>?) ?? {};

                // Filter by search query
                final filteredUsers = users.where((user) {
                  if (_searchQuery.isEmpty) return true;
                  return user.name.toLowerCase().contains(_searchQuery) ||
                      user.email.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'אין חברים בהוב'
                              : 'לא נמצאו תוצאות',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final isCreator = user.uid == hub.createdBy;
                    final currentRole = isCreator
                        ? HubMemberRole.manager
                        : (rolesMap[user.uid] ?? HubMemberRole.member);

                    final isManager = currentRole == HubMemberRole.manager;
                    final isModerator = currentRole == HubMemberRole.moderator;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: PlayerAvatar(user: user, radius: 28),
                        title: Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (user.email.isNotEmpty)
                              Text(
                                user.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            const SizedBox(height: 4),
                            if (isCreator)
                              Chip(
                                label: const Text('יוצר ההאב'),
                                backgroundColor: Colors.blue[100],
                                labelStyle: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                          ],
                        ),
                        trailing: isCreator
                            ? const Chip(
                                label: Text('מנהל'),
                                backgroundColor: Colors.blue,
                                labelStyle: TextStyle(color: Colors.white),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Manager toggle
                                  SwitchListTile(
                                    title: const Text(
                                      'מנהל',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    value: isManager,
                                    onChanged: (value) async {
                                      await _toggleRole(
                                        user,
                                        value
                                            ? HubMemberRole.manager
                                            : HubMemberRole.member,
                                      );
                                    },
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                  ),
                                  // Moderator toggle
                                  SwitchListTile(
                                    title: const Text(
                                      'מודרייטור',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    value: isModerator,
                                    onChanged: (value) async {
                                      await _toggleRole(
                                        user,
                                        value
                                            ? HubMemberRole.moderator
                                            : HubMemberRole.member,
                                      );
                                    },
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleRole(User user, HubMemberRole newRole) async {
    try {
      final currentUserId = auth.FirebaseAuth.instance.currentUser?.uid ?? '';
      final hubsRepo = ref.read(hubsRepositoryProvider);

      await hubsRepo.updateMemberRole(
        widget.hubId,
        user.uid,
        newRole.firestoreValue,
        currentUserId,
      );

      if (!mounted) return;
      SnackbarHelper.showSuccess(
        context,
        'תפקיד ${user.name} עודכן ל-${newRole.displayName}',
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showErrorFromException(context, e);
    }
  }
}

