import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/logic/team_maker.dart';
import 'package:kattrick/models/models.dart';

/// Top-level function for compute isolate - balances teams in background
List<Team> _computeBalanceTeams(Map<String, dynamic> params) {
  final players = (params['players'] as List)
      .map((p) => PlayerForTeam(
            uid: p['uid'] as String,
            rating: p['rating'] as double,
            role: PlayerRole.values.firstWhere((r) => r.name == p['role']),
          ))
      .toList();
  final teamCount = params['teamCount'] as int;

  final result = TeamMaker.createBalancedTeams(
    players,
    teamCount: teamCount,
  );
  return result.teams;
}

/// Team builder page with draggable chips and balance meter
class TeamBuilderPage extends ConsumerStatefulWidget {
  final String gameId;
  final String? hubId; // Added for manager ratings
  final int teamCount;
  final List<String> playerIds;

  const TeamBuilderPage({
    super.key,
    required this.gameId,
    this.hubId,
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
  Hub? _hub; // Cache hub for manager ratings

  @override
  void initState() {
    super.initState();
    _loadHub();
    _loadTeams();
  }

  Future<void> _loadHub() async {
    if (widget.hubId == null) return;
    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final hub = await hubsRepo.getHub(widget.hubId!);
      if (mounted) {
        setState(() {
          _hub = hub;
        });
      }
    } catch (e) {
      debugPrint('Failed to load hub: $e');
    }
  }

  /// Get player rating (manager rating if available, otherwise currentRankScore)
  double _getPlayerRating(User user) {
    if (_hub?.managerRatings != null &&
        _hub!.managerRatings.containsKey(user.uid)) {
      return _hub!.managerRatings[user.uid]!;
    }
    return user.currentRankScore; // Fallback
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
      final hubsRepo = ref.read(hubsRepositoryProvider);

      // Load users and hub (for manager ratings)
      final users = await usersRepo.getUsers(widget.playerIds);
      final hub =
          widget.hubId != null ? await hubsRepo.getHub(widget.hubId!) : null;

      // Use manager ratings if available
      final players = users
          .map((u) => PlayerForTeam.fromUser(
                u,
                hubId: widget.hubId,
                managerRatings: hub?.managerRatings,
              ))
          .toList();

      // Prepare data for compute (must be serializable)
      final playersData = players
          .map((p) => {
                'uid': p.uid,
                'rating': p.rating,
                'role': p.role.name,
              })
          .toList();

      final params = {
        'players': playersData,
        'teamCount': widget.teamCount,
      };

      // Run heavy computation in isolate to prevent UI blocking
      final teams = await compute(_computeBalanceTeams, params);

      // Preserve existing colors when rebalancing
      final existingColors = <String, String>{};
      for (final existingTeam in _teams) {
        if (existingTeam.color != null) {
          existingColors[existingTeam.teamId] = existingTeam.color!;
        }
      }

      // Apply existing colors to new teams (by index)
      final updatedTeams = teams.asMap().entries.map((entry) {
        final index = entry.key;
        final team = entry.value;
        final teamId = 'team_$index';
        final color = existingColors[teamId] ?? _getDefaultColor(index);
        return team.copyWith(color: color);
      }).toList();

      if (mounted) {
        setState(() {
          _teams = updatedTeams;
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
      final gamesRepo = ref.read(gamesRepositoryProvider);

      // Save teams to game document
      await gamesRepo.saveTeamsForGame(widget.gameId, _teams);

      // Also save to teams subcollection (for backward compatibility)
      final teamsRepo = ref.read(teamsRepositoryProvider);
      await teamsRepo.setTeams(widget.gameId, _teams);

      // Update game status to teamsFormed
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
    final metrics =
        _teams.isNotEmpty ? TeamMaker.calculateBalanceMetrics(_teams) : null;

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
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.3),
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

  String _getDefaultColor(int index) {
    const colors = ['red', 'green', 'black', 'yellow', 'blue', 'white'];
    return colors[index % colors.length];
  }

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

  Widget _buildTeamColumn(BuildContext context, int index, Team? team) {
    final teamNames = ['קבוצה א', 'קבוצה ב', 'קבוצה ג', 'קבוצה ד'];
    final currentColor = team?.color ?? _getDefaultColor(index);
    final colorValue = _getColorFromString(currentColor);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: colorValue.withValues(alpha: 0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorValue.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Column(
              children: [
                Row(
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
                if (team != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    alignment: WrapAlignment.center,
                    children: [
                      'red',
                      'green',
                      'black',
                      'yellow',
                      'blue',
                      'white'
                    ].map((colorName) {
                      final isSelected = currentColor == colorName;
                      final color = _getColorFromString(colorName);
                      return ChoiceChip(
                        label: Text(
                          _getColorLabel(colorName),
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.white : color,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _teams[index] = team.copyWith(color: colorName);
                            });
                          }
                        },
                        backgroundColor: color.withValues(alpha: 0.2),
                        selectedColor: color,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      );
                    }).toList(),
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
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                  )
                : FutureBuilder<List<User>>(
                    future: ref
                        .read(usersRepositoryProvider)
                        .getUsers(team.playerIds),
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
                                backgroundColor:
                                    colorValue.withValues(alpha: 0.2),
                                child: user.photoUrl != null
                                    ? ClipOval(
                                        child: Image.network(
                                          user.photoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.person,
                                            size: 16,
                                            color: colorValue,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 16,
                                        color: colorValue,
                                      ),
                              ),
                              title: Text(
                                user.name,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              trailing: Text(
                                _getPlayerRating(user).toStringAsFixed(1),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
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
                color: colorValue.withValues(alpha: 0.05),
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

  String _getColorLabel(String colorName) {
    switch (colorName) {
      case 'red':
        return 'אדום';
      case 'green':
        return 'ירוק';
      case 'black':
        return 'שחור';
      case 'yellow':
        return 'צהוב';
      case 'blue':
        return 'כחול';
      case 'white':
        return 'לבן';
      default:
        return colorName;
    }
  }
}
