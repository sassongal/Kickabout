import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/data/repositories.dart';
import 'package:kattrick/l10n/app_localizations.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';
import 'package:kattrick/widgets/error_widget.dart';
import 'package:kattrick/widgets/optimized_image.dart';
import 'package:kattrick/widgets/player_avatar.dart';

class GameTeamsSection extends StatelessWidget {
  final Game game;
  final AsyncValue<Map<String, User>> teamUsersAsync;

  const GameTeamsSection({
    super.key,
    required this.game,
    required this.teamUsersAsync,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (game.teams.isEmpty) {
      return const SizedBox.shrink();
    }

    return teamUsersAsync.when(
      data: (usersById) => TeamsDisplayWidget(
        teams: game.teams,
        usersById: usersById,
      ),
      loading: () => TeamsDisplayWidget(
        teams: game.teams,
        usersById: const <String, User>{},
        isLoading: true,
      ),
      error: (error, stack) => TeamsDisplayWidget(
        teams: game.teams,
        usersById: const <String, User>{},
        errorMessage: l10n.playersLoadError,
      ),
    );
  }
}

class GameSignupsSection extends StatelessWidget {
  final List<GameSignup> confirmedSignups;
  final List<GameSignup> pendingSignups;
  final UsersRepository usersRepo;
  final bool isAdmin;
  final void Function(String playerId)? onRejectPlayer;

  const GameSignupsSection({
    super.key,
    required this.confirmedSignups,
    required this.pendingSignups,
    required this.usersRepo,
    required this.isAdmin,
    this.onRejectPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.signupsTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        if (confirmedSignups.isNotEmpty) ...[
          Text(
            l10n.confirmedSignupsTitle(confirmedSignups.length),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _SignupList(
            signups: confirmedSignups,
            usersRepo: usersRepo,
            isConfirmed: true,
            isAdmin: isAdmin,
            onRejectPlayer: onRejectPlayer,
          ),
          const SizedBox(height: 16),
        ],
        if (pendingSignups.isNotEmpty) ...[
          Text(
            l10n.pendingSignupsTitle(pendingSignups.length),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _SignupList(
            signups: pendingSignups,
            usersRepo: usersRepo,
            isConfirmed: false,
            isAdmin: isAdmin,
            onRejectPlayer: onRejectPlayer,
          ),
        ],
        if (confirmedSignups.isEmpty && pendingSignups.isEmpty)
          AppEmptyWidget(
            message: l10n.noSignups,
            icon: Icons.people_outline,
          ),
      ],
    );
  }
}

class _SignupList extends StatelessWidget {
  final List<GameSignup> signups;
  final UsersRepository usersRepo;
  final bool isConfirmed;
  final bool isAdmin;
  final void Function(String playerId)? onRejectPlayer;

  const _SignupList({
    required this.signups,
    required this.usersRepo,
    required this.isConfirmed,
    required this.isAdmin,
    this.onRejectPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: signups.length,
      itemBuilder: (context, index) => GameSignupTile(
        signup: signups[index],
        usersRepo: usersRepo,
        isConfirmed: isConfirmed,
        isAdmin: isAdmin,
        onRejectPlayer: onRejectPlayer,
      ),
      separatorBuilder: (context, index) => const SizedBox(height: 4),
    );
  }
}

class GameSignupTile extends StatelessWidget {
  final GameSignup signup;
  final UsersRepository usersRepo;
  final bool isConfirmed;
  final bool isAdmin;
  final void Function(String playerId)? onRejectPlayer;

  const GameSignupTile({
    super.key,
    required this.signup,
    required this.usersRepo,
    required this.isConfirmed,
    required this.isAdmin,
    this.onRejectPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<User?>(
      future: usersRepo.getUser(signup.playerId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return ListTile(
            leading: const SizedBox(
              width: 20,
              height: 20,
              child: KineticLoadingAnimation(size: 20),
            ),
            title: Text(l10n.loading),
          );
        }
        return ListTile(
          leading: PlayerAvatar(
            user: user,
            radius: 20,
            clickable: true,
          ),
          title: Text(user.name),
          subtitle: Text(user.email),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isConfirmed)
                Chip(
                  label: Text(l10n.statusApproved),
                  backgroundColor: Colors.green,
                )
              else
                Chip(
                  label: Text(l10n.statusPending),
                  backgroundColor: Colors.orange,
                ),
              if (isAdmin && onRejectPlayer != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.red),
                  onPressed: () => onRejectPlayer!(signup.playerId),
                  tooltip: l10n.removePlayerTooltip,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class PendingApprovalTile extends StatelessWidget {
  final GameSignup signup;
  final UsersRepository usersRepo;
  final void Function(String playerId) onApprove;
  final void Function(String playerId) onReject;

  const PendingApprovalTile({
    super.key,
    required this.signup,
    required this.usersRepo,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<User?>(
      future: usersRepo.getUser(signup.playerId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: PlayerAvatar(user: user, radius: 20),
            title: Text(user.name),
            subtitle: Text(l10n.requestedToJoinAt(
                DateFormat('HH:mm dd/MM').format(signup.signedUpAt))),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => onApprove(signup.playerId),
                  tooltip: l10n.approveTooltip,
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => onReject(signup.playerId),
                  tooltip: l10n.rejectTooltip,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TeamsDisplayWidget extends StatelessWidget {
  final List<Team> teams;
  final Map<String, User> usersById;
  final bool isLoading;
  final String? errorMessage;

  const TeamsDisplayWidget({
    super.key,
    required this.teams,
    required this.usersById,
    this.isLoading = false,
    this.errorMessage,
  });

  Color _getColorFromString(String? colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'black':
        return Colors.black;
      case 'yellow':
        return Colors.yellow;
      case 'blue':
        return Colors.blue;
      case 'white':
        return Colors.white;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (teams.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.teamsTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: teams.take(2).map((team) {
                final index = teams.indexOf(team);
                final teamColor = _getColorFromString(team.color);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == 0 ? 8 : 0,
                      left: index == 1 ? 8 : 0,
                    ),
                    child: _buildTeamColumn(
                      context,
                      team,
                      teamColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamColumn(BuildContext context, Team team, Color teamColor) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: teamColor.withValues(alpha: 0.3), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: teamColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  team.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: teamColor,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.teamPlayerCount(team.playerIds.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: () {
              if (errorMessage != null) {
                return Center(
                  child: Text(
                    errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                );
              }

              final users = team.playerIds
                  .map((id) => usersById[id])
                  .whereType<User>()
                  .toList();

              if (isLoading && users.isEmpty) {
                return const Center(
                  child: KineticLoadingAnimation(size: 40),
                );
              }

              if (users.isEmpty) {
                return Center(
                  child: Text(l10n.noPlayers),
                );
              }

              return Column(
                children: users.map((user) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: teamColor.withValues(alpha: 0.2),
                          child: user.photoUrl != null
                              ? OptimizedImage(
                                  imageUrl: user.photoUrl ?? '',
                                  fit: BoxFit.cover,
                                  width: 24,
                                  height: 24,
                                  borderRadius: BorderRadius.circular(12),
                                  errorWidget: Icon(
                                    Icons.person,
                                    size: 12,
                                    color: teamColor,
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 12,
                                  color: teamColor,
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user.name,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }(),
          ),
        ],
      ),
    );
  }
}
