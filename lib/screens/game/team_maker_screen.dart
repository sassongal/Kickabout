import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/core/constants.dart';
import 'package:kickadoor/ui/team_builder/team_builder_page.dart';

/// Team maker screen
class TeamMakerScreen extends ConsumerWidget {
  final String gameId;

  const TeamMakerScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesRepo = ref.watch(gamesRepositoryProvider);
    final signupsRepo = ref.watch(signupsRepositoryProvider);

    final gameStream = gamesRepo.watchGame(gameId);
    final signupsStream = signupsRepo.watchSignups(gameId);

    return AppScaffold(
      title: 'יצירת קבוצות',
      body: StreamBuilder<Game?>(
        stream: gameStream,
        builder: (context, gameSnapshot) {
          if (gameSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (gameSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('שגיאה: ${gameSnapshot.error}'),
                ],
              ),
            );
          }

          final game = gameSnapshot.data;
          if (game == null) {
            return const Center(child: Text('משחק לא נמצא'));
          }

          return StreamBuilder<List<GameSignup>>(
            stream: signupsStream,
            builder: (context, signupsSnapshot) {
              if (signupsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final signups = signupsSnapshot.data ?? [];
              final confirmedPlayerIds = signups
                  .where((s) => s.status == SignupStatus.confirmed)
                  .map((s) => s.playerId)
                  .toList();

              if (confirmedPlayerIds.length < game.teamCount * AppConstants.minPlayersPerTeam) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 64,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'אין מספיק נרשמים',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'נדרשים לפחות ${game.teamCount * AppConstants.minPlayersPerTeam} שחקנים',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'נרשמו: ${confirmedPlayerIds.length}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }

              return TeamBuilderPage(
                gameId: gameId,
                teamCount: game.teamCount,
                playerIds: confirmedPlayerIds,
              );
            },
          );
        },
      ),
    );
  }
}
