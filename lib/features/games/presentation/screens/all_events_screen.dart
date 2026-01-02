import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/premium/spotlight_card.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/premium/empty_state.dart';
import 'package:kattrick/widgets/premium/loading_state.dart';
import 'package:kattrick/core/providers/complex_providers.dart';

class AllEventsScreen extends ConsumerStatefulWidget {
  const AllEventsScreen({super.key});

  @override
  ConsumerState<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends ConsumerState<AllEventsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final gameQueriesRepo = ref.read(gameQueriesRepositoryProvider);

    if (currentUserId == null) {
      return const AppScaffold(
        title: 'כל האירועים',
        body: Center(child: Text('נא להתחבר')),
      );
    }

    final hubsAsync = ref.watch(hubsByMemberStreamProvider(currentUserId));

    return AppScaffold(
      title: 'כל האירועים',
      body: hubsAsync.when(
        data: (hubs) {
          final hubIds = hubs.map((h) => h.hubId).toList();

          // Also fetch games created by user or where user is signed up, even if not in hub list
          // For now, let's stick to hub games + user created games logic if possible,
          // but the repository method might need adjustment.
          // Let's assume we want to show all future games relevant to the user.

          // We'll use a FutureBuilder to fetch games since complex querying might not be stream-friendly
          // or use a stream if available. Let's try to fetch all relevant games.

          return FutureBuilder<List<Game>>(
            future: gameQueriesRepo.getUpcomingGames(
              hubIds: hubIds,
              limit: 50, // Reasonable limit
            ),
            builder: (context, gamesSnapshot) {
              if (gamesSnapshot.connectionState == ConnectionState.waiting) {
                return const PremiumLoadingState(message: 'טוען אירועים...');
              }

              if (gamesSnapshot.hasError) {
                return PremiumEmptyState(
                  icon: Icons.error_outline,
                  title: 'שגיאה',
                  message: 'לא ניתן לטעון אירועים',
                );
              }

              final games = gamesSnapshot.data ?? [];

              // Include future games AND games that started recently (up to 3 hours ago)
              final now = DateTime.now();
              final upcomingGames = games.where((g) {
                final startLimit = now.subtract(const Duration(hours: 3));
                return g.gameDate.isAfter(startLimit);
              }).toList();

              // Sort by proximity to 'now' (absolute difference)
              upcomingGames.sort((a, b) {
                final diffA = (a.gameDate.difference(now)).inSeconds.abs();
                final diffB = (b.gameDate.difference(now)).inSeconds.abs();
                return diffA.compareTo(diffB);
              });

              if (upcomingGames.isEmpty) {
                return const PremiumEmptyState(
                  icon: Icons.event_busy,
                  title: 'אין אירועים מתוכננים',
                  message: 'כרגע אין משחקים עתידיים ברשימה שלך.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: upcomingGames.length,
                itemBuilder: (context, index) {
                  final game = upcomingGames[index];
                  return _buildEventCard(context, game, currentUserId);
                },
              );
            },
          );
        },
        loading: () => const PremiumLoadingState(message: 'טוען אירועים...'),
        error: (err, stack) => PremiumEmptyState(
          icon: Icons.error_outline,
          title: 'שגיאה',
          message: 'לא ניתן לטעון אירועים',
        ),
      ),
    );
  }

  Widget _buildEventCard(
      BuildContext context, Game game, String currentUserId) {
    final isCreator = game.createdBy == currentUserId;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'he');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SpotlightCard(
        usePrism: true,
        onTap: () => context.push('/games/${game.gameId}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(game.gameDate),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (game.location != null)
                        Text(
                          game.location!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isCreator)
                  IconButton(
                    icon: const Icon(Icons.edit, color: PremiumColors.primary),
                    onPressed: () {
                      // Navigate to edit game or hub event depending on type
                      // For now, assuming generic edit or game details handles it
                      context.push('/games/${game.gameId}');
                    },
                  )
                else
                  const Icon(Icons.chevron_right, color: Colors.white54),
              ],
            ),
            const SizedBox(height: 12),
            // Status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(game.status).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStatusColor(game.status).withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                _getStatusText(game.status),
                style: TextStyle(
                  color: _getStatusColor(game.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(GameStatus status) {
    switch (status) {
      case GameStatus.teamSelection:
        return Colors.blue;
      case GameStatus.teamsFormed:
        return Colors.orange;
      case GameStatus.inProgress:
        return Colors.green;
      case GameStatus.completed:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(GameStatus status) {
    switch (status) {
      case GameStatus.teamSelection:
        return 'הרשמה פתוחה';
      case GameStatus.teamsFormed:
        return 'קבוצות נוצרו';
      case GameStatus.inProgress:
        return 'במהלך משחק';
      case GameStatus.completed:
        return 'הסתיים';
      default:
        return 'לא ידוע';
    }
  }
}
