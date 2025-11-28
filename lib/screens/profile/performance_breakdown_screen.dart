import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_card.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:intl/intl.dart';

/// Performance breakdown by hub for a player
class PerformanceBreakdownScreen extends ConsumerStatefulWidget {
  final String userId;

  const PerformanceBreakdownScreen({super.key, required this.userId});

  @override
  ConsumerState<PerformanceBreakdownScreen> createState() =>
      _PerformanceBreakdownScreenState();
}

class _PerformanceBreakdownScreenState
    extends ConsumerState<PerformanceBreakdownScreen> {
  late Future<List<_HubPerformance>> _data;

  @override
  void initState() {
    super.initState();
    _data = _loadData();
  }

  Future<List<_HubPerformance>> _loadData() async {
    final hubsRepo = ref.read(hubsRepositoryProvider);
    final gamesRepo = ref.read(gamesRepositoryProvider);
    final hubs = await hubsRepo.getHubsByMember(widget.userId);

    final List<_HubPerformance> results = [];
    for (final hub in hubs) {
      try {
        final games = await gamesRepo.getGamesByHub(hub.hubId);
        final myGames = games
            .where((g) => g.confirmedPlayerIds.contains(widget.userId))
            .toList();

        int wins = 0;
        int goals = 0;
        int assists = 0;
        DateTime? lastGameDate;

        for (final game in myGames) {
          // Track most recent game date
          lastGameDate = _maxDate(lastGameDate, game.gameDate);

          // Find user's team
          String? myTeamColor;
          for (final team in game.teams) {
            if (team.playerIds.contains(widget.userId)) {
              myTeamColor = team.color;
              break;
            }
          }

          if (myTeamColor != null) {
            for (final match in game.matches) {
              // Count goals and assists
              goals +=
                  match.scorerIds.where((id) => id == widget.userId).length;
              assists +=
                  match.assistIds.where((id) => id == widget.userId).length;

              // Check for win
              if (match.scoreA > match.scoreB &&
                  match.teamAColor == myTeamColor) {
                wins++;
              } else if (match.scoreB > match.scoreA &&
                  match.teamBColor == myTeamColor) {
                wins++;
              }
            }
          }
        }

        results.add(_HubPerformance(
          hub: hub,
          gamesPlayed: myGames.length,
          wins: wins,
          goals: goals,
          assists: assists,
          lastGameDate: lastGameDate,
        ));
      } catch (_) {
        // Skip hub if fetching fails
      }
    }
    return results;
  }

  DateTime? _maxDate(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  @override
  Widget build(BuildContext context) {
    return FuturisticScaffold(
      title: 'ביצועים לפי הוב',
      body: FutureBuilder<List<_HubPerformance>>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const FuturisticLoadingState(message: 'טוען נתונים...');
          }

          if (snapshot.hasError) {
            return FuturisticEmptyState(
              icon: Icons.error_outline,
              title: 'שגיאה בטעינת נתונים',
              message: snapshot.error.toString(),
              action: ElevatedButton.icon(
                onPressed: () => setState(() {
                  _data = _loadData();
                }),
                icon: const Icon(Icons.refresh),
                label: const Text('נסה שוב'),
              ),
            );
          }

          final hubs = snapshot.data ?? [];
          if (hubs.isEmpty) {
            return FuturisticEmptyState(
              icon: Icons.sports_soccer,
              title: 'אין נתונים',
              message: 'לא נמצאו משחקים עבור הובים שלך',
              action: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.push('/games/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('צור משחק'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/discover'),
                    icon: const Icon(Icons.group_add),
                    label: const Text('הצטרף להאב'),
                  ),
                ],
              ),
            );
          }

          final totalGames =
              hubs.fold<int>(0, (sum, h) => sum + h.gamesPlayed);
          final totalWins = hubs.fold<int>(0, (sum, h) => sum + h.wins);
          final totalGoals = hubs.fold<int>(0, (sum, h) => sum + h.goals);
          final totalAssists = hubs.fold<int>(0, (sum, h) => sum + h.assists);
          final winRate =
              totalGames == 0 ? 0.0 : (totalWins / totalGames * 100);
          final lastGameDate = hubs.fold<DateTime?>(
              null, (acc, h) => _maxDate(acc, h.lastGameDate));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hubs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _SummaryCard(
                  totalGames: totalGames,
                  totalWins: totalWins,
                  totalGoals: totalGoals,
                  totalAssists: totalAssists,
                  winRate: winRate,
                  lastGameDate: lastGameDate,
                );
              }
              final item = hubs[index - 1];
              return FuturisticCard(
                margin: const EdgeInsets.only(bottom: 12),
                onTap: () => context.push('/hubs/${item.hub.hubId}'),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: FuturisticColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.group, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.hub.name,
                            style: FuturisticTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _StatBadge(
                                  label: 'משחקים',
                                  value: item.gamesPlayed.toString(),
                                  color: Colors.blue),
                              _StatBadge(
                                  label: 'ניצחונות',
                                  value: item.wins.toString(),
                                  color: Colors.green),
                              _StatBadge(
                                  label: 'שערים',
                                  value: item.goals.toString(),
                                  color: Colors.orange),
                              _StatBadge(
                                  label: 'בישולים',
                                  value: item.assists.toString(),
                                  color: Colors.purple),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ניצחונות/משחקים: ${item.wins}/${item.gamesPlayed}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalGames;
  final int totalWins;
  final int totalGoals;
  final int totalAssists;
  final double winRate;
  final DateTime? lastGameDate;

  const _SummaryCard({
    required this.totalGames,
    required this.totalWins,
    required this.totalGoals,
    required this.totalAssists,
    required this.winRate,
    required this.lastGameDate,
  });

  @override
  Widget build(BuildContext context) {
    return FuturisticCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'סיכום ביצועים',
            style: FuturisticTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatBadge(label: 'משחקים', value: '$totalGames', color: Colors.blue),
              _StatBadge(label: 'ניצחונות', value: '$totalWins', color: Colors.green),
              _StatBadge(label: 'שערים', value: '$totalGoals', color: Colors.orange),
              _StatBadge(label: 'בישולים', value: '$totalAssists', color: Colors.purple),
              _StatBadge(
                  label: 'אחוז ניצחונות',
                  value: '${winRate.toStringAsFixed(1)}%',
                  color: Colors.teal),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lastGameDate != null
                ? 'משחק אחרון: ${DateFormat('dd/MM/yy').format(lastGameDate!)}'
                : 'אין משחקים קודמים',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _HubPerformance {
  final Hub hub;
  final int gamesPlayed;
  final int wins;
  final int goals;
  final int assists;
  final DateTime? lastGameDate;

  _HubPerformance({
    required this.hub,
    required this.gamesPlayed,
    required this.wins,
    required this.goals,
    required this.assists,
    required this.lastGameDate,
  });
}
