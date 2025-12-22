import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/data/repositories.dart';
import 'package:kattrick/l10n/app_localizations.dart';
import 'package:kattrick/logic/session_logic.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/models/hub_role.dart';
import 'package:kattrick/screens/game/strategies/game_detail_sections.dart';

class CompletedGameState extends StatelessWidget {
  final Game game;
  final String gameId;
  final UserRole role;
  final List<GameSignup> confirmedSignups;
  final UsersRepository usersRepo;
  final AsyncValue<Map<String, User>> teamUsersAsync;
  final Future<void> Function(BuildContext context, Game game) onEditResult;

  const CompletedGameState({
    super.key,
    required this.game,
    required this.gameId,
    required this.role,
    required this.confirmedSignups,
    required this.usersRepo,
    required this.teamUsersAsync,
    required this.onEditResult,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = role == UserRole.admin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (game.session.matches.isNotEmpty ||
            game.session.aggregateWins.isNotEmpty)
          _SessionSummaryWidget(game: game)
        else if (game.session.legacyTeamAScore != null &&
            game.session.legacyTeamBScore != null)
          _FinalScoreWidget(game: game),
        const SizedBox(height: 24),
        if (game.teams.isNotEmpty) ...[
          GameTeamsSection(game: game, teamUsersAsync: teamUsersAsync),
          const SizedBox(height: 24),
        ],
        if (isAdmin) ...[
          OutlinedButton.icon(
            onPressed: () => onEditResult(context, game),
            icon: const Icon(Icons.edit),
            label: Text(l10n.editResult),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.orange),
            ),
          ),
          const SizedBox(height: 12),
        ],
        ElevatedButton.icon(
          onPressed: () => context.push('/games/$gameId/stats'),
          icon: const Icon(Icons.bar_chart),
          label: Text(l10n.viewFullStats),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        GameSignupsSection(
          confirmedSignups: confirmedSignups,
          pendingSignups: const [],
          usersRepo: usersRepo,
          isAdmin: false,
        ),
      ],
    );
  }
}

class _SessionSummaryWidget extends StatelessWidget {
  final Game game;

  const _SessionSummaryWidget({required this.game});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSessionMode = SessionLogic.isSessionMode(game);
    if (!isSessionMode) {
      return const SizedBox.shrink();
    }

    final teamStats = SessionLogic.getAllTeamStats(game);
    final seriesScore = SessionLogic.getSeriesScoreDisplay(game);
    final winner = SessionLogic.calculateSessionWinner(game);

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.sessionSummaryTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              seriesScore,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
            if (winner != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.sessionWinnerLabel(winner.displayName),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
            const SizedBox(height: 24),
            if (teamStats.isNotEmpty) ...[
              Text(
                l10n.teamStatsTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...teamStats.values.map((stats) {
                final team = game.teams.firstWhere(
                  (t) => (t.color ?? '') == stats.teamColor,
                  orElse: () => game.teams.first,
                );
                final colorValue = team.colorValue ?? 0xFF2196F3;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Color(colorValue),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team.name.isNotEmpty
                                  ? team.name
                                  : stats.teamColor,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              l10n.teamStatsRecord(
                                stats.wins,
                                stats.draws,
                                stats.losses,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                            ),
                            Text(
                              l10n.teamStatsGoals(
                                stats.goalsFor,
                                stats.goalDifference > 0
                                    ? '+${stats.goalDifference}'
                                    : '${stats.goalDifference}',
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        l10n.pointsShort(stats.points),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (game.session.matches.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.totalMatchesLabel(game.session.matches.length),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FinalScoreWidget extends StatelessWidget {
  final Game game;

  const _FinalScoreWidget({required this.game});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final teamAScore = game.session.legacyTeamAScore ?? 0;
    final teamBScore = game.session.legacyTeamBScore ?? 0;
    final teamAName = game.teams.isNotEmpty
        ? game.teams[0].name
        : l10n.teamADefaultName;
    final teamBName = game.teams.length > 1
        ? game.teams[1].name
        : l10n.teamBDefaultName;

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              l10n.finalScoreTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        teamAName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$teamAScore',
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    ':',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        teamBName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$teamBScore',
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
