import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/services/scouting_service.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:kattrick/widgets/futuristic/futuristic_card.dart';
import 'package:kattrick/widgets/futuristic/loading_state.dart';
import 'package:kattrick/widgets/futuristic/empty_state.dart';
import 'package:kattrick/models/notification.dart' as app_notification;
import 'package:kattrick/models/models.dart';

/// Scouting Screen - AI-powered player discovery for Hub managers
class ScoutingScreen extends ConsumerStatefulWidget {
  final String hubId;
  final String? gameId; // Optional: if scouting for a specific game

  const ScoutingScreen({
    super.key,
    required this.hubId,
    this.gameId,
  });

  @override
  ConsumerState<ScoutingScreen> createState() => _ScoutingScreenState();
}

class _ScoutingScreenState extends ConsumerState<ScoutingScreen> {
  int _minAge = 18;
  int _maxAge = 45;
  AgeGroup?
      _selectedAgeGroup; // ✅ Filter by age group (alternative to age range)
  String? _selectedRegion;
  bool _activeOnly = true;
  bool _isLoading = false;
  List<ScoutingResult> _results = [];

  final List<String> _regions = [
    'צפון',
    'מרכז',
    'דרום',
    'ירושלים',
  ];

  @override
  Widget build(BuildContext context) {
    return FuturisticScaffold(
      title: 'גיוס שחקנים',
      body: Column(
        children: [
          // Filters
          _buildFilters(),

          // Search button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _searchPlayers,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(_isLoading ? 'מחפש...' : 'חפש שחקנים'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const FuturisticLoadingState(
                    message: 'מחפש שחקנים מתאימים...')
                : _results.isEmpty
                    ? FuturisticEmptyState(
                        icon: Icons.people_outline,
                        title: 'לא נמצאו שחקנים מתאימים',
                        message: 'נסה לשנות את הפילטרים',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final result = _results[index];
                          return _buildPlayerCard(result);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'פילטרים',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Age range filter
            Text(
              'טווח גילאים',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('גיל מינימלי: $_minAge'),
                      Slider(
                        value: _minAge.toDouble(),
                        min: 16,
                        max: 50,
                        divisions: 34,
                        label: '$_minAge',
                        onChanged: (value) {
                          setState(() {
                            _minAge = value.toInt();
                            if (_minAge > _maxAge) {
                              _maxAge = _minAge;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Text('גיל מקסימלי: $_maxAge'),
                      Slider(
                        value: _maxAge.toDouble(),
                        min: 16,
                        max: 50,
                        divisions: 34,
                        label: '$_maxAge',
                        onChanged: (value) {
                          setState(() {
                            _maxAge = value.toInt();
                            if (_maxAge < _minAge) {
                              _minAge = _maxAge;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ✅ Age Group Filter (alternative to age range)
            DropdownButtonFormField<AgeGroup>(
              value: _selectedAgeGroup,
              decoration: const InputDecoration(
                labelText: 'קבוצת גיל (אופציונלי)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cake_outlined),
                helperText: 'אם נבחר, יתעלם מטווח הגיל',
              ),
              items: [
                const DropdownMenuItem<AgeGroup>(
                  value: null,
                  child: Text('השתמש בטווח גיל'),
                ),
                ...AgeGroup.values.map((ageGroup) => DropdownMenuItem(
                      value: ageGroup,
                      child: Text(ageGroup.displayNameHe),
                    )),
              ],
              onChanged: (value) {
                setState(() => _selectedAgeGroup = value);
              },
            ),
            const SizedBox(height: 16),

            // Region filter
            DropdownButtonFormField<String>(
              initialValue: _selectedRegion,
              decoration: const InputDecoration(
                labelText: 'איזור מגורים',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('כל האיזורים')),
                ..._regions.map((region) => DropdownMenuItem(
                      value: region,
                      child: Text(region),
                    )),
              ],
              onChanged: (value) {
                setState(() => _selectedRegion = value);
              },
            ),
            const SizedBox(height: 16),

            // Active only checkbox
            CheckboxListTile(
              title: const Text('רק שחקנים פעילים'),
              value: _activeOnly,
              onChanged: (value) {
                setState(() => _activeOnly = value ?? true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(ScoutingResult result) {
    final player = result.player;

    return FuturisticCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: PlayerAvatar(user: player, radius: 28),
        title: Row(
          children: [
            Expanded(
              child: Text(
                player.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // Social media icons (if enabled and links exist)
            if (player.showSocialLinks) ...[
              if (player.facebookProfileUrl != null &&
                  player.facebookProfileUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.facebook,
                    size: 16,
                    color: const Color(0xFF1877F2),
                  ),
                ),
              if (player.instagramProfileUrl != null &&
                  player.instagramProfileUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: const Color(0xFFE4405F),
                  ),
                ),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getMatchScoreColor(result.matchScore),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${result.matchScore.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sports_soccer, size: 16),
                    const SizedBox(width: 4),
                    Text(_getPositionName(player.preferredPosition)),
                  ],
                ),
                // ✅ Age Group
                if (player.ageGroup != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cake_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text(player.ageGroup!.displayNameHe),
                    ],
                  ),
                if (result.distanceKm != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Text('${result.distanceKm!.toStringAsFixed(1)} ק"מ'),
                    ],
                  ),
              ],
            ),
            if (result.matchReasons.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: result.matchReasons.take(3).map((reason) {
                  return Chip(
                    label: Text(
                      reason,
                      style: const TextStyle(fontSize: 11),
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            if (widget.gameId != null)
              const PopupMenuItem(
                value: 'invite_game',
                child: Row(
                  children: [
                    Icon(Icons.sports_soccer, size: 20),
                    SizedBox(width: 8),
                    Text('הזמן למשחק'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'invite_hub',
              child: Row(
                children: [
                  Icon(Icons.group_add, size: 20),
                  SizedBox(width: 8),
                  Text('הזמן ל-Hub'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'view_player_card',
              child: Row(
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 8),
                  Text('כרטיס שחקן'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'invite_game':
                _inviteToGame(player.uid);
                break;
              case 'invite_hub':
                _inviteToHub(player.uid);
                break;
              case 'view_player_card':
                _showPlayerCard(context, player);
                break;
            }
          },
        ),
        onTap: () => _showPlayerCard(context, player),
      ),
    );
  }

  Future<void> _searchPlayers() async {
    setState(() {
      _isLoading = true;
      _results = [];
    });

    try {
      final scoutingService = ScoutingService(
        usersRepo: ref.read(usersRepositoryProvider),
        hubsRepo: ref.read(hubsRepositoryProvider),
        locationService: ref.read(locationServiceProvider),
      );

      final criteria = ScoutingCriteria(
        hubId: widget.hubId,
        minAge: _selectedAgeGroup == null
            ? _minAge
            : null, // ✅ Use age range only if ageGroup not selected
        maxAge: _selectedAgeGroup == null ? _maxAge : null,
        ageGroup: _selectedAgeGroup, // ✅ Pass age group filter
        region: _selectedRegion,
        activeOnly: _activeOnly,
        limit: 50,
      );

      final results = await scoutingService.scoutPlayers(criteria);

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בחיפוש: $e')),
        );
      }
    }
  }

  Future<void> _inviteToGame(String playerId) async {
    if (widget.gameId == null) return;

    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final usersRepo = ref.read(usersRepositoryProvider);
      final currentUserId = ref.read(currentUserIdProvider);

      if (currentUserId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('נא להתחבר')),
          );
        }
        return;
      }

      final game = await gamesRepo.getGame(widget.gameId!);
      final hub = await hubsRepo.getHub(widget.hubId);
      final currentUser = await usersRepo.getUser(currentUserId);
      final invitedPlayer = await usersRepo.getUser(playerId);

      if (game == null || hub == null || invitedPlayer == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('שגיאה: לא נמצאו פרטים')),
          );
        }
        return;
      }

      // Create invitation notification
      final notification = app_notification.Notification(
        notificationId: '',
        userId: playerId,
        type: 'game_invite',
        title: 'הזמנה למשחק!',
        body: '${currentUser?.name ?? 'מישהו'} מזמין אותך למשחק ב-${hub.name}',
        data: {
          'gameId': widget.gameId!,
          'hubId': widget.hubId,
          'type': 'game_invite',
          'inviterId': currentUserId,
        },
        createdAt: DateTime.now(),
      );

      final notificationsRepo = ref.read(notificationsRepositoryProvider);
      await notificationsRepo.createNotification(notification);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('הזמנה נשלחה ל-${invitedPlayer.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בשליחת הזמנה: $e')),
        );
      }
    }
  }

  Future<void> _inviteToHub(String playerId) async {
    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final usersRepo = ref.read(usersRepositoryProvider);
      final notificationsRepo = ref.read(notificationsRepositoryProvider);
      final currentUserId = ref.read(currentUserIdProvider);

      if (currentUserId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('נא להתחבר')),
          );
        }
        return;
      }

      final hub = await hubsRepo.getHub(widget.hubId);
      final currentUser = await usersRepo.getUser(currentUserId);
      final invitedPlayer = await usersRepo.getUser(playerId);

      if (hub == null || invitedPlayer == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('שגיאה: לא נמצאו פרטים')),
          );
        }
        return;
      }

      // Create hub invitation notification
      final notification = app_notification.Notification(
        notificationId: '',
        userId: playerId,
        type: 'hub_invite',
        title: 'הזמנה ל-Hub!',
        body: '${currentUser?.name ?? 'מישהו'} מזמין אותך להצטרף ל-${hub.name}',
        data: {
          'hubId': widget.hubId,
          'type': 'hub_invite',
          'inviterId': currentUserId,
        },
        createdAt: DateTime.now(),
      );

      await notificationsRepo.createNotification(notification);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('הזמנה נשלחה ל-${invitedPlayer.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בשליחת הזמנה: $e')),
        );
      }
    }
  }

  Color _getMatchScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.grey;
  }

  String _getPositionName(String position) {
    const positionNames = {
      'Goalkeeper': 'שוער',
      'Defender': 'מגן',
      'Midfielder': 'קשר',
      'Forward': 'חלוץ',
    };
    return positionNames[position] ?? position;
  }

  void _showPlayerCard(BuildContext context, User player) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          _PlayerCardSheet(player: player, hubId: widget.hubId),
    );
  }
}

/// Player card sheet - shows detailed player information
class _PlayerCardSheet extends ConsumerWidget {
  final User player;
  final String hubId;

  const _PlayerCardSheet({
    required this.player,
    required this.hubId,
  });

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    final monthDiff = now.month - birthDate.month;
    final dayDiff = now.day - birthDate.day;
    if (monthDiff < 0 || (monthDiff == 0 && dayDiff < 0)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubsRepo = ref.read(hubsRepositoryProvider);
    final age = _calculateAge(player.birthDate);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'כרטיס שחקן',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),

                // Profile picture and name
                Center(
                  child: Column(
                    children: [
                      PlayerAvatar(user: player, radius: 60),
                      const SizedBox(height: 16),
                      Text(
                        player.firstName != null && player.lastName != null
                            ? '${player.firstName} ${player.lastName}'
                            : player.name,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Player details
                _buildDetailRow(
                  context,
                  Icons.person,
                  'שם מלא',
                  player.firstName != null && player.lastName != null
                      ? '${player.firstName} ${player.lastName}'
                      : player.name,
                ),
                if (player.lastName != null && player.firstName != null)
                  _buildDetailRow(
                    context,
                    Icons.badge,
                    'שם משפחה',
                    player.lastName!,
                  ),
                if (player.region != null)
                  _buildDetailRow(
                    context,
                    Icons.location_on,
                    'איזור מגורים',
                    player.region!,
                  ),
                if (player.phoneNumber != null &&
                    !player.privacySettings['hidePhone']!)
                  _buildDetailRow(
                    context,
                    Icons.phone,
                    'טלפון',
                    player.phoneNumber!,
                  ),
                if (!player.privacySettings['hideEmail']!)
                  _buildDetailRow(
                    context,
                    Icons.email,
                    'מייל',
                    player.email,
                  ),
                if (age > 0)
                  _buildDetailRow(
                    context,
                    Icons.cake,
                    'גיל',
                    '$age',
                  ),

                // Hubs
                if (player.hubIds.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'האבים',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<Hub>>(
                    future: Future.wait(
                      player.hubIds.map((hubId) => hubsRepo.getHub(hubId)),
                    ).then((hubs) => hubs.whereType<Hub>().toList()),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      final hubs = snapshot.data ?? [];
                      if (hubs.isEmpty) {
                        return const Text('אין האבים');
                      }
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: hubs.map((hub) {
                          return Chip(
                            label: Text(hub.name),
                            avatar: const Icon(Icons.group, size: 18),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],

                // Favorite team
                if (player.favoriteTeamId != null) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    context,
                    Icons.favorite,
                    'קבוצה אהודה',
                    'ID: ${player.favoriteTeamId}',
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
