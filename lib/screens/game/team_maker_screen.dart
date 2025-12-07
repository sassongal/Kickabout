import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/l10n/app_localizations.dart';
import 'package:kattrick/theme/futuristic_theme.dart';
import 'package:kattrick/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kattrick/widgets/futuristic/futuristic_card.dart';
import 'package:kattrick/widgets/dialogs/unrated_players_warning_dialog.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/models/hub_role.dart';
import 'package:kattrick/core/constants.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/widgets/team_card.dart';
import 'package:kattrick/screens/game/team_maker_controller.dart';
import 'package:kattrick/logic/team_maker.dart';

/// Premium team maker screen with advanced UI
class TeamMakerScreen extends ConsumerStatefulWidget {
  final String gameId; // Can be gameId or eventId
  final bool isEvent; // If true, gameId is actually an eventId
  final String? hubId; // Required if isEvent == true

  const TeamMakerScreen({
    super.key,
    required this.gameId,
    this.isEvent = false,
    this.hubId,
  });

  @override
  ConsumerState<TeamMakerScreen> createState() => _TeamMakerScreenState();
}

class _TeamMakerScreenState extends ConsumerState<TeamMakerScreen> {
  bool _shownNotEnoughDialog = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.isEvent) {
      return _buildForEvent(context, ref, l10n);
    } else {
      return _buildForGame(context, ref, l10n);
    }
  }

  Widget _buildForEvent(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    if (widget.hubId == null) {
      return FuturisticScaffold(
        title: l10n.teamFormation,
        body: Center(child: Text(l10n.errorMissingHubId)),
      );
    }

    final hubEventsRepo = ref.watch(hubEventsRepositoryProvider);

    // Use a key to ensure this builder is identified
    return FuturisticScaffold(
      title: 'יוצר כוחות',
      body: FutureBuilder<HubEvent?>(
        // Create a memoized future or rely on repo caching.
        // We rely on the repo's internal caching for now.
        future: hubEventsRepo.getHubEvent(widget.hubId!, widget.gameId),
        builder: (context, eventSnapshot) {
          // 1. Handle Loading (only if we have no data at all)
          if (eventSnapshot.connectionState == ConnectionState.waiting &&
              !eventSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Handle Error
          if (eventSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('${l10n.error}: ${eventSnapshot.error}'),
                ],
              ),
            );
          }

          // 3. Handle Data (Success)
          final event = eventSnapshot.data;
          if (event == null) {
            // If connection is done but data is null
            if (eventSnapshot.connectionState == ConnectionState.done) {
              return Center(child: Text(l10n.eventNotFound));
            }
            // Should verify if we are just waiting with no data
            return const Center(child: CircularProgressIndicator());
          }

          // Check admin permissions
          final roleAsync = ref.watch(hubRoleProvider(widget.hubId!));
          return roleAsync.when(
            data: (role) {
              if (role != UserRole.admin) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, size: 64, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noAdminPermissionForScreen,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.onlyHubAdminsCanCreateTeams,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final registeredPlayerIds = event.registeredPlayerIds;

              if (registeredPlayerIds.length <
                  event.teamCount * AppConstants.minPlayersPerTeam) {
                if (!_shownNotEnoughDialog) {
                  _shownNotEnoughDialog = true;
                  Future.microtask(() async {
                    await showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.notEnoughRegisteredPlayers),
                        content: Text(
                          '${l10n.requiredPlayersCount(event.teamCount * AppConstants.minPlayersPerTeam)}\n${l10n.registeredPlayerCount(registeredPlayerIds.length)}',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              context.pop();
                            },
                            child: const Text('אוקיי'),
                          ),
                        ],
                      ),
                    );
                  });
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 64,
                        color: FuturisticColors.warning,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.notEnoughRegisteredPlayers,
                        style: FuturisticTypography.heading2,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.requiredPlayersCount(
                            event.teamCount * AppConstants.minPlayersPerTeam),
                        style: FuturisticTypography.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.registeredPlayerCount(registeredPlayerIds.length),
                        style: FuturisticTypography.bodySmall,
                      ),
                    ],
                  ),
                );
              }

              return PremiumTeamBuilder(
                args: TeamMakerArgs(
                  hubId: widget.hubId!,
                  playerIds: registeredPlayerIds,
                  teamCount: event.teamCount,
                  isEvent: true,
                  eventId: widget.gameId,
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(l10n.permissionCheckErrorDetails(error.toString())),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForGame(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    // Game mode implementation (kept simple for now)
    return FuturisticScaffold(
      title: 'יוצר כוחות',
      body: Center(child: Text('Game mode coming soon')),
    );
  }
}

/// Premium team builder with advanced UI
class PremiumTeamBuilder extends ConsumerStatefulWidget {
  final TeamMakerArgs args;

  const PremiumTeamBuilder({
    super.key,
    required this.args,
  });

  @override
  ConsumerState<PremiumTeamBuilder> createState() => _PremiumTeamBuilderState();
}

class _PremiumTeamBuilderState extends ConsumerState<PremiumTeamBuilder> {
  @override
  void initState() {
    super.initState();
  }

  void _generateTeams() async {
    final controller =
        ref.read(teamMakerControllerProvider(widget.args).notifier);

    // Check for unrated players before generating
    final unratedPlayers = await controller.checkUnratedPlayers();

    // Show warning if there are unrated players
    if (unratedPlayers.isNotEmpty && mounted) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => UnratedPlayersWarningDialog(
          unratedPlayers: unratedPlayers,
          onContinue: () => Navigator.of(context).pop(true),
          onRateNow: () => Navigator.of(context).pop(false),
        ),
      );

      if (shouldContinue != true) {
        // User chose to rate now, assume we should refresh?
        // For now just return, user can go to rate and come back.
        // Actually the dialog handling in old code just returned.
        return;
      }
    }

    controller.generateTeams();
  }

  Future<void> _saveTeams() async {
    final controller =
        ref.read(teamMakerControllerProvider(widget.args).notifier);
    final success = await controller.saveTeams();

    if (success && mounted) {
      SnackbarHelper.showSuccess(context, 'הכוחות נשמרו בהצלחה! 🎉');
      context.pop();
    } else if (mounted) {
      final state = ref.read(teamMakerControllerProvider(widget.args));
      if (state.errorMessage != null) {
        SnackbarHelper.showError(context, state.errorMessage!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teamMakerControllerProvider(widget.args));
    final controller =
        ref.read(teamMakerControllerProvider(widget.args).notifier);

    // Error handling listener
    ref.listen(teamMakerControllerProvider(widget.args), (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        SnackbarHelper.showError(context, next.errorMessage!);
      }
    });

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Balance Score Card (only show after generation)
        if (state.hasGenerated) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: FuturisticCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics_outlined,
                            color: FuturisticColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'ניקוד איזון',
                          style: FuturisticTypography.heading3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.balanceScore.toStringAsFixed(1),
                          style: FuturisticTypography.heading1.copyWith(
                            fontSize: 56,
                            color: _getBalanceColor(state.balanceScore),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '/100',
                          style: FuturisticTypography.heading2.copyWith(
                            color: FuturisticColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: state.balanceScore / 100,
                        minHeight: 12,
                        backgroundColor: FuturisticColors.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getBalanceColor(state.balanceScore),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getBalanceMessage(state.balanceScore),
                      style: FuturisticTypography.bodyMedium.copyWith(
                        color: _getBalanceColor(state.balanceScore),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        // Teams or Generate Button
        Expanded(
          child: state.hasGenerated
              ? _buildTeamsView(state, controller)
              : _buildGenerateView(state),
        ),

        // Bottom Actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FuturisticColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (state.hasGenerated) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.isGenerating ? null : _generateTeams,
                    icon: const Icon(Icons.refresh),
                    label: const Text('צור כוחות מחדש'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: state.hasGenerated && !state.isSaving
                      ? _saveTeams
                      : (state.isGenerating ? null : _generateTeams),
                  icon: state.isSaving || state.isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          state.hasGenerated ? Icons.save : Icons.auto_awesome),
                  label: Text(state.isSaving
                      ? 'שומר...'
                      : state.isGenerating
                          ? 'מייצר...'
                          : state.hasGenerated
                              ? 'שמור כוחות'
                              : 'צור כוחות'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: FuturisticColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateView(TeamMakerState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: FuturisticColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups,
                size: 100,
                color: FuturisticColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '${state.players.length} שחקנים רשומים',
              style: FuturisticTypography.heading1,
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.args.teamCount} קבוצות',
              style: FuturisticTypography.heading3.copyWith(
                color: FuturisticColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'לחץ על "צור כוחות" כדי ליצור קבוצות מאוזנות\nעל בסיס דירוגי השחקנים ותפקידיהם',
              style: FuturisticTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsView(TeamMakerState state, TeamMakerController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.teams.length,
      itemBuilder: (context, index) {
        return TeamCard(
          team: state.teams[index],
          teamIndex: index,
          userMap: state.userMap,
          players: state.players,
          onPlayerDropped: (playerId, toTeamIndex) {
            // Find current team of player
            int fromTeamIndex = -1;
            for (int i = 0; i < state.teams.length; i++) {
              if (state.teams[i].playerIds.contains(playerId)) {
                fromTeamIndex = i;
                break;
              }
            }
            if (fromTeamIndex != -1) {
              controller.movePlayer(playerId, fromTeamIndex, toTeamIndex);
            }
          },
          onPlayerTap: (user, player, teamIndex) {
            _showPlayerDialog(user, player, teamIndex, state, controller);
          },
        );
      },
    );
  }

// Methods removed: _buildTeamCard, _buildPlayerCard

  void _showPlayerDialog(User user, PlayerForTeam player, int currentTeamIndex,
      TeamMakerState state, TeamMakerController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FuturisticColors.surface,
        title: Row(
          children: [
            PlayerAvatar(user: user, size: AvatarSize.sm),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user.displayName ?? user.name,
                style: FuturisticTypography.heading3,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('דירוג', player.rating.toStringAsFixed(1)),
            _buildStatRow('תפקיד', _getRoleDisplayName(player.role)),
            const SizedBox(height: 16),
            Text(
              'העבר לקבוצה:',
              style: FuturisticTypography.heading3.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...state.teams.asMap().entries.map((entry) {
              final teamIndex = entry.key;
              final team = entry.value;
              final isCurrent = teamIndex == currentTeamIndex;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: isCurrent
                      ? null
                      : () {
                          controller.movePlayer(
                              player.uid, currentTeamIndex, teamIndex);
                          Navigator.pop(context);
                        },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? FuturisticColors.primary.withOpacity(0.2)
                          : FuturisticColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent
                            ? FuturisticColors.primary
                            : FuturisticColors.surfaceVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: team.colorValue != null
                                ? Color(team.colorValue!)
                                : FuturisticColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            team.name,
                            style: FuturisticTypography.bodyMedium,
                          ),
                        ),
                        if (isCurrent)
                          const Icon(Icons.check, color: Colors.green),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('סגור'),
          ),
          ElevatedButton(
            onPressed: () {
              context.push('/profile/${user.uid}');
              Navigator.pop(context);
            },
            child: const Text('כרטיס שחקן'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: FuturisticTypography.bodySmall.copyWith(
              color: FuturisticColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: FuturisticTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(PlayerRole role) {
    return switch (role) {
      PlayerRole.goalkeeper => 'שוער',
      PlayerRole.defender => 'מגן',
      PlayerRole.midfielder => 'קשר',
      PlayerRole.attacker => 'תוקף',
    };
  }

  Color _getBalanceColor(double score) {
    if (score >= 85) return FuturisticColors.success;
    if (score >= 70) return Colors.green;
    if (score >= 55) return Colors.orange;
    return Colors.red;
  }

  String _getBalanceMessage(double score) {
    if (score >= 90) return 'איזון מושלם! 🎯';
    if (score >= 80) return 'איזון מצוין 👍';
    if (score >= 70) return 'איזון טוב ✓';
    if (score >= 60) return 'איזון סביר';
    return 'מומלץ להתאים';
  }
}
