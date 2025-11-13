import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/skeleton_loader.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/screens/hub/add_manual_player_dialog.dart';
import 'package:kickadoor/screens/hub/edit_manual_player_dialog.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Dedicated screen for viewing all players in a hub
class HubPlayersListScreen extends ConsumerStatefulWidget {
  final String hubId;

  const HubPlayersListScreen({super.key, required this.hubId});

  @override
  ConsumerState<HubPlayersListScreen> createState() => _HubPlayersListScreenState();
}

class _HubPlayersListScreenState extends ConsumerState<HubPlayersListScreen> {
  String _searchQuery = '';
  String _sortBy = 'rating'; // rating, name, position
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<User> _filterAndSort(List<User> users) {
    var filtered = users;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        final query = _searchQuery.toLowerCase();
        return user.name.toLowerCase().contains(query) ||
            (user.email.toLowerCase().contains(query)) ||
            (user.city?.toLowerCase().contains(query) ?? false) ||
            (user.preferredPosition.toLowerCase().contains(query));
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'rating':
          return b.currentRankScore.compareTo(a.currentRankScore);
        case 'name':
          return a.name.compareTo(b.name);
        case 'position':
          return a.preferredPosition.compareTo(b.preferredPosition);
        default:
          return 0;
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final hubsRepo = ref.watch(hubsRepositoryProvider);
    final usersRepo = ref.watch(usersRepositoryProvider);

    return FuturisticScaffold(
      title: 'שחקני ההוב',
      showBackButton: true,
      body: StreamBuilder<Hub?>(
        stream: hubsRepo.watchHub(widget.hubId),
        builder: (context, hubSnapshot) {
          if (hubSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!hubSnapshot.hasData || hubSnapshot.data == null) {
            return Center(
              child: Text(
                'Hub לא נמצא',
                style: FuturisticTypography.bodyLarge,
              ),
            );
          }

          final hub = hubSnapshot.data!;
          final isHubManager = currentUserId == hub.createdBy;

          if (hub.memberIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: FuturisticColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'אין שחקנים בהוב',
                    style: FuturisticTypography.heading3,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'הוסף שחקנים כדי להתחיל',
                    style: FuturisticTypography.bodyMedium,
                  ),
                  if (isHubManager) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => AddManualPlayerDialog(hubId: widget.hubId),
                        );
                        if (result == true && mounted) {
                          // Refresh will happen automatically
                        }
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('הוסף שחקן'),
                    ),
                  ],
                ],
              ),
            );
          }

          return FutureBuilder<List<User>>(
            future: usersRepo.getUsers(hub.memberIds),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  itemBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: SkeletonPlayerCard(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: FuturisticColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'שגיאה בטעינת שחקנים',
                        style: FuturisticTypography.heading3,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: FuturisticTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final allUsers = snapshot.data ?? [];
              final filteredUsers = _filterAndSort(allUsers);

              return Column(
                children: [
                  // Search and filter bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Search field
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'חפש שחקן...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        // Sort options
                        Row(
                          children: [
                            Text(
                              'מיין לפי:',
                              style: FuturisticTypography.labelMedium,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'rating',
                                    label: Text('ציון'),
                                    icon: Icon(Icons.star),
                                  ),
                                  ButtonSegment(
                                    value: 'name',
                                    label: Text('שם'),
                                    icon: Icon(Icons.sort_by_alpha),
                                  ),
                                  ButtonSegment(
                                    value: 'position',
                                    label: Text('עמדה'),
                                    icon: Icon(Icons.sports_soccer),
                                  ),
                                ],
                                selected: {_sortBy},
                                onSelectionChanged: (Set<String> newSelection) {
                                  setState(() {
                                    _sortBy = newSelection.first;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        // Add player button (for managers)
                        if (isHubManager) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (context) => AddManualPlayerDialog(hubId: widget.hubId),
                              );
                              if (result == true && mounted) {
                                // Refresh will happen automatically
                              }
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('הוסף שחקן ידנית'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FuturisticColors.secondary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Players list
                  Expanded(
                    child: filteredUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: FuturisticColors.textSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'לא נמצאו שחקנים',
                                  style: FuturisticTypography.heading3,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'נסה לשנות את החיפוש',
                                  style: FuturisticTypography.bodyMedium,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              final isManualPlayer = user.email.startsWith('manual_');
                              final isCreator = user.uid == hub.createdBy;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: FuturisticCard(
                                  onTap: isManualPlayer
                                      ? (isHubManager
                                          ? () async {
                                              final result = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => EditManualPlayerDialog(
                                                  player: user,
                                                  hubId: widget.hubId,
                                                ),
                                              );
                                              if (result == true && mounted) {
                                                // Refresh will happen automatically
                                              }
                                            }
                                          : null)
                                      : () => context.push('/profile/${user.uid}'),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: CircleAvatar(
                                      radius: 30,
                                      backgroundColor: FuturisticColors.primaryContainer,
                                      backgroundImage: user.photoUrl != null
                                          ? CachedNetworkImageProvider(user.photoUrl!)
                                          : null,
                                      child: user.photoUrl == null
                                          ? Icon(
                                              Icons.person,
                                              size: 30,
                                              color: FuturisticColors.primary,
                                            )
                                          : null,
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            user.name,
                                            style: FuturisticTypography.labelLarge,
                                          ),
                                        ),
                                        if (isCreator)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: FuturisticColors.primary,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'יוצר',
                                              style: FuturisticTypography.labelSmall.copyWith(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        if (isManualPlayer) ...[
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.edit_note,
                                            size: 16,
                                            color: FuturisticColors.secondary,
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        if (!isManualPlayer)
                                          Text(
                                            user.email,
                                            style: FuturisticTypography.bodySmall,
                                          ),
                                        if (isManualPlayer)
                                          Text(
                                            'שחקן ידני - ללא אפליקציה',
                                            style: FuturisticTypography.bodySmall.copyWith(
                                              color: FuturisticColors.secondary,
                                            ),
                                          ),
                                        if (user.city != null) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 14,
                                                color: FuturisticColors.textSecondary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                user.city!,
                                                style: FuturisticTypography.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (user.preferredPosition.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.sports_soccer,
                                                size: 14,
                                                color: FuturisticColors.textSecondary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                user.preferredPosition,
                                                style: FuturisticTypography.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              size: 16,
                                              color: FuturisticColors.warning,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${user.currentRankScore.toStringAsFixed(1)}',
                                              style: FuturisticTypography.labelMedium.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: FuturisticColors.warning,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: isManualPlayer && isHubManager
                                        ? IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () async {
                                              final result = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => EditManualPlayerDialog(
                                                  player: user,
                                                  hubId: widget.hubId,
                                                ),
                                              );
                                              if (result == true && mounted) {
                                                // Refresh will happen automatically
                                              }
                                            },
                                            tooltip: 'ערוך שחקן',
                                          )
                                        : const Icon(Icons.chevron_left),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

