import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kickabout/widgets/app_scaffold.dart';
import 'package:kickabout/data/repositories_providers.dart';
import 'package:kickabout/data/repositories.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/core/constants.dart';

/// Player profile screen showing rating, history, and recent games
class PlayerProfileScreen extends ConsumerWidget {
  final String playerId;

  const PlayerProfileScreen({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final usersRepo = ref.watch(usersRepositoryProvider);
    final ratingsRepo = ref.watch(ratingsRepositoryProvider);
    final gamesRepo = ref.watch(gamesRepositoryProvider);

    final userStream = usersRepo.watchUser(playerId);
    final ratingHistoryStream = ratingsRepo.watchRatingHistory(playerId);
    final isOwnProfile = currentUserId == playerId;

    return AppScaffold(
      title: 'פרופיל שחקן',
      actions: isOwnProfile
          ? [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.push('/profile/$playerId/edit'),
                tooltip: 'ערוך פרופיל',
              ),
            ]
          : null,
      body: StreamBuilder<User?>(
        stream: userStream,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('שגיאה: ${userSnapshot.error}'),
                ],
              ),
            );
          }

          final user = userSnapshot.data;
          if (user == null) {
            return const Center(child: Text('שחקן לא נמצא'));
          }

          return StreamBuilder<List<RatingSnapshot>>(
            stream: ratingHistoryStream,
            builder: (context, historySnapshot) {
              final history = historySnapshot.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Player header
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.blue.withValues(alpha: 0.2),
                              backgroundImage: user.photoUrl != null
                                  ? NetworkImage(user.photoUrl!)
                                  : null,
                              child: user.photoUrl == null
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Chip(
                                    label: Text(user.preferredPosition),
                                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Current rating
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'דירוג נוכחי',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  user.currentRankScore.toStringAsFixed(1),
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _getRatingColor(user.currentRankScore),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '/ 10',
                                  style: TextStyle(fontSize: 24, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: user.currentRankScore / 10,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getRatingColor(user.currentRankScore),
                              ),
                              minHeight: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Rating history chart
                    if (history.isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'היסטוריית דירוגים',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 200,
                                child: _buildRatingChart(history),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Recent games
                    Text(
                      'משחקים אחרונים',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRecentGames(context, ref, history, gamesRepo),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8) return Colors.green;
    if (rating >= 6) return Colors.blue;
    if (rating >= 4) return Colors.orange;
    return Colors.red;
  }

  Widget _buildRatingChart(List<RatingSnapshot> history) {
    // Take last 10 ratings for chart
    final recentHistory = history.take(10).toList().reversed.toList();
    if (recentHistory.isEmpty) {
      return const Center(child: Text('אין נתונים להצגה'));
    }

    // Calculate average rating for each snapshot
    final ratings = recentHistory.map((snapshot) {
      return (snapshot.defense +
              snapshot.passing +
              snapshot.shooting +
              snapshot.dribbling +
              snapshot.physical +
              snapshot.leadership +
              snapshot.teamPlay +
              snapshot.consistency) /
          8.0;
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= recentHistory.length) return const Text('');
                final index = value.toInt();
                final date = recentHistory[index].submittedAt;
                return Text(
                  DateFormat('dd/MM').format(date),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: ratings.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value);
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        minY: 0,
        maxY: 10,
      ),
    );
  }

  Widget _buildRecentGames(
    BuildContext context,
    WidgetRef ref,
    List<RatingSnapshot> history,
    GamesRepository gamesRepo,
  ) {
    if (history.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('אין משחקים אחרונים')),
        ),
      );
    }

    // Get unique game IDs from history
    final gameIds = history.map((snapshot) => snapshot.gameId).toSet().take(10).toList();

    return Column(
      children: gameIds.map((gameId) {
        return FutureBuilder<Game?>(
          future: gamesRepo.getGame(gameId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ListTile(
                leading: CircularProgressIndicator(),
                title: Text('טוען...'),
              );
            }

            final game = snapshot.data;
            if (game == null) {
              return const SizedBox.shrink();
            }

            final rating = history.firstWhere(
              (r) => r.gameId == gameId,
              orElse: () => history.first,
            );

            final avgRating = (rating.defense +
                    rating.passing +
                    rating.shooting +
                    rating.dribbling +
                    rating.physical +
                    rating.leadership +
                    rating.teamPlay +
                    rating.consistency) /
                8.0;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRatingColor(avgRating).withValues(alpha: 0.2),
                  child: Text(
                    avgRating.toStringAsFixed(1),
                    style: TextStyle(
                      color: _getRatingColor(avgRating),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  game.location ?? 'מיקום לא צוין',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(game.gameDate),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[600],
                ),
                onTap: () {
                  // Navigate to game detail
                  // TODO: Add navigation when ready
                },
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

