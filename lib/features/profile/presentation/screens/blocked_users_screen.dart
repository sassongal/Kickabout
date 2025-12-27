import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/core/constants.dart';

/// Screen for managing blocked users
class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() =>
      _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  bool _isLoading = false;

  Future<void> _unblockUser(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ביטול חסימה'),
        content: const Text('האם אתה בטוח שברצונך לבטל את החסימה?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('אישור'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final currentUserId = ref.read(currentUserIdProvider);
      if (currentUserId == null) {
        SnackbarHelper.showError(context, 'נא להתחבר');
        return;
      }

      final usersRepo = ref.read(usersRepositoryProvider);
      await usersRepo.unblockUser(currentUserId, userId);

      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showSuccess(context, 'החסימה בוטלה');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final usersRepo = ref.read(usersRepositoryProvider);

    if (currentUserId == null) {
      return AppScaffold(
        title: 'משתמשים חסומים',
        body: const Center(
          child: Text('נא להתחבר'),
        ),
      );
    }

    return AppScaffold(
      title: 'משתמשים חסומים',
      body: FutureBuilder<List<User>>(
        future: usersRepo.getBlockedUsers(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('שגיאה: ${snapshot.error}'),
                ],
              ),
            );
          }

          final blockedUsers = snapshot.data ?? [];

          if (blockedUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'אין משתמשים חסומים',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'משתמשים שתחסום יופיעו כאן',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: PlayerAvatar(
                    user: user,
                    radius: 24,
                    clickable: true,
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.block, color: Colors.orange),
                          onPressed: () => _unblockUser(user.uid),
                          tooltip: 'בטל חסימה',
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


