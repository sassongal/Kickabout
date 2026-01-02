import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/shared/infrastructure/logging/error_handler_service.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/premium/empty_state.dart';
import 'package:kattrick/widgets/premium/skeleton_loader.dart';
import 'package:kattrick/utils/city_utils.dart';
import 'package:kattrick/widgets/community/community_welcome_card.dart';

/// Community screen showing hub recruiting posts and public games
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  String? _selectedRegion;
  String? _selectedCity;
  bool _initializedFromUser = false;
  Stream<List<FeedPost>>? _cachedRecruitingStream;
  Stream<List<Game>>? _cachedPublicGamesStream;
  String? _cachedRegion;
  String? _cachedCity;

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CommunityFiltersSheet(
        selectedRegion: _selectedRegion,
        selectedCity: _selectedCity,
        onApply: (region, city) {
          setState(() {
            _selectedRegion = region;
            _selectedCity = city;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedRepo = ref.watch(feedRepositoryProvider);
    final gameQueriesRepo = ref.watch(gameQueriesRepositoryProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final usersRepo = ref.read(usersRepositoryProvider);

    // Region-aware recruiting posts
    final userFuture = currentUserId != null
        ? usersRepo.getUser(currentUserId)
        : Future<User?>.value(null);

    return FutureBuilder<User?>(
      future: userFuture,
      builder: (context, userSnap) {
        final user = userSnap.data;
        final userRegion = user?.region;

        if (!_initializedFromUser &&
            _selectedRegion == null &&
            userRegion != null &&
            userRegion.isNotEmpty) {
          _initializedFromUser = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _selectedRegion = userRegion);
            }
          });
        }

        final effectiveRegion = _selectedRegion ?? userRegion;
        final effectiveCity = _selectedCity;

        // OPTIMIZATION: Only recreate streams if region/city changed
        // This prevents stream recreation on every rebuild, eliminating flickering
        if (_cachedRegion != effectiveRegion || _cachedCity != effectiveCity) {
          _cachedRegion = effectiveRegion;
          _cachedCity = effectiveCity;
          _cachedRecruitingStream = feedRepo.streamRegionalFeed(
            region: effectiveRegion,
            city: effectiveCity,
            postType: 'hub_recruiting',
          );
          _cachedPublicGamesStream = gameQueriesRepo.watchPublicCompletedGames(
            limit: 50,
            region: effectiveRegion,
            city: effectiveCity,
          );
        }

        final recruitingStream = _cachedRecruitingStream!;
        final publicGamesStream = _cachedPublicGamesStream!;

        final hasFilters =
            (_selectedRegion != null && _selectedRegion!.isNotEmpty) ||
                (_selectedCity != null && _selectedCity!.isNotEmpty);

        final headerText = effectiveRegion != null && effectiveRegion.isNotEmpty
            ? (effectiveCity != null && effectiveCity.isNotEmpty
                ? 'תוכן לפי אזור: $effectiveRegion • $effectiveCity'
                : 'תוכן לפי אזור: $effectiveRegion')
            : (effectiveCity != null && effectiveCity.isNotEmpty
                ? 'תוכן לפי עיר: $effectiveCity'
                : 'תוכן קהילתי');

        return AppScaffold(
          title: 'קהילה',
          showBottomNav: true,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.public, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        headerText,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: _showFilters,
                      icon: Icon(
                        Icons.filter_list,
                        color: hasFilters
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      tooltip: 'סינון',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<FeedPost>>(
                  stream: recruitingStream,
                  builder: (context, recruitSnap) {
                    final recruitingPosts = recruitSnap.data ?? [];
                    return StreamBuilder<List<Game>>(
                      stream: publicGamesStream,
                      builder: (context, gameSnap) {
                        if (recruitSnap.connectionState ==
                                ConnectionState.waiting ||
                            gameSnap.connectionState ==
                                ConnectionState.waiting) {
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: 4,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SkeletonLoader(height: 120),
                            ),
                          );
                        }

                        if (recruitSnap.hasError || gameSnap.hasError) {
                          return PremiumEmptyState(
                            icon: Icons.error_outline,
                            title: 'שגיאה בטעינה',
                            message: ErrorHandlerService().handleException(
                              recruitSnap.error ?? gameSnap.error,
                              context: 'Community screen',
                            ),
                            action: ElevatedButton.icon(
                              onPressed: () => {},
                              icon: const Icon(Icons.refresh),
                              label: const Text('נסה שוב'),
                            ),
                          );
                        }

                        final games = gameSnap.data ?? [];
                        final items = <_CommunityItem>[
                          ...recruitingPosts
                              .map((p) => _CommunityItem.recruiting(p)),
                          ...games.map((g) => _CommunityItem.game(g)),
                        ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                        if (items.isEmpty) {
                          return PremiumEmptyState(
                            icon: Icons.group,
                            title: 'אין כרגע פעילות קהילתית',
                            message:
                                'כשיתפרסמו חיפושי שחקנים או משחקים פתוחים באזור, הם יופיעו כאן.',
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: items.length + 1, // +1 for Welcome Card
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return const CommunityWelcomeCard();
                            }
                            final item = items[index - 1];
                            return item.when(
                              recruiting: (post) => _RecruitingCard(post: post),
                              game: (game) => _GameCard(game: game),
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
      },
    );
  }
}

class _CommunityFiltersSheet extends StatefulWidget {
  final String? selectedRegion;
  final String? selectedCity;
  final void Function(String? region, String? city) onApply;

  const _CommunityFiltersSheet({
    required this.selectedRegion,
    required this.selectedCity,
    required this.onApply,
  });

  @override
  State<_CommunityFiltersSheet> createState() => _CommunityFiltersSheetState();
}

class _CommunityFiltersSheetState extends State<_CommunityFiltersSheet> {
  final List<String> _regions = ['צפון', 'מרכז', 'דרום', 'ירושלים'];
  String? _region;
  String? _city;

  @override
  void initState() {
    super.initState();
    _region = widget.selectedRegion;
    _city = widget.selectedCity;
  }

  @override
  Widget build(BuildContext context) {
    final cities = _region == null
        ? CityUtils.cities
        : CityUtils.cities
            .where((city) => CityUtils.getRegionForCity(city) == _region)
            .toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'סינון קהילה',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _region ?? '',
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'אזור'),
              items: [
                const DropdownMenuItem(value: '', child: Text('כל האזורים')),
                ..._regions.map(
                  (region) => DropdownMenuItem(
                    value: region,
                    child: Text(region),
                  ),
                ),
              ],
              onChanged: (value) {
                final nextRegion =
                    value == null || value.isEmpty ? null : value;
                String? nextCity = _city;
                if (nextRegion != null && nextCity != null) {
                  final cityRegion = CityUtils.getRegionForCity(nextCity);
                  if (cityRegion != nextRegion) {
                    nextCity = null;
                  }
                }
                setState(() {
                  _region = nextRegion;
                  _city = nextCity;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _city ?? '',
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'עיר'),
              items: [
                const DropdownMenuItem(value: '', child: Text('כל הערים')),
                ...cities.map(
                  (city) => DropdownMenuItem(
                    value: city,
                    child: Text(city),
                  ),
                ),
              ],
              onChanged: (value) {
                final nextCity = value == null || value.isEmpty ? null : value;
                setState(() {
                  _city = nextCity;
                  if (nextCity != null) {
                    _region = CityUtils.getRegionForCity(nextCity);
                  }
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: () => widget.onApply(null, null),
                  child: const Text('נקה סינון'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => widget.onApply(_region, _city),
                  child: const Text('החל'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecruitingCard extends StatelessWidget {
  final FeedPost post;
  const _RecruitingCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_search, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    post.hubName ?? 'חיפוש שחקנים',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text(
                  DateFormat('dd/MM').format(post.createdAt),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (post.content != null && post.content!.isNotEmpty)
              Text(post.content!),
            const SizedBox(height: 8),
            Row(
              children: [
                if (post.neededPlayers > 0) ...[
                  const Icon(Icons.group, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text('מחפשים ${post.neededPlayers} שחקנים'),
                ],
                if (post.city != null && post.city!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.location_city, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(post.city!, style: const TextStyle(color: Colors.grey)),
                ],
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    if (post.hubId.isNotEmpty) {
                      context.push('/hubs/${post.hubId}');
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('פרטי האב'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final Game game;
  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sports_soccer, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    game.denormalized.hubName ?? 'Unknown Hub',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text(
                  DateFormat('dd/MM').format(game.gameDate),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    game.denormalized.venueName ??
                        game.location ??
                        'מיקום לא ידוע',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => context.push('/games/${game.gameId}'),
              icon: const Icon(Icons.info_outline),
              label: const Text('פרטי משחק'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityItem {
  final FeedPost? recruiting;
  final Game? game;
  final DateTime timestamp;

  _CommunityItem.recruiting(this.recruiting)
      : game = null,
        timestamp = recruiting?.createdAt ?? DateTime.now();

  _CommunityItem.game(this.game)
      : recruiting = null,
        timestamp = game?.createdAt ?? game?.gameDate ?? DateTime.now();

  T when<T>({
    required T Function(FeedPost) recruiting,
    required T Function(Game) game,
  }) {
    if (this.recruiting != null) return recruiting(this.recruiting!);
    return game(this.game!);
  }
}
