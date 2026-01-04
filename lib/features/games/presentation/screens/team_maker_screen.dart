import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:kattrick/core/constants.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/features/games/domain/models/team_maker.dart';
import 'package:kattrick/features/games/domain/services/team_image_generator.dart';
import 'package:kattrick/features/games/presentation/screens/team_maker_controller.dart';
import 'package:kattrick/l10n/app_localizations.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';
import 'package:kattrick/widgets/common/premium_scaffold.dart';
import 'package:kattrick/widgets/dialogs/unrated_players_warning_dialog.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:kattrick/widgets/team_card.dart';

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
      return PremiumScaffold(
        title: l10n.teamFormation,
        body: Center(child: Text(l10n.errorMissingHubId)),
      );
    }

    final hubEventsRepo = ref.watch(hubEventsRepositoryProvider);

    // Use a key to ensure this builder is identified
    return PremiumScaffold(
      title: 'יוצר כוחות',
      actions: [
        // Button to navigate to player ratings screen filtered by event
        IconButton(
          icon: const Icon(Icons.star_rate),
          tooltip: 'דירוג שחקנים',
          onPressed: () {
            context.push('/hubs/${widget.hubId}/players?eventId=${widget.gameId}');
          },
        ),
      ],
      body: FutureBuilder<HubEvent?>(
        // Create a memoized future or rely on repo caching.
        // We rely on the repo's internal caching for now.
        future: hubEventsRepo.getHubEvent(widget.hubId!, widget.gameId),
        builder: (context, eventSnapshot) {
          // 1. Handle Loading (only if we have no data at all)
          if (eventSnapshot.connectionState == ConnectionState.waiting &&
              !eventSnapshot.hasData) {
            return const Center(child: KineticLoadingAnimation(size: 48));
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
            return const Center(child: KineticLoadingAnimation(size: 48));
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
                        color: PremiumColors.warning,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.notEnoughRegisteredPlayers,
                        style: PremiumTypography.heading2,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.requiredPlayersCount(
                            event.teamCount * AppConstants.minPlayersPerTeam),
                        style: PremiumTypography.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.registeredPlayerCount(registeredPlayerIds.length),
                        style: PremiumTypography.bodySmall,
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
            loading: () =>
                const Center(child: KineticLoadingAnimation(size: 48)),
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
    return PremiumScaffold(
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
      // Navigate to home screen instead of just popping
      context.go('/');
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
      return const Center(child: KineticLoadingAnimation(size: 64));
    }

    return Column(
      children: [
        // Balance Score Card (only show after generation) - Compact Premium Design
        if (state.hasGenerated) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    PremiumColors.primary.withValues(alpha: 0.1),
                    PremiumColors.secondary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: PremiumColors.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: PremiumColors.primary.withValues(alpha: 0.1),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Balance Score (Compact)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ניקוד איזון',
                            style: PremiumTypography.labelMedium.copyWith(
                              color: PremiumColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                state.balanceScore.toStringAsFixed(1),
                                style: PremiumTypography.heading1.copyWith(
                                  fontSize: 36,
                                  color: _getBalanceColor(state.balanceScore),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4, left: 4),
                                child: Text(
                                  '/100',
                                  style: PremiumTypography.bodyMedium.copyWith(
                                    color: PremiumColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: state.balanceScore / 100,
                              minHeight: 8,
                              backgroundColor: PremiumColors.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getBalanceColor(state.balanceScore),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Action Buttons (Compact)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Magic Wand button (Optimize)
                        OutlinedButton.icon(
                          onPressed: () {
                            controller.optimizeTeams();
                            SnackbarHelper.showSuccess(
                              context,
                              'הכוחות עודכנו לשיפור האיזון! ✨',
                            );
                          },
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('שיפור', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            foregroundColor: PremiumColors.primary,
                            minimumSize: const Size(0, 36),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Share to WhatsApp button with image
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (state.teams.isEmpty) {
                              SnackbarHelper.showError(
                                context,
                                'אין כוחות לשתף',
                              );
                              return;
                            }

                            try {
                              // Show loading indicator
                              SnackbarHelper.showSuccess(
                                context,
                                'מכין תמונה לשיתוף...',
                              );

                              // Generate team image
                              final imageFile = await TeamImageGenerator.generateTeamImage(
                                teams: state.teams,
                                userMap: state.userMap,
                                balanceScore: state.balanceScore,
                              );

                              // Share via WhatsApp or other apps
                              await Share.shareXFiles(
                                [XFile(imageFile.path)],
                                text: '🏆 כוחות המשחק - Kattrick',
                              );
                            } catch (e) {
                              // Fallback to text sharing
                              if (mounted) {
                                final teamsText = controller.generateTeamsText();
                                await Share.share(
                                  teamsText,
                                  subject: 'Kattrick - כוחות המשחק',
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.share, size: 16),
                          label: const Text('שתף', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 36),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Warning if balance is below 80% (Compact)
          if (state.balanceScore < 80)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'הכוחות לא שווים, כדאי לאזן או לנסות שוב',
                        style: PremiumTypography.bodySmall.copyWith(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
            color: PremiumColors.surface,
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
                          child: KineticLoadingAnimation(size: 20),
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
                    backgroundColor: PremiumColors.primary,
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
                color: PremiumColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups,
                size: 100,
                color: PremiumColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '${state.players.length} שחקנים רשומים',
              style: PremiumTypography.heading1,
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.args.teamCount} קבוצות',
              style: PremiumTypography.heading3.copyWith(
                color: PremiumColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'לחץ על "צור כוחות" כדי ליצור קבוצות מאוזנות\nעל בסיס דירוגי השחקנים ותפקידיהם',
              style: PremiumTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            // Info for odd player count
            if (state.players.length % widget.args.teamCount != 0) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'מספר השחקנים אינו מתחלק שווה בשווה.\nהמערכת תאזן את הקבוצות לפי רייטינג ממוצע',
                        style: PremiumTypography.bodySmall.copyWith(
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
          onPlayerTap: (User user, PlayerForTeam player, int teamIndex) {
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
        backgroundColor: PremiumColors.surface,
        title: Row(
          children: [
            PlayerAvatar(user: user, size: AvatarSize.sm),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user.displayName ?? user.name,
                style: PremiumTypography.heading3,
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
              style: PremiumTypography.heading3.copyWith(fontSize: 16),
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
                          ? PremiumColors.primary.withOpacity(0.2)
                          : PremiumColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent
                            ? PremiumColors.primary
                            : PremiumColors.surfaceVariant,
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
                                : PremiumColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            team.name,
                            style: PremiumTypography.bodyMedium,
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
            style: PremiumTypography.bodySmall.copyWith(
              color: PremiumColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: PremiumTypography.bodyMedium.copyWith(
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
    if (score >= 85) return PremiumColors.success;
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
