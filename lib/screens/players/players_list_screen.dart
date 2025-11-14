import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/data/repositories.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_card.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/widgets/player_avatar.dart';
import 'package:kickadoor/services/location_service.dart';

/// Players List Screen - לוח שחקנים
class PlayersListScreen extends ConsumerStatefulWidget {
  const PlayersListScreen({super.key});

  @override
  ConsumerState<PlayersListScreen> createState() => _PlayersListScreenState();
}

class _PlayersListScreenState extends ConsumerState<PlayersListScreen> {
  String _searchQuery = '';
  String _sortBy = 'rating'; // rating, distance, name
  bool _showAvailableOnly = false;
  String? _selectedCity;
  String? _selectedPosition;
  double? _minRating;

  @override
  Widget build(BuildContext context) {
    final locationService = ref.watch(locationServiceProvider);
    final usersRepo = ref.watch(usersRepositoryProvider);

    return FuturisticScaffold(
      title: 'לוח שחקנים',
      actions: [
        IconButton(
          icon: Icon(_showAvailableOnly ? Icons.check_circle : Icons.check_circle_outline),
          onPressed: () {
            setState(() {
              _showAvailableOnly = !_showAvailableOnly;
            });
          },
          tooltip: 'הצג רק זמינים',
        ),
      ],
      body: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'חפש שחקן...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: FuturisticColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: FuturisticColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'rating',
                            label: Text('דירוג'),
                            icon: Icon(Icons.star),
                          ),
                          ButtonSegment(
                            value: 'distance',
                            label: Text('מרחק'),
                            icon: Icon(Icons.location_on),
                          ),
                          ButtonSegment(
                            value: 'name',
                            label: Text('שם'),
                            icon: Icon(Icons.sort_by_alpha),
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
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () => _showFilterDialog(context),
                      tooltip: 'פילטרים',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Players list
          Expanded(
            child: FutureBuilder<List<User>>(
              future: _getPlayers(usersRepo, locationService),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 5,
                    itemBuilder: (context, index) => const SkeletonPlayerCard(),
                  );
                }

                if (snapshot.hasError) {
                  return FuturisticEmptyState(
                    icon: Icons.error_outline,
                    title: 'שגיאה בטעינת שחקנים',
                    message: snapshot.error.toString(),
                  );
                }

                final players = snapshot.data ?? [];
                if (players.isEmpty) {
                  return FuturisticEmptyState(
                    icon: Icons.people_outline,
                    title: 'אין שחקנים',
                    message: 'לא נמצאו שחקנים התואמים לחיפוש',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: FuturisticCard(
                        onTap: () => context.push('/profile/${player.uid}'),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // Avatar
                              Stack(
                                children: [
                                  PlayerAvatar(
                                    user: player,
                                    radius: 32,
                                  ),
                                  // Availability indicator
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: _getAvailabilityColor(player.availabilityStatus),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: FuturisticColors.background,
                                          width: 2,
                                        ),
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
                                      player.name,
                                      style: FuturisticTypography.heading3,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (player.preferredPosition.isNotEmpty) ...[
                                          Icon(
                                            Icons.sports_soccer,
                                            size: 14,
                                            color: FuturisticColors.textTertiary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            player.preferredPosition,
                                            style: FuturisticTypography.bodySmall,
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        if (player.city != null && player.city!.isNotEmpty) ...[
                                          Icon(
                                            Icons.location_city,
                                            size: 14,
                                            color: FuturisticColors.textTertiary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            player.city!,
                                            style: FuturisticTypography.bodySmall,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 14,
                                          color: FuturisticColors.secondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'דירוג: ${player.currentRankScore.toStringAsFixed(1)}',
                                          style: FuturisticTypography.bodySmall.copyWith(
                                            color: FuturisticColors.secondary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.event,
                                          size: 14,
                                          color: FuturisticColors.textTertiary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${player.totalParticipations} משחקים',
                                          style: FuturisticTypography.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Rating badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: FuturisticColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  player.currentRankScore.toStringAsFixed(1),
                                  style: FuturisticTypography.labelMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  Future<List<User>> _getPlayers(
    UsersRepository usersRepo,
    LocationService locationService,
  ) async {
    try {
      // Get all users (in a real app, you'd want pagination)
      // For now, we'll get users from nearby hubs or all users
      final position = await locationService.getCurrentLocation();
      
      List<User> players;
      if (position != null) {
        // Get nearby available players
        players = await usersRepo.findAvailablePlayersNearby(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusKm: 50.0, // 50km radius
          limit: 100,
        );
      } else {
        // Fallback: get all users (limited)
        // Note: This is not ideal for production - you'd want pagination
        players = await usersRepo.getAllUsers(limit: 100);
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        players = players.where((player) {
          return player.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (player.city != null && player.city!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
              (player.preferredPosition.toLowerCase().contains(_searchQuery.toLowerCase()));
        }).toList();
      }

      // Filter by availability
      if (_showAvailableOnly) {
        players = players.where((p) => p.availabilityStatus == 'available').toList();
      }

      // Filter by city
      if (_selectedCity != null && _selectedCity!.isNotEmpty) {
        players = players.where((p) => p.city == _selectedCity).toList();
      }

      // Filter by position
      if (_selectedPosition != null && _selectedPosition!.isNotEmpty) {
        players = players.where((p) => p.preferredPosition == _selectedPosition).toList();
      }

      // Filter by minimum rating
      if (_minRating != null) {
        players = players.where((p) => p.currentRankScore >= _minRating!).toList();
      }

      // Sort
      switch (_sortBy) {
        case 'rating':
          players.sort((a, b) => b.currentRankScore.compareTo(a.currentRankScore));
          break;
        case 'name':
          players.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'distance':
          // Distance sorting would require calculating distance for each player
          // For now, keep as is (already sorted by distance from findAvailablePlayersNearby)
          break;
      }

      return players;
    } catch (e) {
      return [];
    }
  }

  Color _getAvailabilityColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'busy':
        return Colors.orange;
      case 'notAvailable':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    final cities = ['חיפה', 'קריית אתא', 'קריית ביאליק', 'קריית ים', 'נשר', 'טירת כרמל'];
    final positions = ['Goalkeeper', 'Defender', 'Midfielder', 'Forward'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('פילטרים'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // City filter
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    decoration: const InputDecoration(
                      labelText: 'עיר',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('כל הערים')),
                      ...cities.map((city) => DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedCity = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Position filter
                  DropdownButtonFormField<String>(
                    value: _selectedPosition,
                    decoration: const InputDecoration(
                      labelText: 'עמדה',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('כל העמדות')),
                      ...positions.map((pos) => DropdownMenuItem(
                        value: pos,
                        child: Text(_getPositionHebrew(pos)),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedPosition = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Min rating filter
                  Text('דירוג מינימלי: ${_minRating?.toStringAsFixed(1) ?? "כל הדירוגים"}'),
                  Slider(
                    value: _minRating ?? 0.0,
                    min: 0.0,
                    max: 10.0,
                    divisions: 20,
                    label: _minRating?.toStringAsFixed(1) ?? 'כל הדירוגים',
                    onChanged: (value) {
                      setDialogState(() {
                        _minRating = value > 0 ? value : null;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCity = null;
                _selectedPosition = null;
                _minRating = null;
              });
              Navigator.pop(context);
            },
            child: const Text('איפוס'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('החל'),
          ),
        ],
      ),
    );
  }

  String _getPositionHebrew(String position) {
    switch (position) {
      case 'Goalkeeper':
        return 'שוער';
      case 'Defender':
        return 'מגן';
      case 'Midfielder':
        return 'קשר';
      case 'Forward':
        return 'חלוץ';
      default:
        return position;
    }
  }
}

