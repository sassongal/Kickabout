import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:kattrick/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/data/repositories.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/theme/futuristic_theme.dart';
import 'package:kattrick/widgets/futuristic/futuristic_card.dart';
import 'package:kattrick/widgets/futuristic/empty_state.dart';
import 'package:kattrick/widgets/futuristic/skeleton_loader.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:kattrick/services/location_service.dart';
import 'package:kattrick/services/error_handler_service.dart';
import 'package:geolocator/geolocator.dart';

/// Players List Screen - לוח שחקנים
class PlayersListScreen extends ConsumerStatefulWidget {
  const PlayersListScreen({super.key});

  @override
  ConsumerState<PlayersListScreen> createState() => _PlayersListScreenState();
}

class _PlayersListScreenState extends ConsumerState<PlayersListScreen> {
  String _searchQuery = '';
  String _sortBy = 'name'; // distance, name
  bool _showAvailableOnly = false;
  String? _selectedCity;
  String? _selectedPosition;

  final Map<String, double> _playerDistances = {};
  final ScrollController _scrollController = ScrollController();
  List<User> _allPlayers = [];
  List<User> _displayedPlayers = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMorePlayers();
    }
  }

  Future<void> _loadMorePlayers() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    final nextIndex = _displayedPlayers.length;
    final endIndex = (nextIndex + _pageSize).clamp(0, _allPlayers.length);

    if (nextIndex < _allPlayers.length) {
      setState(() {
        _displayedPlayers.addAll(_allPlayers.sublist(nextIndex, endIndex));
        _hasMore = endIndex < _allPlayers.length;
        _isLoadingMore = false;
      });
    } else {
      setState(() {
        _hasMore = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationService = ref.watch(locationServiceProvider);
    final hubsRepo = ref.watch(hubsRepositoryProvider);
    final currentUserId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    final usersRepo = ref.watch(usersRepositoryProvider);

    return FuturisticScaffold(
      title: 'לוח שחקנים',
      actions: [
        IconButton(
          icon: Icon(_showAvailableOnly
              ? Icons.check_circle
              : Icons.check_circle_outline),
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
          Expanded(
            child: FutureBuilder<List<Hub>>(
              future: _getMyHubs(hubsRepo, currentUserId),
              builder: (context, hubsSnapshot) {
                final myHubs = hubsSnapshot.data ?? [];

                return FutureBuilder<List<User>>(
                  future: _getPlayers(usersRepo, locationService),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 5,
                        itemBuilder: (context, index) =>
                            const SkeletonPlayerCard(),
                      );
                    }

                    if (snapshot.hasError) {
                      return FuturisticEmptyState(
                        icon: Icons.error_outline,
                        title: 'שגיאה בטעינת שחקנים',
                        message: ErrorHandlerService().handleException(
                          snapshot.error,
                          context: 'Players list screen',
                        ),
                      );
                    }

                    final allPlayers = snapshot.data ?? [];

                    if (_allPlayers.length != allPlayers.length ||
                        (_allPlayers.isNotEmpty &&
                            _allPlayers.first.uid != allPlayers.first.uid)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _allPlayers = allPlayers;
                            _displayedPlayers =
                                allPlayers.take(_pageSize).toList();
                            _hasMore = allPlayers.length > _pageSize;
                          });
                        }
                      });
                    }

                    final playersToShow = _displayedPlayers.isNotEmpty
                        ? _displayedPlayers
                        : allPlayers.take(_pageSize).toList();
                    final hasMoreToShow = _displayedPlayers.isNotEmpty
                        ? _hasMore
                        : allPlayers.length > _pageSize;

                    if (playersToShow.isEmpty && allPlayers.isEmpty) {
                      return const FuturisticEmptyState(
                        icon: Icons.people_outline,
                        title: 'אין שחקנים',
                        message: 'לא נמצאו שחקנים התואמים לחיפוש',
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: playersToShow.length + (hasMoreToShow ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == playersToShow.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final player = playersToShow[index];
                        final distance = _playerDistances[player.uid];
                        final sharedHubs = myHubs
                            .where((hub) => player.hubIds.contains(hub.hubId))
                            .toList();
                        final managerHubCandidates = currentUserId == null
                            ? <Hub>[]
                            : sharedHubs.where((hub) {
                                final role = hub.roles[currentUserId];
                                return role == 'manager' ||
                                    role == 'admin' ||
                                    hub.createdBy == currentUserId;
                              }).toList();
                        final managerHub = managerHubCandidates.isNotEmpty
                            ? managerHubCandidates.first
                            : null;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: FuturisticCard(
                            onTap: () => context.push('/profile/${player.uid}'),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      PlayerAvatar(
                                        user: player,
                                        radius: 32,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: _getAvailabilityColor(
                                                player.availabilityStatus),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  FuturisticColors.background,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                player.name,
                                                style: FuturisticTypography
                                                    .heading3,
                                              ),
                                            ),
                                            // Social media icons (if enabled and links exist)
                                            if (player.showSocialLinks) ...[
                                              if (player.facebookProfileUrl !=
                                                      null &&
                                                  player.facebookProfileUrl!
                                                      .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 4),
                                                  child: Icon(
                                                    Icons.facebook,
                                                    size: 16,
                                                    color:
                                                        const Color(0xFF1877F2),
                                                  ),
                                                ),
                                              if (player.instagramProfileUrl !=
                                                      null &&
                                                  player.instagramProfileUrl!
                                                      .isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 4),
                                                  child: Icon(
                                                    Icons.camera_alt,
                                                    size: 16,
                                                    color:
                                                        const Color(0xFFE4405F),
                                                  ),
                                                ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 4,
                                          children: [
                                            if (player.city != null &&
                                                player.city!.isNotEmpty)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.location_city,
                                                    size: 14,
                                                    color: FuturisticColors
                                                        .textTertiary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    player.city!,
                                                    style: FuturisticTypography
                                                        .bodySmall,
                                                  ),
                                                ],
                                              ),
                                            if (player
                                                .preferredPosition.isNotEmpty)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.sports_soccer,
                                                    size: 14,
                                                    color: FuturisticColors
                                                        .textTertiary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    player.preferredPosition,
                                                    style: FuturisticTypography
                                                        .bodySmall,
                                                  ),
                                                ],
                                              ),
                                            if (player.favoriteTeamId != null)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.favorite,
                                                    size: 14,
                                                    color:
                                                        FuturisticColors.error,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'קבוצה אהודה',
                                                    style: FuturisticTypography
                                                        .bodySmall,
                                                  ),
                                                ],
                                              ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.group,
                                                  size: 14,
                                                  color: FuturisticColors
                                                      .textTertiary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${player.hubIds.length} הובים',
                                                  style: FuturisticTypography
                                                      .bodySmall,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.event,
                                              size: 14,
                                              color:
                                                  FuturisticColors.textTertiary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${player.totalParticipations} משחקים',
                                              style: FuturisticTypography
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                        // Only show shared hubs info, not manager rating (manager ratings are private)
                                        if (sharedHubs.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.handshake,
                                                size: 14,
                                                color: FuturisticColors.primary,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'אתם יחד ב${sharedHubs.first.name}',
                                                  style: FuturisticTypography
                                                      .bodySmall
                                                      .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: FuturisticColors
                                                        .primary,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (distance != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 14,
                                                color: FuturisticColors.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                distance < 1000
                                                    ? 'מרחק: ${distance.toStringAsFixed(0)} מ\''
                                                    : 'מרחק: ${(distance / 1000).toStringAsFixed(1)} ק"מ',
                                                style: FuturisticTypography
                                                    .bodySmall
                                                    .copyWith(
                                                  color:
                                                      FuturisticColors.primary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Hub>> _getMyHubs(
    HubsRepository hubsRepo,
    String? currentUserId,
  ) async {
    if (currentUserId == null) return [];
    try {
      return await hubsRepo.getHubsByMember(currentUserId);
    } catch (_) {
      return [];
    }
  }

  Future<List<User>> _getPlayers(
    UsersRepository usersRepo,
    LocationService locationService,
  ) async {
    try {
      final position = await locationService.getCurrentLocation();

      List<User> players;
      if (position != null) {
        players = await usersRepo.findAvailablePlayersNearby(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusKm: 50.0,
          limit: 100,
        );
      } else {
        players = await usersRepo.getAllUsers(limit: 100);
      }

      if (_searchQuery.isNotEmpty) {
        players = players.where((player) {
          return player.name
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (player.city != null &&
                  player.city!
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase())) ||
              (player.preferredPosition
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()));
        }).toList();
      }

      if (_showAvailableOnly) {
        players =
            players.where((p) => p.availabilityStatus == 'available').toList();
      }

      if (_selectedCity != null && _selectedCity!.isNotEmpty) {
        players = players.where((p) => p.city == _selectedCity).toList();
      }

      if (_selectedPosition != null && _selectedPosition!.isNotEmpty) {
        players = players
            .where((p) => p.preferredPosition == _selectedPosition)
            .toList();
      }

      _playerDistances.clear();
      if (position != null) {
        for (final player in players) {
          if (player.location != null) {
            final distance = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              player.location!.latitude,
              player.location!.longitude,
            );
            _playerDistances[player.uid] = distance;
          }
        }
      }

      switch (_sortBy) {
        case 'name':
          players.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'distance':
          if (position != null) {
            players.sort((a, b) {
              final distA = _playerDistances[a.uid];
              final distB = _playerDistances[b.uid];
              if (distA == null && distB == null) return 0;
              if (distA == null) return 1;
              if (distB == null) return -1;
              return distA.compareTo(distB);
            });
          } else {
            // If no position, sort by name
            players.sort((a, b) => a.name.compareTo(b.name));
          }
          break;
        default:
          // Default to name sorting
          players.sort((a, b) => a.name.compareTo(b.name));
          break;
      }

      return players;
    } catch (_) {
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
    final cities = [
      'חיפה',
      'קריית אתא',
      'קריית ביאליק',
      'קריית ים',
      'נשר',
      'טירת כרמל'
    ];
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
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCity,
                    decoration: const InputDecoration(
                      labelText: 'עיר',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('כל הערים')),
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
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPosition,
                    decoration: const InputDecoration(
                      labelText: 'עמדה',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('כל העמדות')),
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
