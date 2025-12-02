import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/widgets/futuristic/empty_state.dart';
import 'package:kattrick/widgets/futuristic/skeleton_loader.dart';
import 'package:kattrick/services/error_handler_service.dart';
import 'package:kattrick/services/cache_service.dart';

/// Community Activity Feed Screen
/// Displays public games and events from all hubs
class CommunityActivityFeedScreen extends ConsumerStatefulWidget {
  const CommunityActivityFeedScreen({super.key});

  @override
  ConsumerState<CommunityActivityFeedScreen> createState() =>
      _CommunityActivityFeedScreenState();
}

class _CommunityActivityFeedScreenState
    extends ConsumerState<CommunityActivityFeedScreen> {
  // Filters
  String? _selectedHubId;
  String? _selectedRegion;
  String? _selectedGameType;
  DateTime? _startDate;
  DateTime? _endDate;
  String _contentType = 'all'; // 'all', 'games', 'events'

  // Pagination state
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 20; // Load 20 items at a time
  bool _isLoadingMore = false;
  bool _hasMoreGames = true;
  List<Game> _loadedGames = [];

  @override
  void initState() {
    super.initState();
    // Listen to scroll position for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more when user scrolls to 80% of the list
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Load more will be handled in the stream builders
    // This is just a trigger
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    });
  }

  void _resetPagination() {
    if (mounted) {
      setState(() {
        _loadedGames = [];
        _hasMoreGames = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gamesRepo = ref.watch(gamesRepositoryProvider);
    final eventsRepo = ref.watch(hubEventsRepositoryProvider);

    // OPTIMIZED: Use pagination - load 20 items at a time
    // Get games stream with pagination
    final gamesStream = gamesRepo.watchPublicCompletedGames(
      limit: _pageSize,
      hubId: _selectedHubId,
      region: _selectedRegion,
      startDate: _startDate,
      endDate: _endDate,
    );

    // Get events stream with pagination
    final eventsStream = eventsRepo.watchPublicEvents(
      limit: _pageSize,
      hubId: _selectedHubId,
      region: _selectedRegion,
      startDate: _startDate,
      endDate: _endDate,
    );

    return AppScaffold(
      title: 'פעילות קהילתית',
      showBottomNav: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilters,
          tooltip: 'סינונים',
        ),
      ],
      body: Column(
        children: [
          // Content type selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('הכל'),
                    selected: _contentType == 'all',
                    onSelected: (selected) {
                      if (selected) setState(() => _contentType = 'all');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('משחקים'),
                    selected: _contentType == 'games',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _contentType = 'games';
                          _resetPagination();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('אירועים'),
                    selected: _contentType == 'events',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _contentType = 'events';
                          _resetPagination();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Feed content
          Expanded(
            child: _contentType == 'games'
                ? _buildGamesFeed(gamesStream)
                : _contentType == 'events'
                    ? _buildEventsFeed(eventsStream)
                    : _buildCombinedFeed(gamesStream, eventsStream),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesFeed(Stream<List<Game>> gamesStream) {
    // Try to load from cache first
    final cacheKey = CacheKeys.publicGames(region: _selectedRegion);
    final cachedGames = CacheService().get<List<Game>>(cacheKey);

    return StreamBuilder<List<Game>>(
      stream: gamesStream,
      initialData: cachedGames, // Use cached data as initial data
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) => const SkeletonGameCard(),
          );
        }

        if (snapshot.hasError) {
          return FuturisticEmptyState(
            icon: Icons.error_outline,
            title: 'שגיאה בטעינת משחקים',
            message: ErrorHandlerService().handleException(
              snapshot.error,
              context: 'Community activity feed',
            ),
          );
        }

        final games = snapshot.data ?? [];

        if (games.isEmpty) {
          return FuturisticEmptyState(
            icon: Icons.sports_soccer_outlined,
            title: 'אין משחקים',
            message: 'לא נמצאו משחקים ציבוריים',
          );
        }

        // Update loaded games directly (no postFrameCallback to avoid infinite loops)
        // Only update if data actually changed
        if (games.isNotEmpty) {
          final firstGameId = games.first.gameId;
          if (_loadedGames.isEmpty ||
              _loadedGames.first.gameId != firstGameId) {
            // Use Future.microtask to update state after current build
            Future.microtask(() {
              if (mounted) {
                setState(() {
                  _loadedGames = games;
                  _hasMoreGames = games.length >= _pageSize;
                });
              }
            });
          }
        }

        // Use games directly if _loadedGames is empty (initial load)
        final displayGames = _loadedGames.isEmpty ? games : _loadedGames;

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount:
              displayGames.length + (_hasMoreGames && _isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == displayGames.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final game = displayGames[index];
            return _GameFeedCard(game: game);
          },
        );
      },
    );
  }

  Widget _buildEventsFeed(Stream<List<HubEvent>> eventsStream) {
    return StreamBuilder<List<HubEvent>>(
      stream: eventsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) => const SkeletonGameCard(),
          );
        }

        if (snapshot.hasError) {
          return FuturisticEmptyState(
            icon: Icons.error_outline,
            title: 'שגיאה בטעינת אירועים',
            message: ErrorHandlerService().handleException(
              snapshot.error,
              context: 'Community activity feed',
            ),
          );
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return FuturisticEmptyState(
            icon: Icons.event_outlined,
            title: 'אין אירועים',
            message: 'לא נמצאו אירועים ציבוריים',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _EventFeedCard(event: event);
          },
        );
      },
    );
  }

  Widget _buildCombinedFeed(
    Stream<List<Game>> gamesStream,
    Stream<List<HubEvent>> eventsStream,
  ) {
    return StreamBuilder<List<Game>>(
      stream: gamesStream,
      builder: (context, gamesSnapshot) {
        return StreamBuilder<List<HubEvent>>(
          stream: eventsStream,
          builder: (context, eventsSnapshot) {
            if (gamesSnapshot.connectionState == ConnectionState.waiting ||
                eventsSnapshot.connectionState == ConnectionState.waiting) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (context, index) => const SkeletonGameCard(),
              );
            }

            final games = gamesSnapshot.data ?? [];
            final events = eventsSnapshot.data ?? [];

            // Combine and sort by date
            final items = <_FeedItem>[];
            items.addAll(games.map((g) => _FeedItem.game(g)));
            items.addAll(events.map((e) => _FeedItem.event(e)));
            items.sort((a, b) {
              final aDate = a.isGame ? a.game!.gameDate : a.event!.eventDate;
              final bDate = b.isGame ? b.game!.gameDate : b.event!.eventDate;
              return bDate.compareTo(aDate); // Newest first
            });

            if (items.isEmpty) {
              return FuturisticEmptyState(
                icon: Icons.timeline_outlined,
                title: 'אין פעילות',
                message: 'לא נמצאה פעילות ציבורית',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                if (item.isGame) {
                  return _GameFeedCard(game: item.game!);
                } else {
                  return _EventFeedCard(event: item.event!);
                }
              },
            );
          },
        );
      },
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FiltersSheet(
        selectedHubId: _selectedHubId,
        selectedRegion: _selectedRegion,
        selectedGameType: _selectedGameType,
        startDate: _startDate,
        endDate: _endDate,
        onApply: (hubId, region, gameType, startDate, endDate) {
          setState(() {
            _selectedHubId = hubId;
            _selectedRegion = region;
            _selectedGameType = gameType;
            _startDate = startDate;
            _endDate = endDate;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Feed item wrapper
class _FeedItem {
  final Game? game;
  final HubEvent? event;

  _FeedItem.game(this.game) : event = null;
  _FeedItem.event(this.event) : game = null;

  bool get isGame => game != null;
}

/// Game feed card with unique design
class _GameFeedCard extends ConsumerWidget {
  final Game game;

  const _GameFeedCard({required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubsRepo = ref.read(hubsRepositoryProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score - LARGE and prominent
            if (game.legacyTeamAScore != null && game.legacyTeamBScore != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${game.legacyTeamAScore}',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '-',
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                  Text(
                    '${game.legacyTeamBScore}',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            if (game.legacyTeamAScore != null && game.legacyTeamBScore != null)
              const SizedBox(height: 16),

            // Hub name - medium size
            FutureBuilder<Hub?>(
              future: game.hubId != null
                  ? hubsRepo.getHub(game.hubId!)
                  : Future.value(null),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Text(
                    snapshot.data!.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 8),

            // Date - small
            Text(
              DateFormat('dd/MM/yyyy HH:mm', 'he').format(game.gameDate),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 8),

            // Venue/Location - small - using denormalized data
            if (game.venueName != null && game.venueName!.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    game.venueName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ],
              )
            else if (game.location != null && game.location!.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    game.location!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            const SizedBox(height: 12),

            // Goal scorers - small list (like football results) - using denormalized data
            if (game.goalScorerNames.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: game.goalScorerNames.map((fullName) {
                  final nameParts = fullName.split(' ');
                  final firstName =
                      nameParts.isNotEmpty ? nameParts.first : fullName;
                  final lastName = nameParts.length > 1
                      ? nameParts.sublist(1).join(' ')
                      : '';
                  return Text(
                    '$firstName $lastName',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                  );
                }).toList(),
              ),

            // MVP - bottom left with star icon - using denormalized data
            if (game.mvpPlayerName != null && game.mvpPlayerName!.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 18,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Builder(
                      builder: (context) {
                        final nameParts = game.mvpPlayerName!.split(' ');
                        final firstName = nameParts.isNotEmpty
                            ? nameParts.first
                            : game.mvpPlayerName!;
                        final lastName = nameParts.length > 1
                            ? nameParts.sublist(1).join(' ')
                            : '';
                        return Text(
                          '$firstName $lastName',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Event feed card
class _EventFeedCard extends ConsumerWidget {
  final HubEvent event;

  const _EventFeedCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubsRepo = ref.read(hubsRepositoryProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event title - large
            Text(
              event.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            // Hub name - medium
            FutureBuilder<Hub?>(
              future: hubsRepo.getHub(event.hubId),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Text(
                    snapshot.data!.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 8),

            // Date and time - small
            Text(
              DateFormat('dd/MM/yyyy HH:mm', 'he').format(event.eventDate),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 8),

            // Location - small
            if (event.location != null && event.location!.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    event.location!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            const SizedBox(height: 8),

            // Registered players count
            Text(
              '${event.registeredPlayerIds.length}/${event.maxParticipants} נרשמו',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filters bottom sheet
class _FiltersSheet extends StatefulWidget {
  final String? selectedHubId;
  final String? selectedRegion;
  final String? selectedGameType;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(String?, String?, String?, DateTime?, DateTime?) onApply;

  const _FiltersSheet({
    required this.selectedHubId,
    required this.selectedRegion,
    required this.selectedGameType,
    required this.startDate,
    required this.endDate,
    required this.onApply,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late String? _hubId;
  late String? _region;
  late String? _gameType;
  late DateTime? _startDate;
  late DateTime? _endDate;

  final List<String> _regions = ['צפון', 'מרכז', 'דרום', 'ירושלים'];
  final List<String> _gameTypes = [
    '3v3',
    '4v4',
    '5v5',
    '6v6',
    '7v7',
    '8v8',
    '9v9',
    '10v10',
    '11v11'
  ];

  @override
  void initState() {
    super.initState();
    _hubId = widget.selectedHubId;
    _region = widget.selectedRegion;
    _gameType = widget.selectedGameType;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'סינונים',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Region filter
          DropdownButtonFormField<String>(
            initialValue: _region,
            decoration: const InputDecoration(
              labelText: 'איזור',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('כל האיזורים'),
              ),
              ..._regions.map((r) => DropdownMenuItem<String>(
                    value: r,
                    child: Text(r),
                  )),
            ],
            onChanged: (value) => setState(() => _region = value),
          ),
          const SizedBox(height: 16),

          // Game type filter
          DropdownButtonFormField<String>(
            initialValue: _gameType,
            decoration: const InputDecoration(
              labelText: 'סוג משחק',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('כל הסוגים'),
              ),
              ..._gameTypes.map((t) => DropdownMenuItem<String>(
                    value: t,
                    child: Text(t),
                  )),
            ],
            onChanged: (value) => setState(() => _gameType = value),
          ),
          const SizedBox(height: 16),

          // Date range
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      locale: const Locale('he'),
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'מתאריך',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _startDate != null
                          ? DateFormat('dd/MM/yyyy', 'he').format(_startDate!)
                          : 'בחר תאריך',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      locale: const Locale('he'),
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'עד תאריך',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _endDate != null
                          ? DateFormat('dd/MM/yyyy', 'he').format(_endDate!)
                          : 'בחר תאריך',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Apply button
          ElevatedButton(
            onPressed: () {
              widget.onApply(_hubId, _region, _gameType, _startDate, _endDate);
            },
            child: const Text('החל סינונים'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _hubId = null;
                _region = null;
                _gameType = null;
                _startDate = null;
                _endDate = null;
              });
              widget.onApply(null, null, null, null, null);
              Navigator.pop(context);
            },
            child: const Text('נקה סינונים'),
          ),
        ],
      ),
    );
  }
}
