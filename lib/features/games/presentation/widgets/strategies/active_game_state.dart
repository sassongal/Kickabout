import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/data/repositories.dart';
import 'package:kattrick/l10n/app_localizations.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/features/hubs/domain/models/hub_role.dart';
import 'package:kattrick/features/games/presentation/widgets/strategies/game_detail_sections.dart';

class ActiveGameState extends StatelessWidget {
  final Game game;
  final String gameId;
  final GameStatus status;
  final UserRole role;
  final bool isCreator;
  final bool isGameFull;
  final List<GameSignup> confirmedSignups;
  final List<GameSignup> pendingSignups;
  final UsersRepository usersRepo;
  final String? currentUserId;
  final AsyncValue<Map<String, User>> teamUsersAsync;
  final Future<void> Function(BuildContext context, Game game) onStartGame;
  final Future<void> Function(BuildContext context, Game game) onEndGame;
  final void Function(String playerId) onRejectPlayer;
  final Future<void> Function(
    BuildContext context,
    Game game,
    int currentPlayers,
    int maxPlayers,
  ) onFindMissingPlayers;

  const ActiveGameState({
    super.key,
    required this.game,
    required this.gameId,
    required this.status,
    required this.role,
    required this.isCreator,
    required this.isGameFull,
    required this.confirmedSignups,
    required this.pendingSignups,
    required this.usersRepo,
    required this.currentUserId,
    required this.teamUsersAsync,
    required this.onStartGame,
    required this.onEndGame,
    required this.onRejectPlayer,
    required this.onFindMissingPlayers,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case GameStatus.inProgress:
        return _buildInProgress(context);
      case GameStatus.statsInput:
        return _buildStatsInput(context);
      case GameStatus.fullyBooked:
      case GameStatus.teamsFormed:
      default:
        return _buildConfirmed(context);
    }
  }

  Widget _buildConfirmed(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = role == UserRole.admin;
    final maxPlayers = game.teamCount * 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (currentUserId != null) ...[
          OutlinedButton.icon(
            onPressed: () => context.push('/games/$gameId/chat'),
            icon: const Icon(Icons.chat),
            label: Text(l10n.gameChatButton),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          if (isAdmin) ...[
            if (game.visibility == GameVisibility.private && !isGameFull)
              ElevatedButton.icon(
                onPressed: () => onFindMissingPlayers(
                    context, game, confirmedSignups.length, maxPlayers),
                icon: const Icon(Icons.person_add),
                label: Text(l10n.findMissingPlayers),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            if (game.visibility == GameVisibility.private && !isGameFull)
              const SizedBox(height: 12),
            if (game.teams.isEmpty)
              ElevatedButton.icon(
                onPressed: () => context.push('/games/$gameId/team-maker'),
                icon: const Icon(Icons.group),
                label: Text(l10n.createTeams),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            if (game.teams.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () => context.push('/games/$gameId/stats'),
                icon: const Icon(Icons.bar_chart),
                label: Text(l10n.logResultAndStats),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            if (isCreator && game.teams.isNotEmpty) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => onStartGame(context, game),
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.startGame),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
          const SizedBox(height: 24),
        ],
        if (game.teams.isNotEmpty) ...[
          GameTeamsSection(game: game, teamUsersAsync: teamUsersAsync),
          const SizedBox(height: 24),
        ],
        GameSignupsSection(
          confirmedSignups: confirmedSignups,
          pendingSignups: pendingSignups,
          usersRepo: usersRepo,
          isAdmin: isAdmin,
          onRejectPlayer: onRejectPlayer,
        ),
      ],
    );
  }

  Widget _buildInProgress(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = role == UserRole.admin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (currentUserId != null) ...[
          OutlinedButton.icon(
            onPressed: () => context.push('/games/$gameId/chat'),
            icon: const Icon(Icons.chat),
            label: Text(l10n.gameChatButton),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          if (isAdmin) ...[
            ElevatedButton.icon(
              onPressed: () => context.push('/games/$gameId/stats'),
              icon: const Icon(Icons.bar_chart),
              label: Text(l10n.recordStats),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (isCreator)
            ElevatedButton.icon(
              onPressed: () => onEndGame(context, game),
              icon: const Icon(Icons.stop),
              label: Text(l10n.endGame),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          const SizedBox(height: 24),
        ],
        if (game.teams.isNotEmpty) ...[
          GameTeamsSection(game: game, teamUsersAsync: teamUsersAsync),
          const SizedBox(height: 24),
        ],
        GameSignupsSection(
          confirmedSignups: confirmedSignups,
          pendingSignups: const [],
          usersRepo: usersRepo,
          isAdmin: false,
        ),
      ],
    );
  }

  Widget _buildStatsInput(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = role == UserRole.admin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isAdmin) ...[
          ElevatedButton.icon(
            onPressed: () => context.push('/games/$gameId/stats'),
            icon: const Icon(Icons.bar_chart),
            label: Text(l10n.recordStats),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (game.teams.isNotEmpty) ...[
          GameTeamsSection(game: game, teamUsersAsync: teamUsersAsync),
          const SizedBox(height: 24),
        ],
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
