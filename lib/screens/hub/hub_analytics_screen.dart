import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';

/// Hub Analytics Screen - Dashboard עם סטטיסטיקות למנהלי הוב
class HubAnalyticsScreen extends ConsumerStatefulWidget {
  final String hubId;

  const HubAnalyticsScreen({
    super.key,
    required this.hubId,
  });

  @override
  ConsumerState<HubAnalyticsScreen> createState() => _HubAnalyticsScreenState();
}

class _HubAnalyticsScreenState extends ConsumerState<HubAnalyticsScreen> {
  DateTime _selectedPeriod = DateTime.now(); // Current month
  bool _isLoading = true;
  HubAnalytics? _analytics;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final gamesRepo = ref.read(gamesRepositoryProvider);
      final feedRepo = ref.read(feedRepositoryProvider);
      final usersRepo = ref.read(usersRepositoryProvider);

      final hub = await hubsRepo.getHub(widget.hubId);
      if (hub == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get games for selected period
      final allGames = await gamesRepo.getGamesByHub(widget.hubId);
      final periodStart = DateTime(_selectedPeriod.year, _selectedPeriod.month, 1);
      final periodEnd = DateTime(_selectedPeriod.year, _selectedPeriod.month + 1, 0);
      
      final periodGames = allGames.where((game) {
        return game.gameDate.isAfter(periodStart) && 
               game.gameDate.isBefore(periodEnd.add(const Duration(days: 1)));
      }).toList();

      // Get feed posts (using stream and taking first value)
      List<FeedPost> feedPosts = [];
      try {
        final feedStream = feedRepo.watchFeed(widget.hubId);
        feedPosts = await feedStream.first;
      } catch (e) {
        feedPosts = [];
      }
      final periodPosts = feedPosts.where((post) {
        return post.createdAt.isAfter(periodStart) && 
               post.createdAt.isBefore(periodEnd.add(const Duration(days: 1)));
      }).toList();

      // Get members
      final members = await usersRepo.getUsers(hub.memberIds);
      final avgRating = members.isNotEmpty
          ? members.map((m) => m.currentRankScore).reduce((a, b) => a + b) / members.length
          : 0.0;

      // Calculate total participants (from signups)
      int totalParticipants = 0;
      try {
        final signupsRepo = ref.read(signupsRepositoryProvider);
        for (final game in periodGames) {
          final signups = await signupsRepo.getSignups(game.gameId);
          totalParticipants += signups.where((s) => s.status == SignupStatus.confirmed).length;
        }
      } catch (e) {
        // If fails, use 0
        totalParticipants = 0;
      }

      // Calculate stats
      final analytics = HubAnalytics(
        hubId: widget.hubId,
        period: _selectedPeriod,
        totalGames: periodGames.length,
        totalParticipants: totalParticipants,
        totalPosts: periodPosts.length,
        totalMembers: hub.memberIds.length,
        averageRating: avgRating,
        gamesByWeek: _calculateGamesByWeek(periodGames),
        activityTrend: _calculateActivityTrend(periodPosts),
      );

      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<int, int> _calculateGamesByWeek(List<Game> games) {
    final gamesByWeek = <int, int>{};
    for (final game in games) {
      final week = ((game.gameDate.day - 1) / 7).floor() + 1;
      gamesByWeek[week] = (gamesByWeek[week] ?? 0) + 1;
    }
    return gamesByWeek;
  }

  Map<DateTime, int> _calculateActivityTrend(List<FeedPost> posts) {
    final activityTrend = <DateTime, int>{};
    for (final post in posts) {
      final date = DateTime(
        post.createdAt.year,
        post.createdAt.month,
        post.createdAt.day,
      );
      activityTrend[date] = (activityTrend[date] ?? 0) + 1;
    }
    return activityTrend;
  }

  @override
  Widget build(BuildContext context) {
    return FuturisticScaffold(
      title: 'אנליטיקס Hub',
      body: _isLoading
          ? const FuturisticLoadingState(message: 'טוען נתונים...')
          : _analytics == null
              ? const Center(child: Text('אין נתונים'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period selector
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () {
                                  setState(() {
                                    _selectedPeriod = DateTime(
                                      _selectedPeriod.year,
                                      _selectedPeriod.month - 1,
                                    );
                                  });
                                  _loadAnalytics();
                                },
                              ),
                              Text(
                                DateFormat('MMMM yyyy', 'he').format(_selectedPeriod),
                                style: FuturisticTypography.heading3,
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: () {
                                  setState(() {
                                    _selectedPeriod = DateTime(
                                      _selectedPeriod.year,
                                      _selectedPeriod.month + 1,
                                    );
                                  });
                                  _loadAnalytics();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Stats cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'משחקים',
                              '${_analytics!.totalGames}',
                              Icons.sports_soccer,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'חברים',
                              '${_analytics!.totalMembers}',
                              Icons.people,
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'פוסטים',
                              '${_analytics!.totalPosts}',
                              Icons.post_add,
                              Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'דירוג ממוצע',
                              _analytics!.averageRating.toStringAsFixed(1),
                              Icons.star,
                              Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Games by week chart
                      if (_analytics!.gamesByWeek.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'משחקים לפי שבוע',
                                  style: FuturisticTypography.heading3,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child: _buildGamesByWeekChart(_analytics!.gamesByWeek),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Activity trend
                      if (_analytics!.activityTrend.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'טרנד פעילות',
                                  style: FuturisticTypography.heading3,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child: _buildActivityTrendChart(_analytics!.activityTrend),
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

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: FuturisticTypography.heading2.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: FuturisticTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamesByWeekChart(Map<int, int> gamesByWeek) {
    final maxWeek = gamesByWeek.keys.isEmpty ? 4 : gamesByWeek.keys.reduce((a, b) => a > b ? a : b);
    final maxGames = gamesByWeek.values.isEmpty ? 1 : gamesByWeek.values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxGames.toDouble() + 1,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final week = value.toInt();
                if (week < 1 || week > maxWeek) return const Text('');
                return Text(
                  'שבוע $week',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
        barGroups: List.generate(maxWeek, (index) {
          final week = index + 1;
          final games = gamesByWeek[week] ?? 0;
          return BarChartGroupData(
            x: week,
            barRods: [
              BarChartRodData(
                toY: games.toDouble(),
                color: Colors.blue,
                width: 20,
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildActivityTrendChart(Map<DateTime, int> activityTrend) {
    final sortedDates = activityTrend.keys.toList()..sort();
    if (sortedDates.isEmpty) {
      return const Center(child: Text('אין נתונים'));
    }

    final maxActivity = activityTrend.values.isEmpty 
        ? 1 
        : activityTrend.values.reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedDates.length) return const Text('');
                return Text(
                  DateFormat('dd/MM').format(sortedDates[index]),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: sortedDates.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                activityTrend[entry.value]!.toDouble(),
              );
            }).toList(),
            isCurved: true,
            color: Colors.purple,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        minY: 0,
        maxY: maxActivity.toDouble() + 1,
      ),
    );
  }
}

/// Hub Analytics data model
class HubAnalytics {
  final String hubId;
  final DateTime period;
  final int totalGames;
  final int totalParticipants;
  final int totalPosts;
  final int totalMembers;
  final double averageRating;
  final Map<int, int> gamesByWeek;
  final Map<DateTime, int> activityTrend;

  HubAnalytics({
    required this.hubId,
    required this.period,
    required this.totalGames,
    required this.totalParticipants,
    required this.totalPosts,
    required this.totalMembers,
    required this.averageRating,
    required this.gamesByWeek,
    required this.activityTrend,
  });
}

