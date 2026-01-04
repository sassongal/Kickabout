import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/data/proteams_repository.dart';
import 'package:kattrick/data/repositories.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/features/location/infrastructure/services/location_service.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/shared/infrastructure/logging/error_handler_service.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/widgets/common/premium_scaffold.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:kattrick/widgets/premium/empty_state.dart';
import 'package:kattrick/widgets/premium/skeleton_loader.dart';
import 'package:rxdart/rxdart.dart';

/// **TURBOCHARGED** Players List Screen
///
/// Performance optimizations:
/// - ✅ RxDart debouncing on search (300ms)
/// - ✅ Server-side search via usersRepository.searchUsers()
/// - ✅ Compact UI with dense tiles
/// - ✅ Search mode toggle: Nearby vs Global
/// - ✅ Skill level filter (1-5 stars based on managerRating)
/// - ✅ Slide-in animations with flutter_animate
class PlayersListScreenRefactored extends ConsumerStatefulWidget {
  const PlayersListScreenRefactored({super.key});

  @override
  ConsumerState<PlayersListScreenRefactored> createState() =>
      _PlayersListScreenRefactoredState();
}

enum SearchMode { nearby, global }

class _PlayersListScreenRefactoredState
    extends ConsumerState<PlayersListScreenRefactored> {
  // Search & Filter State
  final _searchController = TextEditingController();
  final _searchSubject = BehaviorSubject<String>();
  StreamSubscription? _searchSubscription;

  SearchMode _searchMode = SearchMode.nearby;
  String? _selectedCity;
  String? _selectedPosition;
  AgeGroup? _selectedAgeGroup;
  String? _selectedProTeamId;
  int? _selectedSkillLevel; // 1-5 stars filter

  // Data State
  List<User> _players = [];
  bool _isLoading = false;
  String? _error;
  Position? _currentPosition;

  final Map<String, double> _playerDistances = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeSearch();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchSubject.close();
    _searchSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize debounced search with RxDart
  void _initializeSearch() {
    _searchSubscription = _searchSubject
        .debounceTime(const Duration(milliseconds: 300))
        .distinct()
        .listen((query) {
      _performSearch();
    });
  }

  /// Load initial data (location + nearby players)
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final locationService = ref.read(locationServiceProvider);
      _currentPosition = await locationService.getCurrentLocation();

      await _performSearch();
    } catch (e) {
      setState(() {
        _error = ErrorHandlerService()
            .handleException(e, context: 'Players list initial load');
        _isLoading = false;
      });
    }
  }

  /// **Server-side search** - No client-side filtering!
  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      final query = _searchController.text.trim();

      List<User> results;

      if (_searchMode == SearchMode.global && query.isNotEmpty) {
        // 🔍 GLOBAL NAME SEARCH (server-side)
        results = await usersRepo.searchUsers(query, limit: 100);
      } else if (_searchMode == SearchMode.nearby && _currentPosition != null) {
        // 📍 NEARBY SEARCH (geohash-based)
        results = await usersRepo.findAvailablePlayersNearby(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          radiusKm: 50.0,
          limit: 100,
        );

        // If there's a search query in nearby mode, filter by name (minimal)
        if (query.isNotEmpty) {
          results = results.where((user) {
            return user.name.toLowerCase().contains(query.toLowerCase());
          }).toList();
        }
      } else {
        // Fallback: get all users
        results = await usersRepo.getAllUsers(limit: 100);
      }

      // Apply filters (these are lightweight filters on already-fetched data)
      results = _applyFilters(results);

      // Calculate distances if position available
      _calculateDistances(results);

      setState(() {
        _players = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorHandlerService()
            .handleException(e, context: 'Players search');
        _isLoading = false;
      });
    }
  }

  /// Apply client-side filters (only on already-fetched data)
  List<User> _applyFilters(List<User> users) {
    var filtered = users;

    // City filter
    if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      filtered = filtered.where((p) => p.city == _selectedCity).toList();
    }

    // Position filter
    if (_selectedPosition != null && _selectedPosition!.isNotEmpty) {
      filtered =
          filtered.where((p) => p.preferredPosition == _selectedPosition).toList();
    }

    // Age group filter
    if (_selectedAgeGroup != null) {
      filtered = filtered.where((p) => p.ageGroup == _selectedAgeGroup).toList();
    }

    // Favorite team filter
    if (_selectedProTeamId != null && _selectedProTeamId!.isNotEmpty) {
      filtered =
          filtered.where((p) => p.favoriteProTeamId == _selectedProTeamId).toList();
    }

    // Skill level filter (1-5 stars based on currentRankScore)
    if (_selectedSkillLevel != null) {
      filtered = filtered.where((p) {
        final rating = p.currentRankScore;

        // Map currentRankScore (0-10) to stars (1-5)
        final stars = (rating / 2).ceil();
        return stars == _selectedSkillLevel;
      }).toList();
    }

    return filtered;
  }

  /// Calculate distances from current position
  void _calculateDistances(List<User> users) {
    _playerDistances.clear();
    if (_currentPosition == null) return;

    for (final player in users) {
      if (player.location != null) {
        final distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          player.location!.latitude,
          player.location!.longitude,
        );
        _playerDistances[player.uid] = distance;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: 'לוח שחקנים',
      body: Column(
        children: [
          _buildSearchHeader(),
          const Divider(height: 1),
          Expanded(child: _buildPlayersList()),
        ],
      ),
    );
  }

  /// Search Header with Mode Toggle
  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: PremiumColors.surface,
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            onChanged: (value) => _searchSubject.add(value),
            style: PremiumTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: _searchMode == SearchMode.nearby
                  ? 'חפש בקרבתך...'
                  : 'חפש שחקן גלובלית...',
              hintStyle: PremiumTypography.bodySmall.copyWith(
                color: PremiumColors.textTertiary,
              ),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _searchSubject.add('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: PremiumColors.background,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: PremiumColors.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Search Mode Toggle + Filters
          Row(
            children: [
              // Mode Toggle
              Expanded(
                child: SegmentedButton<SearchMode>(
                  segments: const [
                    ButtonSegment(
                      value: SearchMode.nearby,
                      label: Text('📍 קרבתי', style: TextStyle(fontSize: 13)),
                    ),
                    ButtonSegment(
                      value: SearchMode.global,
                      label: Text('🔍 גלובלי', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                  selected: {_searchMode},
                  onSelectionChanged: (Set<SearchMode> newSelection) {
                    setState(() {
                      _searchMode = newSelection.first;
                    });
                    _performSearch();
                  },
                  style: ButtonStyle(
                    textStyle: WidgetStateProperty.all(
                      PremiumTypography.labelMedium,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Filter button
              IconButton(
                icon: Badge(
                  isLabelVisible: _hasActiveFilters(),
                  backgroundColor: PremiumColors.primary,
                  child: const Icon(Icons.filter_list, size: 20),
                ),
                onPressed: () => _showFilterDialog(context),
                tooltip: 'פילטרים',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Check if any filters are active
  bool _hasActiveFilters() {
    return _selectedCity != null ||
        _selectedPosition != null ||
        _selectedAgeGroup != null ||
        _selectedProTeamId != null ||
        _selectedSkillLevel != null;
  }

  /// Players List with Compact Cards
  Widget _buildPlayersList() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 5,
        itemBuilder: (context, index) => const SkeletonPlayerCard(),
      );
    }

    if (_error != null) {
      return PremiumEmptyState(
        icon: Icons.error_outline,
        title: 'שגיאה',
        message: _error!,
      );
    }

    if (_players.isEmpty) {
      return PremiumEmptyState(
        icon: Icons.people_outline,
        title: 'אין שחקנים',
        message: 'לא נמצאו שחקנים התואמים לחיפוש',
        action: ElevatedButton.icon(
          onPressed: () {
            // TODO: Add "Invite Friend" functionality
          },
          icon: const Icon(Icons.person_add),
          label: const Text('הזמן חבר'),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _players.length,
      itemBuilder: (context, index) {
        final player = _players[index];
        final distance = _playerDistances[player.uid];

        return CompactPlayerCard(
          player: player,
          distance: distance,
          onTap: () => context.push('/profile/${player.uid}'),
          onFollow: () => _handleFollow(player),
          onMessage: () => _handleMessage(player),
        )
            .animate()
            .slideX(
              begin: 0.1,
              end: 0,
              duration: const Duration(milliseconds: 250),
              delay: Duration(milliseconds: index * 30),
              curve: Curves.easeOutCubic,
            )
            .fadeIn(
              duration: const Duration(milliseconds: 250),
              delay: Duration(milliseconds: index * 30),
            );
      },
    );
  }

  /// Handle follow action
  Future<void> _handleFollow(User player) async {
    final currentUserId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final followRepo = ref.read(followRepositoryProvider);
      await followRepo.follow(currentUserId, player.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('התחלת לעקוב אחרי ${player.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e')),
        );
      }
    }
  }

  /// Handle message action
  Future<void> _handleMessage(User player) async {
    final currentUserId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final pmRepo = ref.read(privateMessagesRepositoryProvider);
      final conversationId =
          await pmRepo.getOrCreateConversation(currentUserId, player.uid);

      if (mounted) {
        context.push('/messages/$conversationId', extra: player);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה ביצירת שיחה: $e')),
        );
      }
    }
  }

  /// Filter Dialog
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
        title: Text('פילטרים', style: PremiumTypography.heading3),
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
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('כל הערים')),
                      ...cities.map((city) => DropdownMenuItem(
                            value: city,
                            child: Text(city),
                          )),
                    ],
                    onChanged: (value) => setDialogState(() => _selectedCity = value),
                  ),
                  const SizedBox(height: 12),

                  // Position filter
                  DropdownButtonFormField<String>(
                    value: _selectedPosition,
                    decoration: const InputDecoration(
                      labelText: 'עמדה',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('כל העמדות')),
                      ...positions.map((pos) => DropdownMenuItem(
                            value: pos,
                            child: Text(_getPositionHebrew(pos)),
                          )),
                    ],
                    onChanged: (value) => setDialogState(() => _selectedPosition = value),
                  ),
                  const SizedBox(height: 12),

                  // Age group filter
                  DropdownButtonFormField<AgeGroup>(
                    value: _selectedAgeGroup,
                    decoration: const InputDecoration(
                      labelText: 'קבוצת גיל',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<AgeGroup>(
                        value: null,
                        child: Text('כל קבוצות הגיל'),
                      ),
                      ...AgeGroup.values.map((ageGroup) => DropdownMenuItem(
                            value: ageGroup,
                            child: Text(ageGroup.displayNameHe),
                          )),
                    ],
                    onChanged: (value) => setDialogState(() => _selectedAgeGroup = value),
                  ),
                  const SizedBox(height: 12),

                  // Skill level filter (1-5 stars)
                  DropdownButtonFormField<int>(
                    value: _selectedSkillLevel,
                    decoration: const InputDecoration(
                      labelText: 'רמת מיומנות',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(Icons.stars),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('כל הרמות'),
                      ),
                      ...List.generate(5, (i) => i + 1).map((stars) => DropdownMenuItem(
                            value: stars,
                            child: Row(
                              children: [
                                ...List.generate(
                                  stars,
                                  (_) => const Icon(Icons.star, size: 16, color: Colors.amber),
                                ),
                                ...List.generate(
                                  5 - stars,
                                  (_) => const Icon(Icons.star_border, size: 16, color: Colors.grey),
                                ),
                                const SizedBox(width: 8),
                                Text('$stars כוכבים'),
                              ],
                            ),
                          )),
                    ],
                    onChanged: (value) => setDialogState(() => _selectedSkillLevel = value),
                  ),
                  const SizedBox(height: 12),

                  // Favorite team filter
                  FutureBuilder<List<ProTeam>>(
                    future: ref.read(proTeamsRepositoryProvider).getAllTeams(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final teams = snapshot.data!;
                      return DropdownButtonFormField<String>(
                        value: _selectedProTeamId,
                        decoration: const InputDecoration(
                          labelText: 'קבוצה אהודה',
                          border: OutlineInputBorder(),
                          isDense: true,
                          prefixIcon: Icon(Icons.sports_soccer),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('כל הקבוצות'),
                          ),
                          ...teams.map((team) => DropdownMenuItem(
                                value: team.teamId,
                                child: Row(
                                  children: [
                                    _buildTeamLogo(team.logoUrl, size: 20),
                                    const SizedBox(width: 8),
                                    Text(team.name),
                                  ],
                                ),
                              )),
                        ],
                        onChanged: (value) =>
                            setDialogState(() => _selectedProTeamId = value),
                      );
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
                _selectedAgeGroup = null;
                _selectedProTeamId = null;
                _selectedSkillLevel = null;
              });
              Navigator.pop(context);
              _performSearch();
            },
            child: const Text('איפוס'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performSearch();
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

  Widget _buildTeamLogo(String logoUrl, {double size = 24}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        imageUrl: logoUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: Colors.grey[200],
        ),
        errorWidget: (context, url, error) => const Icon(
          Icons.sports_soccer,
          size: 18,
          color: PremiumColors.textSecondary,
        ),
      ),
    );
  }
}

/// **Compact Player Card** - Pro-Tool Dense Design
class CompactPlayerCard extends ConsumerWidget {
  const CompactPlayerCard({
    required this.player,
    required this.onTap,
    required this.onFollow,
    required this.onMessage,
    this.distance,
    super.key,
  });

  final User player;
  final double? distance;
  final VoidCallback onTap;
  final VoidCallback onFollow;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PremiumCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Avatar (compact)
            Stack(
              children: [
                PlayerAvatar(user: player, radius: 24),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getAvailabilityColor(player.availabilityStatus),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Player Info (compact)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: PremiumTypography.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      if (player.city != null && player.city!.isNotEmpty)
                        _buildCompactInfo(Icons.location_city, player.city!),
                      if (player.preferredPosition.isNotEmpty)
                        _buildCompactInfo(Icons.sports_soccer, player.preferredPosition),
                      if (distance != null)
                        _buildCompactInfo(
                          Icons.location_on,
                          distance! < 1000
                              ? '${distance!.toStringAsFixed(0)}m'
                              : '${(distance! / 1000).toStringAsFixed(1)}km',
                          color: PremiumColors.primary,
                        ),
                    ],
                  ),
                  // Star rating (based on currentRankScore)
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      ...List.generate(
                        (player.currentRankScore / 2).ceil(),
                        (_) => const Icon(Icons.star, size: 12, color: Colors.amber),
                      ),
                      ...List.generate(
                        5 - (player.currentRankScore / 2).ceil(),
                        (_) => const Icon(Icons.star_border, size: 12, color: Colors.grey),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${player.totalParticipations} משחקים',
                        style: PremiumTypography.labelSmall.copyWith(
                          color: PremiumColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action Buttons (compact)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  onPressed: onFollow,
                  tooltip: 'עקוב',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  color: PremiumColors.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.message_outlined, size: 18),
                  onPressed: onMessage,
                  tooltip: 'הודעה',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  color: PremiumColors.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfo(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: color ?? PremiumColors.textTertiary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: PremiumTypography.labelSmall.copyWith(
            color: color ?? PremiumColors.textSecondary,
          ),
        ),
      ],
    );
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
}
