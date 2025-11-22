import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';

/// Manual team builder with drag-and-drop functionality
class ManualTeamBuilder extends ConsumerStatefulWidget {
  final String gameId;
  final Game game;
  final int teamCount;
  final List<String> playerIds;
  final Function(List<Team>)? onTeamsChanged; // Callback for when teams change

  const ManualTeamBuilder({
    super.key,
    required this.gameId,
    required this.game,
    required this.teamCount,
    required this.playerIds,
    this.onTeamsChanged,
  });

  @override
  ConsumerState<ManualTeamBuilder> createState() => _ManualTeamBuilderState();
}

class _ManualTeamBuilderState extends ConsumerState<ManualTeamBuilder> {
  List<List<String>> _teamPlayerIds = [];
  List<User> _allPlayers = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeTeams();
    _loadDraft(); // Load draft first, then load players
    _loadPlayers();
  }

  void _initializeTeams() {
    _teamPlayerIds = List.generate(
      widget.teamCount,
      (_) => <String>[],
    );
  }

  /// Load draft from SharedPreferences
  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftKey = 'teammaker_draft_${widget.gameId}';
      final draftJson = prefs.getString(draftKey);
      
      if (draftJson != null) {
        final draft = jsonDecode(draftJson) as Map<String, dynamic>;
        final savedTeamCount = draft['teamCount'] as int?;
        final savedTeamPlayerIds = draft['teamPlayerIds'] as List<dynamic>?;
        
        // Only load if team count matches
        if (savedTeamCount == widget.teamCount && savedTeamPlayerIds != null) {
          setState(() {
            _teamPlayerIds = savedTeamPlayerIds
                .map((team) => (team as List<dynamic>).cast<String>())
                .toList();
          });
        }
      }
    } catch (e) {
      // If draft loading fails, just use empty teams
      debugPrint('Failed to load draft: $e');
    }
  }

  /// Save draft to SharedPreferences
  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftKey = 'teammaker_draft_${widget.gameId}';
      final draft = {
        'teamCount': widget.teamCount,
        'teamPlayerIds': _teamPlayerIds,
        'savedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(draftKey, jsonEncode(draft));
    } catch (e) {
      debugPrint('Failed to save draft: $e');
    }
  }

  /// Clear draft from SharedPreferences
  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftKey = 'teammaker_draft_${widget.gameId}';
      await prefs.remove(draftKey);
    } catch (e) {
      debugPrint('Failed to clear draft: $e');
    }
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);
    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      final players = await usersRepo.getUsers(widget.playerIds);
      
      if (mounted) {
        setState(() {
          _allPlayers = players;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת שחקנים: $e')),
        );
      }
    }
  }

  Future<void> _saveTeams() async {
    if (_teamPlayerIds.any((team) => team.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('יש לפחות קבוצה אחת ריקה')),
      );
      return;
    }

    // Check that all players are assigned
    final assignedPlayers = _teamPlayerIds.expand((team) => team).toSet();
    if (assignedPlayers.length != widget.playerIds.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('יש שחקנים שלא הוקצו לקבוצה')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);
      final teamsRepo = ref.read(teamsRepositoryProvider);

      // Create Team objects
      final teamNames = ['קבוצה א', 'קבוצה ב', 'קבוצה ג', 'קבוצה ד'];
      final teams = _teamPlayerIds.asMap().entries.map((entry) {
        final index = entry.key;
        final playerIds = entry.value;
        
        // Calculate total score
        final totalScore = _allPlayers
            .where((p) => playerIds.contains(p.uid))
            .fold<double>(0.0, (sum, player) => sum + player.currentRankScore);

        return Team(
          teamId: 'team_$index',
          name: teamNames[index],
          playerIds: playerIds,
          totalScore: totalScore,
          color: widget.game.teams.length > index
              ? widget.game.teams[index].color
              : null,
        );
      }).toList();

      // Save teams to game document
      await gamesRepo.saveTeamsForGame(widget.gameId, teams);

      // Also save to teams subcollection (for backward compatibility)
      await teamsRepo.setTeams(widget.gameId, teams);

      // Update game status to teamsFormed
      await gamesRepo.updateGameStatus(widget.gameId, GameStatus.teamsFormed);

      // Clear draft after successful save
      await _clearDraft();

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

  void _onPlayerDropped(String playerId, int targetTeamIndex) {
    setState(() {
      // Remove player from all teams
      for (final team in _teamPlayerIds) {
        team.remove(playerId);
      }
      
      // Add to target team
      _teamPlayerIds[targetTeamIndex].add(playerId);
      
      // Notify callback if provided
      _notifyTeamsChanged();
      
      // Auto-save draft after any change
      _saveDraft();
    });
  }

  void _notifyTeamsChanged() {
    if (widget.onTeamsChanged != null) {
      final teamNames = ['קבוצה א', 'קבוצה ב', 'קבוצה ג', 'קבוצה ד'];
      final teams = _teamPlayerIds.asMap().entries.map((entry) {
        final index = entry.key;
        final playerIds = entry.value;
        
        // Calculate total score
        final totalScore = _allPlayers
            .where((p) => playerIds.contains(p.uid))
            .fold<double>(0.0, (sum, player) => sum + player.currentRankScore);

        return Team(
          teamId: 'team_$index',
          name: teamNames[index],
          playerIds: playerIds,
          totalScore: totalScore,
          color: widget.game.teams.length > index
              ? widget.game.teams[index].color
              : null,
        );
      }).toList();
      
      widget.onTeamsChanged!(teams);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get unassigned players
    final assignedPlayers = _teamPlayerIds.expand((team) => team).toSet();
    final unassignedPlayers = _allPlayers
        .where((player) => !assignedPlayers.contains(player.uid))
        .toList();

    final teamNames = ['קבוצה א', 'קבוצה ב', 'קבוצה ג', 'קבוצה ד'];

    return Column(
      children: [
        // Save button (only if no callback provided)
        if (widget.onTeamsChanged == null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveTeams,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'שומר...' : 'שמור קבוצות'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

        // Teams and unassigned players
        Expanded(
          child: Row(
            children: [
              // Teams columns
              ...List.generate(widget.teamCount, (index) {
                return Expanded(
                  child: _buildTeamColumn(
                    context,
                    teamNames[index],
                    index,
                    _teamPlayerIds[index],
                  ),
                );
              }),
              
              // Unassigned players column
              Container(
                width: 200,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                      child: Text(
                        'שחקנים לא מוקצים (${unassignedPlayers.length})',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: unassignedPlayers.length,
                        itemBuilder: (context, playerIndex) {
                          final player = unassignedPlayers[playerIndex];
                          return Draggable<String>(
                            data: player.uid,
                            feedback: Material(
                              elevation: 4,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  player.name,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 4),
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 16,
                                  child: Text(
                                    player.name[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                title: Text(
                                  player.name,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                subtitle: Text(
                                  'דירוג: ${player.currentRankScore.toStringAsFixed(1)}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamColumn(
    BuildContext context,
    String teamName,
    int teamIndex,
    List<String> playerIds,
  ) {
    final teamPlayers = _allPlayers
        .where((player) => playerIds.contains(player.uid))
        .toList();

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Text(
              '$teamName (${playerIds.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: DragTarget<String>(
              onAccept: (playerId) => _onPlayerDropped(playerId, teamIndex),
              builder: (context, candidateData, rejectedData) {
                return Container(
                  color: candidateData.isNotEmpty
                      ? Colors.blue.withValues(alpha: 0.2)
                      : Colors.transparent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: teamPlayers.length,
                    itemBuilder: (context, index) {
                      final player = teamPlayers[index];
                      return Draggable<String>(
                        data: player.uid,
                        feedback: Material(
                          elevation: 4,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              player.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              child: Text(
                                player.name[0].toUpperCase(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            title: Text(
                              player.name,
                              style: const TextStyle(fontSize: 12),
                            ),
                            subtitle: Text(
                              'דירוג: ${player.currentRankScore.toStringAsFixed(1)}',
                              style: const TextStyle(fontSize: 10),
                            ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  setState(() {
                                    playerIds.remove(player.uid);
                                    _notifyTeamsChanged();
                                    // Auto-save draft after any change
                                    _saveDraft();
                                  });
                                },
                              ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

