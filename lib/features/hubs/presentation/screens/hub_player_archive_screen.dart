import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/widgets/common/premium_scaffold.dart';
import 'package:kattrick/core/providers/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/features/hubs/domain/models/hub_member.dart' as models;
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';

/// Screen showing archived players for a hub
class HubPlayerArchiveScreen extends ConsumerStatefulWidget {
  final String hubId;

  const HubPlayerArchiveScreen({super.key, required this.hubId});

  @override
  ConsumerState<HubPlayerArchiveScreen> createState() =>
      _HubPlayerArchiveScreenState();
}

class _HubPlayerArchiveScreenState
    extends ConsumerState<HubPlayerArchiveScreen> {
  List<_ArchivedPlayerData>? _archivedPlayers;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArchivedPlayers();
  }

  Future<void> _loadArchivedPlayers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final usersRepo = ref.read(usersRepositoryProvider);

      // Get archived members
      final archivedMembers = await hubsRepo.getHubMembersByStatus(
        hubId: widget.hubId,
        status: models.HubMemberStatus.archived,
      );

      // Fetch user data for each archived member
      final List<_ArchivedPlayerData> playerDataList = [];
      for (final member in archivedMembers) {
        final user = await usersRepo.getUser(member.userId);
        if (user != null) {
          playerDataList.add(_ArchivedPlayerData(
            member: member,
            user: user,
          ));
        }
      }

      setState(() {
        _archivedPlayers = playerDataList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading archived players: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _restorePlayer(_ArchivedPlayerData playerData) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('שחזר שחקן'),
        content: Text(
          'האם לשחזר את ${playerData.user.name} לרשימת השחקנים הפעילים?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('שחזר'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final hubsRepo = ref.read(hubsRepositoryProvider);
        await hubsRepo.updateMemberStatus(
          widget.hubId,
          playerData.member.userId,
          models.HubMemberStatus.active,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${playerData.user.name} שוחזר בהצלחה'),
              backgroundColor: Colors.green,
            ),
          );

          // Reload the list
          await _loadArchivedPlayers();
        }
      } catch (e) {
        debugPrint('Error restoring player: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('שגיאה בשחזור שחקן'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: 'ארכיון שחקנים',
      showBackButton: true,
      body: _isLoading
          ? const Center(child: KineticLoadingAnimation(size: 60))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'שגיאה בטעינת הארכיון',
                        style: PremiumTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: PremiumTypography.bodySmall.copyWith(
                          color: PremiumColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadArchivedPlayers,
                        icon: const Icon(Icons.refresh),
                        label: const Text('נסה שוב'),
                      ),
                    ],
                  ),
                )
              : _archivedPlayers!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.archive_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'אין שחקנים בארכיון',
                            style: PremiumTypography.heading2,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'שחקנים שיועברו לארכיון יופיעו כאן',
                            style: PremiumTypography.bodyMedium.copyWith(
                              color: PremiumColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadArchivedPlayers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _archivedPlayers!.length,
                        itemBuilder: (context, index) {
                          final playerData = _archivedPlayers![index];
                          return _buildArchivedPlayerCard(playerData);
                        },
                      ),
                    ),
    );
  }

  Widget _buildArchivedPlayerCard(_ArchivedPlayerData playerData) {
    final user = playerData.user;
    final member = playerData.member;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        elevation: PremiumCardElevation.sm,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar with archive badge
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: user.photoUrl != null
                      ? CachedNetworkImageProvider(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: PremiumTypography.heading3,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.archive,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Player info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: PremiumTypography.heading3,
                  ),
                  const SizedBox(height: 4),
                  // preferredPosition is never null
                    Text(
                      user.preferredPosition,
                      style: PremiumTypography.bodySmall.copyWith(
                        color: PremiumColors.textSecondary,
                      ),
                    ),
                  if (member.managerRating > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          member.managerRating.toStringAsFixed(1),
                          style: PremiumTypography.bodySmall.copyWith(
                            color: PremiumColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (member.updatedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'הועבר לארכיון: ${_formatDate(member.updatedAt!)}',
                      style: PremiumTypography.bodySmall.copyWith(
                        color: Colors.orange,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Restore button
            ElevatedButton.icon(
              onPressed: () => _restorePlayer(playerData),
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('שחזר'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PremiumColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'היום';
    } else if (difference.inDays == 1) {
      return 'אתמול';
    } else if (difference.inDays < 7) {
      return 'לפני ${difference.inDays} ימים';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'לפני $weeks ${weeks == 1 ? 'שבוע' : 'שבועות'}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'לפני $months ${months == 1 ? 'חודש' : 'חודשים'}';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'לפני $years ${years == 1 ? 'שנה' : 'שנים'}';
    }
  }
}

/// Helper class to hold archived player data
class _ArchivedPlayerData {
  final models.HubMember member;
  final User user;

  _ArchivedPlayerData({
    required this.member,
    required this.user,
  });
}
