import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/services/scouting_service.dart';
import 'package:kickadoor/widgets/player_avatar.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_card.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/models/notification.dart' as app_notification;

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
  String? _selectedPosition;
  double? _minRating;
  double? _maxRating;
  double? _maxDistanceKm;
  bool _availableOnly = true;
  bool _isLoading = false;
  List<ScoutingResult> _results = [];

  final List<String> _positions = [
    'Goalkeeper',
    'Defender',
    'Midfielder',
    'Forward',
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
                ? const FuturisticLoadingState(message: 'מחפש שחקנים מתאימים...')
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

            // Position filter
            DropdownButtonFormField<String>(
              initialValue: _selectedPosition,
              decoration: const InputDecoration(
                labelText: 'עמדה',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports_soccer),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('כל העמדות')),
                ..._positions.map((pos) => DropdownMenuItem(
                      value: pos,
                      child: Text(_getPositionName(pos)),
                    )),
              ],
              onChanged: (value) {
                setState(() => _selectedPosition = value);
              },
            ),
            const SizedBox(height: 16),

            // Rating range
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'דירוג מינימלי',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.star),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _minRating = value.isEmpty ? null : double.tryParse(value);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'דירוג מקסימלי',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.star),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _maxRating = value.isEmpty ? null : double.tryParse(value);
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Distance filter
            TextFormField(
              decoration: InputDecoration(
                labelText: 'מרחק מקסימלי (ק"מ)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _maxDistanceKm = value.isEmpty ? null : double.tryParse(value);
                });
              },
            ),
            const SizedBox(height: 16),

            // Available only checkbox
            CheckboxListTile(
              title: const Text('רק שחקנים זמינים'),
              value: _availableOnly,
              onChanged: (value) {
                setState(() => _availableOnly = value ?? true);
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
            Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(player.currentRankScore.toStringAsFixed(1)),
                const SizedBox(width: 16),
                Icon(Icons.sports_soccer, size: 16),
                const SizedBox(width: 4),
                Text(_getPositionName(player.preferredPosition)),
                if (result.distanceKm != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Text('${result.distanceKm!.toStringAsFixed(1)} ק"מ'),
                ],
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
              value: 'view_profile',
              child: Row(
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 8),
                  Text('צפה בפרופיל'),
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
              case 'view_profile':
                context.push('/profile/${player.uid}');
                break;
            }
          },
        ),
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
        requiredPosition: _selectedPosition,
        minRating: _minRating,
        maxRating: _maxRating,
        maxDistanceKm: _maxDistanceKm,
        availableOnly: _availableOnly,
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
}

