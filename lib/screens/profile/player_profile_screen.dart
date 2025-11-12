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
import 'package:kickabout/services/push_notification_integration_service.dart';
import 'package:flutter/foundation.dart';

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
    final followRepo = ref.watch(followRepositoryProvider);
    final gamificationRepo = ref.watch(gamificationRepositoryProvider);

    final userStream = usersRepo.watchUser(playerId);
    final ratingHistoryStream = ratingsRepo.watchRatingHistory(playerId);
    final gamificationStream = gamificationRepo.watchGamification(playerId);
    final isFollowingStream = currentUserId != null && currentUserId != playerId
        ? followRepo.watchIsFollowing(currentUserId, playerId)
        : Stream.value(false);
    final followingCountStream = followRepo.watchFollowingCount(playerId);
    final followersCountStream = followRepo.watchFollowersCount(playerId);
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
                                  if (user.city != null && user.city!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_city,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          user.city!,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          user.phoneNumber!,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Chip(
                                    label: Text(user.preferredPosition),
                                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.event,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${user.totalParticipations} השתתפויות',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  if (!isOwnProfile) ...[
                                    const SizedBox(height: 12),
                                    StreamBuilder<bool>(
                                      stream: isFollowingStream,
                                      builder: (context, isFollowingSnapshot) {
                                        final isFollowing = isFollowingSnapshot.data ?? false;
                                        return ElevatedButton.icon(
                                          onPressed: () async {
                                            if (currentUserId == null) return;
                                            try {
                                              if (isFollowing) {
                                                await followRepo.unfollow(currentUserId, playerId);
                                              } else {
                                                await followRepo.follow(currentUserId, playerId);
                                                
                                                // Send notification
                                                try {
                                                  final pushIntegration = ref.read(pushNotificationIntegrationServiceProvider);
                                                  final currentUser = await usersRepo.getUser(currentUserId);
                                                  
                                                  await pushIntegration.notifyNewFollow(
                                                    followerName: currentUser?.name ?? 'מישהו',
                                                    followingId: playerId,
                                                  );
                                                } catch (e) {
                                                  debugPrint('Failed to send follow notification: $e');
                                                }
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('שגיאה: $e')),
                                                );
                                              }
                                            }
                                          },
                                          icon: Icon(isFollowing ? Icons.person_remove : Icons.person_add),
                                          label: Text(isFollowing ? 'ביטול עקיבה' : 'עקוב'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isFollowing
                                                ? Theme.of(context).colorScheme.error
                                                : Theme.of(context).colorScheme.primary,
                                            foregroundColor: isFollowing
                                                ? Theme.of(context).colorScheme.onError
                                                : Theme.of(context).colorScheme.onPrimary,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      StreamBuilder<int>(
                                        stream: followersCountStream,
                                        builder: (context, snapshot) {
                                          final count = snapshot.data ?? 0;
                                          return InkWell(
                                            onTap: () => context.push('/profile/$playerId/followers'),
                                            child: Column(
                                              children: [
                                                Text(
                                                  '$count',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const Text(
                                                  'עוקבים',
                                                  style: TextStyle(fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 24),
                                      StreamBuilder<int>(
                                        stream: followingCountStream,
                                        builder: (context, snapshot) {
                                          final count = snapshot.data ?? 0;
                                          return InkWell(
                                            onTap: () => context.push('/profile/$playerId/following'),
                                            child: Column(
                                              children: [
                                                Text(
                                                  '$count',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const Text(
                                                  'עוקב',
                                                  style: TextStyle(fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Gamification
                    StreamBuilder<Gamification?>(
                      stream: gamificationStream,
                      builder: (context, gamificationSnapshot) {
                        final gamification = gamificationSnapshot.data;
                        if (gamification != null) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'גיימיפיקציה',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          Text(
                                            '${gamification.points}',
                                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.amber,
                                                ),
                                          ),
                                          const Text('נקודות'),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          Text(
                                            'Level ${gamification.level}',
                                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                          ),
                                          const Text('רמה'),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (gamification.badges.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      'תגים',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: gamification.badges.map((badge) {
                                        return Chip(
                                          label: Text(badge),
                                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
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
                      // Advanced analytics
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ניתוח מתקדם',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Skills radar chart
                              if (history.isNotEmpty) ...[
                                Text(
                                  'השוואת יכולות',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 250,
                                  child: _buildSkillsRadarChart(history.last),
                                ),
                                const SizedBox(height: 24),
                              ],
                              // Trend indicators
                              _buildTrendIndicators(history),
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

  Widget _buildSkillsRadarChart(RatingSnapshot snapshot) {
    final skills = [
      ('הגנה', snapshot.defense),
      ('מסירות', snapshot.passing),
      ('בעיטות', snapshot.shooting),
      ('כדרור', snapshot.dribbling),
      ('פיזי', snapshot.physical),
      ('מנהיגות', snapshot.leadership),
      ('משחק קבוצתי', snapshot.teamPlay),
      ('עקביות', snapshot.consistency),
    ];

    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            fillColor: Colors.blue.withValues(alpha: 0.2),
            borderColor: Colors.blue,
            borderWidth: 2,
            dataEntries: skills.map((s) => RadarEntry(value: s.$2)).toList(),
          ),
        ],
        tickCount: 5,
        ticksTextStyle: const TextStyle(fontSize: 10),
        tickBorderData: BorderSide(color: Colors.grey[300]!),
        borderData: BorderSide(color: Colors.grey[400]!, width: 2),
        radarBackgroundColor: Colors.grey[100]!,
        radarBorderData: BorderSide(color: Colors.grey[400]!, width: 1),
        titleTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        getTitle: (index, angle) {
          return RadarChartTitle(
            text: skills[index].$1,
            angle: angle,
          );
        },
      ),
    );
  }

  Widget _buildTrendIndicators(List<RatingSnapshot> history) {
    if (history.length < 2) {
      return const SizedBox.shrink();
    }

    // Calculate trends
    final recent = history.take(5).toList();
    final older = history.skip(5).take(5).toList();
    
    if (older.isEmpty) {
      return const SizedBox.shrink();
    }

    final recentAvg = recent.map((s) => 
      (s.defense + s.passing + s.shooting + s.dribbling + 
       s.physical + s.leadership + s.teamPlay + s.consistency) / 8.0
    ).reduce((a, b) => a + b) / recent.length;

    final olderAvg = older.map((s) => 
      (s.defense + s.passing + s.shooting + s.dribbling + 
       s.physical + s.leadership + s.teamPlay + s.consistency) / 8.0
    ).reduce((a, b) => a + b) / older.length;

    final trend = recentAvg - olderAvg;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildTrendCard(
          'מגמה',
          trend > 0.1 ? 'משתפר' : trend < -0.1 ? 'יורד' : 'יציב',
          trend > 0.1 ? Colors.green : trend < -0.1 ? Colors.red : Colors.grey,
          Icons.trending_up,
        ),
        _buildTrendCard(
          'שינוי',
          '${trend > 0 ? "+" : ""}${trend.toStringAsFixed(1)}',
          trend > 0 ? Colors.green : trend < 0 ? Colors.red : Colors.grey,
          Icons.arrow_upward,
        ),
        _buildTrendCard(
          'ממוצע אחרון',
          recentAvg.toStringAsFixed(1),
          _getRatingColor(recentAvg),
          Icons.star,
        ),
      ],
    );
  }

  Widget _buildTrendCard(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
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

