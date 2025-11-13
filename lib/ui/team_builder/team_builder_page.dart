import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/logic/team_maker.dart';
import 'package:kickadoor/models/models.dart';

/// Team builder page with draggable chips and balance meter
class TeamBuilderPage extends ConsumerStatefulWidget {
  final String gameId;
  final int teamCount;
  final List<String> playerIds;

  const TeamBuilderPage({
    super.key,
    required this.gameId,
    required this.teamCount,
    required this.playerIds,
  });

  @override
  ConsumerState<TeamBuilderPage> createState() => _TeamBuilderPageState();
}

class _TeamBuilderPageState extends ConsumerState<TeamBuilderPage> {
  List<Team> _teams = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    final teamsRepo = ref.read(teamsRepositoryProvider);
    final teams = await teamsRepo.getTeams(widget.gameId);
    
    if (mounted) {
      setState(() {
        _teams = teams;
      });
    }
  }

  Future<void> _autoBalance() async {
    if (widget.playerIds.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      final users = await usersRepo.getUsers(widget.playerIds);

      final players = users.map((u) => PlayerForTeam.fromUser(u)).toList();
      final teams = TeamMaker.createBalancedTeams(
        players,
        teamCount: widget.teamCount,
      );

      if (mounted) {
        setState(() {
          _teams = teams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה באיזון: $e')),
        );
      }
    }
  }

  Future<void> _saveTeams() async {
    if (_teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('אין קבוצות לשמירה')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final teamsRepo = ref.read(teamsRepositoryProvider);
      await teamsRepo.setTeams(widget.gameId, _teams);

      // Update game status to teamsFormed
      final gamesRepo = ref.read(gamesRepositoryProvider);
      await gamesRepo.updateGameStatus(widget.gameId, GameStatus.teamsFormed);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הקבוצות נשמרו בהצלחה!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בשמירה: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _teams.isNotEmpty
        ? TeamMaker.calculateBalanceMetrics(_teams)
        : null;

    return Column(
      children: [
        // Balance meter
        if (metrics != null)
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'איזון קבוצות',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'סטיית תקן: ${metrics.stddev.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (1.0 - (metrics.stddev / 5.0)).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    metrics.stddev < 0.5
                        ? Colors.green
                        : metrics.stddev < 1.0
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metrics.stddev < 0.5
                      ? 'מאוזן היטב'
                      : metrics.stddev < 1.0
                          ? 'מאוזן'
                          : 'לא מאוזן',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _autoBalance,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: const Text('איזון אוטומטי'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving || _teams.isEmpty ? null : _saveTeams,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('שמור קבוצות'),
                ),
              ),
            ],
          ),
        ),

        // Teams display
        Expanded(
          child: _teams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'לחץ על "איזון אוטומטי" כדי ליצור קבוצות',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Row(
                  children: List.generate(widget.teamCount, (index) {
                    final team = index < _teams.length ? _teams[index] : null;
                    return Expanded(
                      child: _buildTeamColumn(context, index, team),
                    );
                  }),
                ),
        ),
      ],
    );
  }

  Widget _buildTeamColumn(BuildContext context, int index, Team? team) {
    final teamNames = ['קבוצה א', 'קבוצה ב', 'קבוצה ג', 'קבוצה ד'];
    final teamColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: teamColors[index % teamColors.length].withValues(alpha: 0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: teamColors[index % teamColors.length].withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  team?.name ?? teamNames[index],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (team != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${team.playerIds.length})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: team == null || team.playerIds.isEmpty
                ? Center(
                    child: Text(
                      'ריק',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : FutureBuilder<List<User>>(
                    future: ref.read(usersRepositoryProvider).getUsers(team.playerIds),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final users = snapshot.data ?? [];

                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: users.length,
                        itemBuilder: (context, userIndex) {
                          final user = users[userIndex];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: teamColors[index % teamColors.length]
                                    .withValues(alpha: 0.2),
                                child: user.photoUrl != null
                                    ? ClipOval(
                                        child: Image.network(
                                          user.photoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.person,
                                            size: 16,
                                            color: teamColors[index % teamColors.length],
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 16,
                                        color: teamColors[index % teamColors.length],
                                      ),
                              ),
                              title: Text(
                                user.name,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              trailing: Text(
                                user.currentRankScore.toStringAsFixed(1),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          if (team != null && team.playerIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: teamColors[index % teamColors.length].withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Text(
                'ממוצע: ${(team.totalScore / team.playerIds.length).toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

