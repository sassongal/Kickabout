import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/core/constants.dart';
import 'package:kattrick/models/hub_role.dart';

/// Screen for managing banned users in a hub
class BannedUsersScreen extends ConsumerStatefulWidget {
  final String hubId;

  const BannedUsersScreen({
    super.key,
    required this.hubId,
  });

  @override
  ConsumerState<BannedUsersScreen> createState() =>
      _BannedUsersScreenState();
}

class _BannedUsersScreenState extends ConsumerState<BannedUsersScreen> {
  bool _isLoading = false;

  Future<void> _unbanUser(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ביטול ניפוי'),
        content: const Text('האם אתה בטוח שברצונך לבטל את הניפוי?'),
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
      final hubsRepo = ref.read(hubsRepositoryProvider);
      await hubsRepo.unbanUserFromHub(widget.hubId, userId);

      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showSuccess(context, 'הניפוי בוטל');
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
    final hubsRepo = ref.read(hubsRepositoryProvider);

    return AppScaffold(
      title: 'משתמשים מנופים',
      body: FutureBuilder<List<User>>(
        future: hubsRepo.getBannedUsers(widget.hubId),
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

          final bannedUsers = snapshot.data ?? [];

          if (bannedUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'אין משתמשים מנופים',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'משתמשים שתנפה מההאב יופיעו כאן',
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
            itemCount: bannedUsers.length,
            itemBuilder: (context, index) {
              final user = bannedUsers[index];
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
                          onPressed: () => _unbanUser(user.uid),
                          tooltip: 'בטל ניפוי',
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


