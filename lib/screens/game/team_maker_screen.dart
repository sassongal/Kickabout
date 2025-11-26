import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/l10n/app_localizations.dart';
import 'package:kickadoor/logic/team_maker.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_card.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/models/hub_role.dart';
import 'package:kickadoor/core/constants.dart';
import 'package:kickadoor/widgets/player_avatar.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Premium team maker screen with advanced UI
class TeamMakerScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (isEvent) {
      return _buildForEvent(context, ref, l10n);
    } else {
      return _buildForGame(context, ref, l10n);
    }
  }

  Widget _buildForEvent(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    if (hubId == null) {
      return FuturisticScaffold(
        title: l10n.teamFormation,
        body: Center(child: Text(l10n.errorMissingHubId)),
      );
    }

    final hubEventsRepo = ref.watch(hubEventsRepositoryProvider);

    return FuturisticScaffold(
      title: 'יוצר כוחות',
      body: FutureBuilder<HubEvent?>(
        future: hubEventsRepo.getHubEvent(hubId!, gameId),
        builder: (context, eventSnapshot) {
          if (eventSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

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

          final event = eventSnapshot.data;
          if (event == null) {
            return Center(child: Text(l10n.eventNotFound));
          }

          // Check admin permissions
          final roleAsync = ref.watch(hubRoleProvider(hubId!));
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
                playerIds: registeredPlayerIds,
                teamCount: event.teamCount,
                hubId: hubId!,
                isEvent: true,
                eventId: gameId,
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
  final List<String> playerIds;
  final int teamCount;
  final String hubId;
  final bool isEvent;
  final String? eventId;
  final String? gameId;

  const PremiumTeamBuilder({
    super.key,
    required this.playerIds,
    required this.teamCount,
    required this.hubId,
    required this.isEvent,
    this.eventId,
    this.gameId,
  });

  @override
  ConsumerState<PremiumTeamBuilder> createState() => _PremiumTeamBuilderState();
}

class _PremiumTeamBuilderState extends ConsumerState<PremiumTeamBuilder> {
  List<PlayerForTeam> _players = [];
  List<Team> _teams = [];
  Map<String, User> _userMap = {};
  double _balanceScore = 0.0;
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isSaving = false;
  bool _hasGenerated = false;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);
    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      final hub = await ref.read(hubsRepositoryProvider).getHub(widget.hubId);
      final managerRatings = hub?.managerRatings ?? {};

      final users = await usersRepo.getUsers(widget.playerIds);

      _userMap = {for (var user in users) user.uid: user};
      _players = users
          .map((user) => PlayerForTeam.fromUser(user,
              hubId: widget.hubId, managerRatings: managerRatings))
          .toList();

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  void _generateTeams() async {
    setState(() => _isGenerating = true);

    await Future.delayed(const Duration(milliseconds: 500)); // For UX

    final result = TeamMaker.createBalancedTeams(
      _players,
      teamCount: widget.teamCount,
    );

    if (mounted) {
      setState(() {
        _teams = result.teams;
        _balanceScore = result.balanceScore;
        _hasGenerated = true;
        _isGenerating = false;
      });
    }
  }

  void _movePlayer(String playerId, int fromTeamIndex, int toTeamIndex) {
    if (fromTeamIndex == toTeamIndex) return;

    final player = _players.firstWhere((p) => p.uid == playerId);

    setState(() {
      final fromTeam = _teams[fromTeamIndex];
      final toTeam = _teams[toTeamIndex];

      final newFromPlayerIds = List<String>.from(fromTeam.playerIds)
        ..remove(playerId);
      final newFromScore = fromTeam.totalScore - player.rating;

      final newToPlayerIds = List<String>.from(toTeam.playerIds)..add(playerId);
      final newToScore = toTeam.totalScore + player.rating;

      _teams[fromTeamIndex] = fromTeam.copyWith(
        playerIds: newFromPlayerIds,
        totalScore: newFromScore,
      );
      _teams[toTeamIndex] = toTeam.copyWith(
        playerIds: newToPlayerIds,
        totalScore: newToScore,
      );

      final metrics = TeamMaker.calculateBalanceMetrics(_teams);
      _balanceScore = (1.0 - (metrics.stddev / 5.0)).clamp(0.0, 1.0) * 100;
    });
  }

  Future<void> _saveTeams() async {
    setState(() => _isSaving = true);

    try {
      if (widget.isEvent && widget.eventId != null) {
        final eventsRepo = ref.read(hubEventsRepositoryProvider);
        await eventsRepo.updateHubEvent(
          widget.hubId,
          widget.eventId!,
          {
            'teams': _teams.map((t) => t.toJson()).toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'הכוחות נשמרו בהצלחה! 🎉');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Balance Score Card (only show after generation)
        if (_hasGenerated) ...[
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
                          _balanceScore.toStringAsFixed(1),
                          style: FuturisticTypography.heading1.copyWith(
                            fontSize: 56,
                            color: _getBalanceColor(_balanceScore),
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
                        value: _balanceScore / 100,
                        minHeight: 12,
                        backgroundColor: FuturisticColors.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getBalanceColor(_balanceScore),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getBalanceMessage(_balanceScore),
                      style: FuturisticTypography.bodyMedium.copyWith(
                        color: _getBalanceColor(_balanceScore),
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
          child: _hasGenerated ? _buildTeamsView() : _buildGenerateView(),
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
              if (_hasGenerated) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isGenerating ? null : _generateTeams,
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
                  onPressed: _hasGenerated && !_isSaving
                      ? _saveTeams
                      : (_isGenerating ? null : _generateTeams),
                  icon: _isSaving || _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(_hasGenerated ? Icons.save : Icons.auto_awesome),
                  label: Text(_isSaving
                      ? 'שומר...'
                      : _isGenerating
                          ? 'מייצר...'
                          : _hasGenerated
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

  Widget _buildGenerateView() {
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
              '${_players.length} שחקנים רשומים',
              style: FuturisticTypography.heading1,
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.teamCount} קבוצות',
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

  Widget _buildTeamsView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _teams.length,
      itemBuilder: (context, index) => _buildTeamCard(index),
    );
  }

  Widget _buildTeamCard(int teamIndex) {
    final team = _teams[teamIndex];
    final teamColor = team.colorValue != null
        ? Color(team.colorValue!)
        : FuturisticColors.primary;
    final avgRating =
        team.playerIds.isEmpty ? 0.0 : team.totalScore / team.playerIds.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FuturisticCard(
        child: Column(
          children: [
            // Team Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    teamColor,
                    teamColor.withOpacity(0.7),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            team.name[0],
                            style: TextStyle(
                              color: teamColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        team.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${team.playerIds.length} שחקנים',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        avgRating.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Players
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: team.playerIds.map((playerId) {
                  final user = _userMap[playerId];
                  final player = _players.firstWhere((p) => p.uid == playerId);

                  if (user == null) return const SizedBox.shrink();

                  return _buildPlayerCard(user, player, teamIndex);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(User user, PlayerForTeam player, int teamIndex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showPlayerDialog(user, player, teamIndex),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FuturisticColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FuturisticColors.surfaceVariant),
          ),
          child: Row(
            children: [
              PlayerAvatar(
                user: user,
                size: AvatarSize.md,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? user.name,
                      style: FuturisticTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          _getRoleIcon(player.role),
                          size: 14,
                          color: FuturisticColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getRoleDisplayName(player.role),
                          style: FuturisticTypography.bodySmall.copyWith(
                            color: FuturisticColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      FuturisticColors.primary,
                      FuturisticColors.accent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  player.rating.toStringAsFixed(1),
                  style: FuturisticTypography.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.drag_indicator,
                color: FuturisticColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlayerDialog(
      User user, PlayerForTeam player, int currentTeamIndex) {
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
            ..._teams.asMap().entries.map((entry) {
              final teamIndex = entry.key;
              final team = entry.value;
              final isCurrent = teamIndex == currentTeamIndex;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: isCurrent
                      ? null
                      : () {
                          _movePlayer(player.uid, currentTeamIndex, teamIndex);
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

  IconData _getRoleIcon(PlayerRole role) {
    return switch (role) {
      PlayerRole.goalkeeper => Icons.sports_soccer,
      PlayerRole.defender => Icons.shield,
      PlayerRole.midfielder => Icons.sports,
      PlayerRole.attacker => Icons.flash_on,
    };
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
