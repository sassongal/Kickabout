import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/common/premium_scaffold.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/widgets/premium/loading_state.dart';
import 'package:kattrick/widgets/premium/empty_state.dart';

class HubStatsScreen extends ConsumerStatefulWidget {
  final String hubId;
  final String playerId;

  const HubStatsScreen({
    super.key,
    required this.hubId,
    required this.playerId,
  });

  @override
  ConsumerState<HubStatsScreen> createState() => _HubStatsScreenState();
}

class _HubStatsScreenState extends ConsumerState<HubStatsScreen> {
  bool _isLoading = true;
  Hub? _hub;
  List<Game> _games = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final hubsRepo = ref.read(hubsRepositoryProvider);
      final gamesRepo = ref.read(gamesRepositoryProvider);

      // Fetch Hub
      final hub = await hubsRepo.getHub(widget.hubId);
      if (hub == null) {
        throw Exception('Hub not found');
      }

      // Fetch Games
      final games =
          await gamesRepo.getPlayerGamesInHub(widget.hubId, widget.playerId);

      if (mounted) {
        setState(() {
          _hub = hub;
          _games = games;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _calculateStats() {
    int gamesPlayed = _games.length;
    int wins = 0;
    int goals = 0;
    int mvps = 0;
    int draws = 0;
    int losses = 0;

    for (final game in _games) {
      // Count Goals
      goals += game.denormalized.goalScorerIds
          .where((id) => id == widget.playerId)
          .length;

      // Count MVPs
      if (game.denormalized.mvpPlayerId == widget.playerId) {
        mvps++;
      }

      // Determine Result
      final teamAScore = game.session.legacyTeamAScore ?? 0;
      final teamBScore = game.session.legacyTeamBScore ?? 0;

      // Find player's team
      String playerTeamId = 'teamA'; // Default
      if (game.teams.isNotEmpty) {
        final teamA = game.teams[0];
        final teamB = game.teams.length > 1 ? game.teams[1] : null;

        if (teamA.playerIds.contains(widget.playerId)) {
          playerTeamId = teamA.teamId;
        } else if (teamB != null && teamB.playerIds.contains(widget.playerId)) {
          playerTeamId = teamB.teamId;
        }
      }

      // Determine Winner
      String? winningTeamId;
      if (teamAScore > teamBScore) {
        winningTeamId = game.teams.isNotEmpty ? game.teams[0].teamId : 'teamA';
      } else if (teamBScore > teamAScore) {
        winningTeamId = game.teams.length > 1 ? game.teams[1].teamId : 'teamB';
      }

      if (winningTeamId == null) {
        draws++;
      } else if (winningTeamId == playerTeamId) {
        wins++;
      } else {
        losses++;
      }
    }

    return {
      'gamesPlayed': gamesPlayed,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'goals': goals,
      'mvps': mvps,
      'winRate': gamesPlayed > 0
          ? (wins / gamesPlayed * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const PremiumScaffold(
        title: 'סטטיסטיקות האב',
        body: PremiumLoadingState(message: 'מחשב נתונים...'),
      );
    }

    if (_error != null || _hub == null) {
      return PremiumScaffold(
        title: 'שגיאה',
        body: PremiumEmptyState(
          icon: Icons.error_outline,
          title: 'שגיאה בטעינת נתונים',
          message: _error ?? 'האב לא נמצא',
          action: ElevatedButton(
            onPressed: _loadData,
            child: const Text('נסה שוב'),
          ),
        ),
      );
    }

    final stats = _calculateStats();

    return PremiumScaffold(
      title: _hub!.name,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Hub Header
            Center(
              child: Column(
                children: [
                  Hero(
                    tag: 'hub_avatar_${_hub!.hubId}',
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor:
                          PremiumColors.primary.withOpacity(0.2),
                      child: Icon(
                        Icons.group,
                        size: 40,
                        color: PremiumColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'סטטיסטיקות אישיות',
                    style: PremiumTypography.heading3,
                  ),
                  Text(
                    _hub!.name,
                    style: PremiumTypography.bodyMedium.copyWith(
                      color: PremiumColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Main Stats Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  'משחקים',
                  stats['gamesPlayed'].toString(),
                  Icons.sports_soccer,
                  PremiumColors.primary,
                ),
                _buildStatCard(
                  'שערים',
                  stats['goals'].toString(),
                  Icons.sports_soccer, // different icon?
                  PremiumColors.secondary,
                ),
                _buildStatCard(
                  'ניצחונות',
                  stats['wins'].toString(),
                  Icons.emoji_events,
                  Colors.green,
                ),
                _buildStatCard(
                  'MVP',
                  stats['mvps'].toString(),
                  Icons.star,
                  Colors.amber,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Win Rate Card
            PremiumCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'אחוזי הצלחה',
                        style: PremiumTypography.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stats['winRate']}%',
                        style: PremiumTypography.heading2.copyWith(
                          color: PremiumColors.accent,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: CircularProgressIndicator(
                      value: double.parse(stats['winRate']) / 100,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      color: PremiumColors.accent,
                      strokeWidth: 8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Detailed Record
            PremiumCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRecordItem('ניצחונות', stats['wins'], Colors.green),
                  _buildRecordItem('תיקו', stats['draws'], Colors.grey),
                  _buildRecordItem('הפסדים', stats['losses'], Colors.red),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: PremiumTypography.heading2.copyWith(
              color: color,
            ),
          ),
          Text(
            label,
            style: PremiumTypography.labelMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: PremiumTypography.heading3.copyWith(color: color),
        ),
        Text(
          label,
          style: PremiumTypography.labelSmall,
        ),
      ],
    );
  }
}
