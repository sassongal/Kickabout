import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kattrick/models/models.dart';

/// Dialog for editing a finalized game result
///
/// Allows managers to:
/// - Update team scores
/// - Modify goal scorers and assist providers
/// - Change MVP selection
class EditGameResultDialog extends StatefulWidget {
  final Game game;
  final List<User> players;
  final Function({
    required int teamAScore,
    required int teamBScore,
    required Map<String, int> goalScorerIds,
    Map<String, int>? assistPlayerIds,
    String? mvpPlayerId,
  }) onSave;

  const EditGameResultDialog({
    super.key,
    required this.game,
    required this.players,
    required this.onSave,
  });

  @override
  State<EditGameResultDialog> createState() => _EditGameResultDialogState();
}

class _EditGameResultDialogState extends State<EditGameResultDialog> {
  late TextEditingController _teamAScoreController;
  late TextEditingController _teamBScoreController;

  final Map<String, int> _goalScorers = {};
  final Map<String, int> _assistProviders = {};
  String? _mvpPlayerId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize with current values
    _teamAScoreController = TextEditingController(
      text: (widget.game.session.legacyTeamAScore ?? 0).toString(),
    );
    _teamBScoreController = TextEditingController(
      text: (widget.game.session.legacyTeamBScore ?? 0).toString(),
    );

    // Initialize goal scorers from game data
    if (widget.game.denormalized.goalScorerIds.isNotEmpty) {
      for (final scorerId in widget.game.denormalized.goalScorerIds) {
        _goalScorers[scorerId] = (_goalScorers[scorerId] ?? 0) + 1;
      }
    }
    if (widget.game.denormalized.mvpPlayerId != null) {
      _mvpPlayerId = widget.game.denormalized.mvpPlayerId;
    }
  }

  @override
  void dispose() {
    _teamAScoreController.dispose();
    _teamBScoreController.dispose();
    super.dispose();
  }

  void _incrementGoals(String playerId) {
    setState(() {
      _goalScorers[playerId] = (_goalScorers[playerId] ?? 0) + 1;
    });
  }

  void _decrementGoals(String playerId) {
    setState(() {
      final current = _goalScorers[playerId] ?? 0;
      if (current > 0) {
        _goalScorers[playerId] = current - 1;
        if (_goalScorers[playerId] == 0) {
          _goalScorers.remove(playerId);
        }
      }
    });
  }

  void _incrementAssists(String playerId) {
    setState(() {
      _assistProviders[playerId] = (_assistProviders[playerId] ?? 0) + 1;
    });
  }

  void _decrementAssists(String playerId) {
    setState(() {
      final current = _assistProviders[playerId] ?? 0;
      if (current > 0) {
        _assistProviders[playerId] = current - 1;
        if (_assistProviders[playerId] == 0) {
          _assistProviders.remove(playerId);
        }
      }
    });
  }

  Future<void> _handleSave() async {
    final teamAScore = int.tryParse(_teamAScoreController.text) ?? 0;
    final teamBScore = int.tryParse(_teamBScoreController.text) ?? 0;

    if (teamAScore < 0 || teamBScore < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scores cannot be negative')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.onSave(
        teamAScore: teamAScore,
        teamBScore: teamBScore,
        goalScorerIds: _goalScorers,
        assistPlayerIds: _assistProviders.isNotEmpty ? _assistProviders : null,
        mvpPlayerId: _mvpPlayerId,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teamAName =
        widget.game.teams.isNotEmpty ? widget.game.teams[0].name : 'Team A';
    final teamBName =
        widget.game.teams.length > 1 ? widget.game.teams[1].name : 'Team B';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.edit, color: theme.primaryColor),
                const SizedBox(width: 12),
                Text('ערוך תוצאה', style: theme.textTheme.headlineMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Warning message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'פעולה זו תבטל את התוצאה הקודמת ותחשב מחדש את סטטיסטיקות השחקנים',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Scores Section
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(teamAName, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _teamAScoreController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          labelText: 'Score',
                          border: const OutlineInputBorder(),
                          prefixIcon:
                              Icon(Icons.score, color: theme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Text('vs', style: theme.textTheme.headlineSmall),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(teamBName, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _teamBScoreController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          labelText: 'Score',
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(Icons.score, color: Colors.pink),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Players Section (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Goal Scorers
                    Text('שוערים', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...widget.players.map((player) {
                      final goalCount = _goalScorers[player.uid] ?? 0;
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundImage: player.photoUrl != null
                              ? NetworkImage(player.photoUrl!)
                              : null,
                          child: player.photoUrl == null
                              ? Text(player.name[0].toUpperCase())
                              : null,
                        ),
                        title: Text(player.displayName ?? player.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: goalCount > 0
                                  ? () => _decrementGoals(player.uid)
                                  : null,
                            ),
                            SizedBox(
                              width: 40,
                              child: Center(
                                child: Text(
                                  goalCount.toString(),
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => _incrementGoals(player.uid),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Assist Providers
                    Text('בישולים', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...widget.players.map((player) {
                      final assistCount = _assistProviders[player.uid] ?? 0;
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundImage: player.photoUrl != null
                              ? NetworkImage(player.photoUrl!)
                              : null,
                          child: player.photoUrl == null
                              ? Text(player.name[0].toUpperCase())
                              : null,
                        ),
                        title: Text(player.displayName ?? player.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: assistCount > 0
                                  ? () => _decrementAssists(player.uid)
                                  : null,
                            ),
                            SizedBox(
                              width: 40,
                              child: Center(
                                child: Text(
                                  assistCount.toString(),
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => _incrementAssists(player.uid),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // MVP Selection
                    Text('MVP', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _mvpPlayerId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'בחר MVP',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...widget.players.map((player) {
                          return DropdownMenuItem<String>(
                            value: player.uid,
                            child: Text(player.displayName ?? player.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _mvpPlayerId = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('ביטול'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('שמור שינויים'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
