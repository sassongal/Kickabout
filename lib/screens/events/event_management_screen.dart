import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/data/hub_events_repository.dart';
import 'package:kattrick/data/users_repository.dart';
import 'package:kattrick/data/hubs_repository.dart';
import 'package:kattrick/services/weather_service.dart';
import 'package:kattrick/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kattrick/theme/futuristic_theme.dart';
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
      final eventsRepo = HubEventsRepository();
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
    final eventsRepo = HubEventsRepository();
    final usersRepo = UsersRepository();
    final hubsRepo = HubsRepository();

    return FuturisticScaffold(
      title: 'ניהול אירוע',
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: FuturisticColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    event.title,
                    style: FuturisticTypography.heading2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Navigate to edit event screen
                    context.push(
                        '/hubs/${widget.hubId}/events/${widget.eventId}/edit');
                  },
                  tooltip: 'ערוך אירוע',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date & Time
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  // Wrap with Expanded to prevent overflow
                  child: Text(
                    dateFormat.format(event.eventDate),
                    style: FuturisticTypography.bodyLarge,
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
                      style: FuturisticTypography.bodyLarge,
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
                      color: FuturisticColors.primary,
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
                style: FuturisticTypography.bodyMedium,
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
                style: FuturisticTypography.labelSmall.copyWith(
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
                Icon(Icons.wb_sunny, color: FuturisticColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  // Wrap with Expanded to prevent overflow
                  child: Text(
                    'תחזית מזג אוויר',
                    style: FuturisticTypography.labelLarge,
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
                        style: FuturisticTypography.heading1,
                      ),
                      Text(
                        _weatherData!.condition,
                        style: FuturisticTypography.bodyMedium,
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
                          style: FuturisticTypography.bodyMedium,
                        ),
                        Text(
                          'מינימום: ${_weatherData!.minTemperature}°',
                          style: FuturisticTypography.bodyMedium,
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
                        style: FuturisticTypography.bodyMedium,
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
                Icon(Icons.people, color: FuturisticColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  // Wrap with Expanded to prevent overflow
                  child: Text(
                    'שחקנים רשומים (${players.length}/${event.maxParticipants})',
                    style: FuturisticTypography.labelLarge,
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
                          color: FuturisticColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          displayRating.toStringAsFixed(1),
                          style: FuturisticTypography.labelMedium.copyWith(
                            color: FuturisticColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsCard(HubEvent event, List<User> players, Hub? hub) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  event.teams.isNotEmpty ? Icons.groups : Icons.group_work,
                  color: event.teams.isNotEmpty
                      ? FuturisticColors.success
                      : FuturisticColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'כוחות',
                    style: FuturisticTypography.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Show teams if they exist
            if (event.teams.isNotEmpty) ...[
              ...event.teams.asMap().entries.map((entry) {
                final index = entry.key;
                final team = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getTeamColor(team.name).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              team.name,
                              style: FuturisticTypography.labelMedium.copyWith(
                                color: _getTeamColor(team.name),
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${team.playerIds.length} שחקנים)',
                            style: FuturisticTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: team.playerIds.map((playerId) {
                        return Chip(
                          label: Text(
                            playerId, // In real implementation, fetch player name
                            style: FuturisticTypography.bodySmall,
                          ),
                          backgroundColor:
                              _getTeamColor(team.name).withValues(alpha: 0.1),
                        );
                      }).toList(),
                    ),
                    if (index < event.teams.length - 1) const Divider(height: 24),
                  ],
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
                        color: FuturisticColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'לא נבחרו עוד כוחות',
                        style: FuturisticTypography.bodyLarge.copyWith(
                          color: FuturisticColors.textSecondary,
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
                            backgroundColor: FuturisticColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        )
                      else if (players.length < 6)
                        Text(
                          'נדרשים לפחות 6 שחקנים ליצירת כוחות',
                          style: FuturisticTypography.bodySmall.copyWith(
                            color: FuturisticColors.textSecondary,
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
        return FuturisticColors.primary;
      case 'ongoing':
        return FuturisticColors.success;
      case 'completed':
        return FuturisticColors.textSecondary;
      case 'cancelled':
        return FuturisticColors.error;
      default:
        return FuturisticColors.textSecondary;
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
      return FuturisticColors.error;
    } else if (weather.weatherCode >= 61 && weather.weatherCode <= 67) {
      return FuturisticColors.warning;
    } else if (weather.weatherCode >= 95) {
      return FuturisticColors.error;
    } else {
      return FuturisticColors.success;
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
    return colors[teamName] ?? FuturisticColors.primary;
  }
}
