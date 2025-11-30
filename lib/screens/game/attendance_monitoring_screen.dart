import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/core/constants.dart';

/// Screen for organizer to monitor attendance confirmations
class AttendanceMonitoringScreen extends ConsumerWidget {
  final String gameId;

  const AttendanceMonitoringScreen({
    super.key,
    required this.gameId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesRepo = ref.read(gamesRepositoryProvider);
    final signupsRepo = ref.read(signupsRepositoryProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    final gameStream = gamesRepo.watchGame(gameId);
    final signupsStream = signupsRepo.watchSignups(gameId);

    return AppScaffold(
      title: 'ניטור הגעה',
      body: StreamBuilder<Game?>(
        stream: gameStream,
        builder: (context, gameSnapshot) {
          if (gameSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final game = gameSnapshot.data;
          if (game == null) {
            return const Center(child: Text('משחק לא נמצא'));
          }

          // Verify user is organizer
          if (currentUserId != game.createdBy) {
            return const Center(
              child: Text('רק מארגן המשחק יכול לראות ניטור הגעה'),
            );
          }

          final gameDate = DateFormat('dd/MM/yyyy HH:mm').format(game.gameDate);
          final hasReminderEnabled = game.enableAttendanceReminder;

          return StreamBuilder<List<GameSignup>>(
            stream: signupsStream,
            builder: (context, signupsSnapshot) {
              if (signupsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final signups = signupsSnapshot.data ?? [];
              final confirmedSignups = signups
                  .where((s) => s.status == SignupStatus.confirmed)
                  .toList();
              final pendingSignups = signups
                  .where((s) => s.status == SignupStatus.pending)
                  .toList();

              final maxPlayers = game.maxParticipants ??
                  (game.teamCount * 3); // Default: 3 per team

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Game info card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game.hubName ?? 'משחק',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text(gameDate),
                              ],
                            ),
                            if (game.venueName != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(game.venueName!)),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  hasReminderEnabled
                                      ? Icons.notifications_active
                                      : Icons.notifications_off,
                                  size: 16,
                                  color: hasReminderEnabled
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  hasReminderEnabled
                                      ? 'תזכורות הגעה מופעלות'
                                      : 'תזכורות הגעה כבויות',
                                  style: TextStyle(
                                    color: hasReminderEnabled
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Statistics card
                    Card(
                      color: Colors.blue.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  context,
                                  'מאושרים',
                                  confirmedSignups.length.toString(),
                                  Colors.green,
                                ),
                                _buildStatItem(
                                  context,
                                  'ממתינים',
                                  pendingSignups.length.toString(),
                                  Colors.orange,
                                ),
                                _buildStatItem(
                                  context,
                                  'סה"כ',
                                  signups.length.toString(),
                                  Colors.blue,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: signups.isEmpty
                                  ? 0
                                  : confirmedSignups.length / maxPlayers,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${confirmedSignups.length} / $maxPlayers שחקנים',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Confirmed players section
                    if (confirmedSignups.isNotEmpty) ...[
                      Text(
                        'מאושרים (${confirmedSignups.length})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...confirmedSignups.map((signup) => _buildPlayerTile(
                            context,
                            signup,
                            ref,
                            true,
                          )),
                      const SizedBox(height: 24),
                    ],

                    // Pending players section
                    if (pendingSignups.isNotEmpty) ...[
                      Text(
                        'ממתינים לאישור (${pendingSignups.length})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...pendingSignups.map((signup) => _buildPlayerTile(
                            context,
                            signup,
                            ref,
                            false,
                          )),
                    ],

                    // Empty state
                    if (signups.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'אין נרשמים עדיין',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildPlayerTile(
    BuildContext context,
    GameSignup signup,
    WidgetRef ref,
    bool isConfirmed,
  ) {
    final usersRepo = ref.read(usersRepositoryProvider);
    return FutureBuilder<User?>(
      future: usersRepo.getUser(signup.playerId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return const ListTile(
            leading: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('טוען...'),
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: PlayerAvatar(
              user: user,
              radius: 24,
              clickable: true,
            ),
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: Chip(
              label: Text(isConfirmed ? 'מאושר' : 'ממתין'),
              backgroundColor: isConfirmed ? Colors.green : Colors.orange,
              labelStyle: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}

