import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/core/providers/repositories_providers.dart';
import 'package:kattrick/core/providers/auth_providers.dart';
import 'package:kattrick/core/providers/complex_providers.dart';
import 'package:kattrick/features/profile/data/repositories/users_repository.dart';
import 'package:kattrick/services/weather_service.dart';
import 'package:kattrick/widgets/common/premium_scaffold.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Event Management Screen - displays event details, registered players,
/// weather forecast, and team generation functionality
class EventManagementScreen extends ConsumerStatefulWidget {
  final String hubId;
  final String eventId;

  const EventManagementScreen({
    super.key,
    required this.hubId,
    required this.eventId,
  });

  @override
  ConsumerState<EventManagementScreen> createState() =>
      _EventManagementScreenState();
}

class _EventManagementScreenState extends ConsumerState<EventManagementScreen> {
  final _weatherService = WeatherService();
  WeatherData? _weatherData;
  bool _isLoadingWeather = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() => _isLoadingWeather = true);

    try {
      final eventsRepo = ref.read(hubEventsRepositoryProvider);
      final event = await eventsRepo.getHubEvent(widget.hubId, widget.eventId);

      if (event?.locationPoint != null) {
        final weather = await _weatherService.getWeatherForDate(
          latitude: event!.locationPoint!.latitude,
          longitude: event.locationPoint!.longitude,
          date: event.eventDate,
        );

        if (mounted) {
          setState(() {
            _weatherData = weather;
            _isLoadingWeather = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoadingWeather = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingWeather = false);
      }
    }
  }

  void _navigateToTeamGenerator(List<User> players) {
    if (players.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נדרשים לפחות 6 שחקנים ליצירת קבוצות')),
      );
      return;
    }

    // Navigate to team generator config screen
    context.go('/hubs/${widget.hubId}/events/${widget.eventId}/team-generator/config');
  }

  Future<void> _navigateToLocation(double latitude, double longitude) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('לא ניתן לפתוח ניווט')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsRepo = ref.watch(hubEventsRepositoryProvider);
    final usersRepo = ref.watch(usersRepositoryProvider);
    final hubsRepo = ref.watch(hubsRepositoryProvider);

    return PremiumScaffold(
      title: 'ניהול אירוע',
      actions: [
        // Add button to navigate to live match if event is ongoing
        StreamBuilder<HubEvent?>(
          stream: eventsRepo.watchHubEvent(widget.hubId, widget.eventId),
          builder: (context, snapshot) {
            final event = snapshot.data;
            final isEventOngoing = event != null &&
                (event.isStarted || event.status == 'ongoing');
            
            if (isEventOngoing) {
              return IconButton(
                icon: const Icon(Icons.sports_soccer),
                tooltip: 'מסך המשחק החי',
                onPressed: () {
                  context.push(
                      '/hubs/${widget.hubId}/events/${widget.eventId}/live');
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
      body: StreamBuilder<HubEvent?>(
        stream: eventsRepo.watchHubEvent(widget.hubId, widget.eventId),
        builder: (context, eventSnapshot) {
          if (eventSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final event = eventSnapshot.data;
          if (event == null) {
            return const Center(child: Text('אירוע לא נמצא'));
          }

          return FutureBuilder<Hub?>(
            future: hubsRepo.getHub(widget.hubId),
            builder: (context, hubSnapshot) {
              final hub = hubSnapshot.data;

              return FutureBuilder<List<User>>(
                future: _fetchRegisteredPlayers(
                    event.registeredPlayerIds, usersRepo),
                builder: (context, playersSnapshot) {
                  final players = playersSnapshot.data ?? [];

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Event Details Card
                        _buildEventDetailsCard(event),
                        const SizedBox(height: 16),

                        // Weather Forecast Card
                        if (event.locationPoint != null)
                          _buildWeatherCard(event),
                        const SizedBox(height: 16),

                        // Registered Players Card
                        _buildRegisteredPlayersCard(event, players, hub),
                        const SizedBox(height: 16),

                        // Teams Section - always show
                        _buildTeamsCard(event, players, hub),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEventDetailsCard(HubEvent event) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'he');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: PremiumColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.title,
                    style: PremiumTypography.heading3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    context.push(
                        '/hubs/${widget.hubId}/events/${widget.eventId}/edit');
                  },
                  tooltip: 'ערוך אירוע',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date & Time
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  // Wrap with Expanded to prevent overflow
                  child: Text(
                    dateFormat.format(event.eventDate),
                    style: PremiumTypography.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Location
            if (event.location != null) ...[
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location!,
                      style: PremiumTypography.bodyLarge,
                    ),
                  ),
                  if (event.locationPoint != null)
                    IconButton(
                      icon: const Icon(Icons.navigation),
                      onPressed: () => _navigateToLocation(
                        event.locationPoint!.latitude,
                        event.locationPoint!.longitude,
                      ),
                      tooltip: 'ניווט למיקום',
                      color: PremiumColors.primary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Description
            if (event.description != null && event.description!.isNotEmpty) ...[
              const Divider(),
              Text(
                event.description!,
                style: PremiumTypography.bodyMedium,
              ),
            ],

            // Event Status
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(event.status).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(event.status),
                style: PremiumTypography.labelSmall.copyWith(
                  color: _getStatusColor(event.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(HubEvent event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wb_sunny, color: PremiumColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  // Wrap with Expanded to prevent overflow
                  child: Text(
                    'תחזית מזג אוויר',
                    style: PremiumTypography.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingWeather)
              const Center(child: CircularProgressIndicator())
            else if (_weatherData != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${_weatherData!.temperature}°',
                        style: PremiumTypography.heading1,
                      ),
                      Text(
                        _weatherData!.condition,
                        style: PremiumTypography.bodyMedium,
                      ),
                    ],
                  ),
                  if (_weatherData!.minTemperature != null &&
                      _weatherData!.maxTemperature != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'מקסימום: ${_weatherData!.maxTemperature}°',
                          style: PremiumTypography.bodyMedium,
                        ),
                        Text(
                          'מינימום: ${_weatherData!.minTemperature}°',
                          style: PremiumTypography.bodyMedium,
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getWeatherRecommendationColor(_weatherData!)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getWeatherIcon(_weatherData!),
                      color: _getWeatherRecommendationColor(_weatherData!),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _weatherData!.summary,
                        style: PremiumTypography.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              const Text('לא ניתן לטעון תחזית מזג אוויר'),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisteredPlayersCard(
      HubEvent event, List<User> players, Hub? hub) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: PremiumColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  // Wrap with Expanded to prevent overflow
                  child: Text(
                    'שחקנים רשומים (${players.length}/${event.maxParticipants})',
                    style: PremiumTypography.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (players.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('אין שחקנים רשומים'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: players.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final player = players[index];
                  // Use system rating for display (managerRating would require async fetch)
                  final displayRating = player.currentRankScore;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: player.photoUrl != null
                          ? NetworkImage(player.photoUrl!)
                          : null,
                      child: player.photoUrl == null
                          ? Text(player.name[0].toUpperCase())
                          : null,
                    ),
                    title: Text(player.name),
                    subtitle: player.city != null ? Text(player.city!) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: PremiumColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          displayRating.toStringAsFixed(1),
                          style: PremiumTypography.labelMedium.copyWith(
                            color: PremiumColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // Add recruiting post button if user has permission and event has spots
            const SizedBox(height: 16),
            _buildRecruitingPostButton(event, players),
          ],
        ),
      ),
    );
  }

  Widget _buildRecruitingPostButton(HubEvent event, List<User> players) {
    final currentUserId = ref.watch(currentUserIdProvider);
    if (currentUserId == null) return const SizedBox.shrink();

    final availableSpots = event.maxParticipants - players.length;
    final isUpcoming = event.status == 'upcoming';

    // Check permissions
    final hubPermissionsAsync = ref.watch(
      hubPermissionsProvider((hubId: widget.hubId, userId: currentUserId))
    );

    return hubPermissionsAsync.when(
      data: (permissions) {
        // Only show if user can create posts, event is upcoming, and has spots
        if (!permissions.canCreatePosts || !isUpcoming || availableSpots <= 0) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              context.push('/hubs/${widget.hubId}/create-recruiting-post');
            },
            icon: const Icon(Icons.group_add),
            label: Text('מחפש $availableSpots שחקנים'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildTeamsCard(HubEvent event, List<User> players, Hub? hub) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  event.teams.isNotEmpty ? Icons.groups : Icons.group_work,
                  color: event.teams.isNotEmpty
                      ? PremiumColors.success
                      : PremiumColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'כוחות',
                    style: PremiumTypography.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Show "Start Session" or "Enter Session" button if teams exist and game created
            if (event.teams.isNotEmpty && event.gameId != null) ...[
              StreamBuilder<Game?>(
                stream: ref.read(gamesRepositoryProvider).watchGame(event.gameId!),
                builder: (context, gameSnapshot) {
                  final game = gameSnapshot.data;

                  // Check if session is active
                  final isSessionActive = game?.session.isActive ?? false;
                  final hasSessionEnded = game?.session.sessionEndedAt != null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to GameSessionScreen
                          context.push(
                            '/hubs/${widget.hubId}/events/${widget.eventId}/game-session',
                          );
                        },
                        icon: Icon(
                          isSessionActive
                            ? Icons.sports_soccer
                            : hasSessionEnded
                              ? Icons.emoji_events
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          isSessionActive
                            ? 'כנס לסשן פעיל'
                            : hasSessionEnded
                              ? 'צפה בסיכום'
                              : 'התחל סשן',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          backgroundColor: isSessionActive
                            ? Colors.green
                            : hasSessionEnded
                              ? Colors.amber
                              : PremiumColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],

            // Show teams if they exist - Compact display with player names
            if (event.teams.isNotEmpty) ...[
              ...event.teams.asMap().entries.map((entry) {
                final index = entry.key;
                final team = entry.value;
                final teamColor = _getTeamColor(team.name);
                
                // Get player names from the players list
                final teamPlayers = players.where((p) => team.playerIds.contains(p.uid)).toList();

                return Padding(
                  padding: EdgeInsets.only(bottom: index < event.teams.length - 1 ? 16 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Team header with color indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: teamColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: teamColor.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: teamColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                team.name,
                                style: PremiumTypography.labelLarge.copyWith(
                                  color: teamColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${team.playerIds.length} שחקנים',
                              style: PremiumTypography.bodySmall.copyWith(
                                color: PremiumColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Player names list
                      ...teamPlayers.map((player) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: teamColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  player.name,
                                  style: PremiumTypography.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ]
            // Show message if no teams selected yet
            else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 48,
                        color: PremiumColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'לא נבחרו עוד כוחות',
                        style: PremiumTypography.bodyLarge.copyWith(
                          color: PremiumColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Show generate teams button if enough players
                      if (hub != null && players.length >= 6)
                        ElevatedButton.icon(
                          onPressed: () => _navigateToTeamGenerator(players),
                          icon: const Icon(Icons.group_work),
                          label: const Text('יצירת כוחות'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 24,
                            ),
                            backgroundColor: PremiumColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        )
                      else if (players.length < 6)
                        Text(
                          'נדרשים לפחות 6 שחקנים ליצירת כוחות',
                          style: PremiumTypography.bodySmall.copyWith(
                            color: PremiumColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<List<User>> _fetchRegisteredPlayers(
    List<String> playerIds,
    UsersRepository usersRepo,
  ) async {
    final players = <User>[];
    for (final playerId in playerIds) {
      final user = await usersRepo.getUser(playerId);
      if (user != null) {
        players.add(user);
      }
    }
    return players;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'upcoming':
        return PremiumColors.primary;
      case 'ongoing':
        return PremiumColors.success;
      case 'completed':
        return PremiumColors.textSecondary;
      case 'cancelled':
        return PremiumColors.error;
      default:
        return PremiumColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'upcoming':
        return 'קרוב';
      case 'ongoing':
        return 'בעיצומו';
      case 'completed':
        return 'הסתיים';
      case 'cancelled':
        return 'בוטל';
      default:
        return status;
    }
  }

  Color _getWeatherRecommendationColor(WeatherData weather) {
    if (weather.temperature > 30 || weather.temperature < 5) {
      return PremiumColors.error;
    } else if (weather.weatherCode >= 61 && weather.weatherCode <= 67) {
      return PremiumColors.warning;
    } else if (weather.weatherCode >= 95) {
      return PremiumColors.error;
    } else {
      return PremiumColors.success;
    }
  }

  IconData _getWeatherIcon(WeatherData weather) {
    if (weather.weatherCode >= 95) {
      return Icons.thunderstorm;
    } else if (weather.weatherCode >= 71) {
      return Icons.ac_unit;
    } else if (weather.weatherCode >= 61) {
      return Icons.water_drop;
    } else if (weather.weatherCode == 0) {
      return Icons.wb_sunny;
    } else {
      return Icons.cloud;
    }
  }

  Color _getTeamColor(String teamName) {
    final colors = {
      'Blue': Colors.blue,
      'Red': Colors.red,
      'Green': Colors.green,
      'Yellow': Colors.amber,
      'Orange': Colors.orange,
      'Purple': Colors.purple,
      'Pink': Colors.pink,
      'Cyan': Colors.cyan,
    };
    return colors[teamName] ?? PremiumColors.primary;
  }
}
