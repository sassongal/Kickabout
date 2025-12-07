import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'dart:math';

/// Manual team builder with drag-and-drop functionality
class ManualTeamBuilder extends ConsumerStatefulWidget {
  final String gameId;
  final Game game;
  final int teamCount;
  final List<String> playerIds;
  final Function(List<Team>)? onTeamsChanged; // Callback for when teams change
  final bool isEvent; // If true, save teams to Event instead of Game
  final String? eventId; // Event ID if isEvent == true
  final String? hubId; // Hub ID if isEvent == true

  const ManualTeamBuilder({
    super.key,
    required this.gameId,
    required this.game,
    required this.teamCount,
    required this.playerIds,
    this.onTeamsChanged,
    this.isEvent = false,
    this.eventId,
    this.hubId,
  });

  @override
  ConsumerState<ManualTeamBuilder> createState() => _ManualTeamBuilderState();
}

class _ManualTeamBuilderState extends ConsumerState<ManualTeamBuilder> {
  List<List<String>> _teamPlayerIds = [];
  List<User> _allPlayers = [];
  bool _isLoading = false;
  bool _isSaving = false;
  Hub? _hub; // Cache hub for manager ratings
  Map<String, double> _managerRatings = {}; // Cache manager ratings

  // Team colors - predefined neon colors
  static const List<Map<String, dynamic>> _teamColors = [
    {'name': 'כחול', 'color': 0xFF2196F3, 'value': 0xFF2196F3},
    {'name': 'אדום', 'color': 0xFFF44336, 'value': 0xFFF44336},
    {'name': 'ירוק', 'color': 0xFF4CAF50, 'value': 0xFF4CAF50},
    {'name': 'כתום', 'color': 0xFFFF9800, 'value': 0xFFFF9800},
    {'name': 'סגול', 'color': 0xFF9C27B0, 'value': 0xFF9C27B0},
    {'name': 'צהוב', 'color': 0xFFFFEB3B, 'value': 0xFFFFEB3B},
    {'name': 'ורוד', 'color': 0xFFE91E63, 'value': 0xFFE91E63},
    {'name': 'טורקיז', 'color': 0xFF00BCD4, 'value': 0xFF00BCD4},
  ];

  // Current team colors (index -> color map)
  final Map<int, Map<String, dynamic>> _teamColorMap = {};

  @override
  void initState() {
    super.initState();
    _initializeTeams();
    _loadDraft(); // Load draft first, then load players
    _loadHub();
    _loadPlayers();
  }

  Future<void> _loadHub() async {
    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      if (widget.game.hubId != null) {
        final hub = await hubsRepo.getHub(widget.game.hubId!);

        // Load manager ratings from HubMember subcollection
        final hubMembers = await hubsRepo.getHubMembers(widget.game.hubId!);
        final ratings = <String, double>{};
        for (final member in hubMembers) {
          if (member.managerRating > 0) {
            ratings[member.userId] = member.managerRating;
          }
        }

        if (mounted) {
          setState(() {
            _hub = hub;
            _managerRatings = ratings;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load hub: $e');
    }
  }

  /// Get player rating - uses manager rating if available, otherwise defaults to 4.0
  double _getPlayerRating(User user) {
    // Use manager rating as single source of truth
    return _managerRatings[user.uid] ?? 4.0;
  }

  void _initializeTeams() {
    _teamPlayerIds = List.generate(
      widget.teamCount,
      (_) => <String>[],
    );

    // Initialize colors from existing teams or assign defaults
    for (int i = 0; i < widget.teamCount; i++) {
      if (widget.game.teams.length > i && widget.game.teams[i].color != null) {
        // Use existing color if available
        final existingColor = widget.game.teams[i].color;
        final colorData = _teamColors.firstWhere(
          (c) => c['name'] == existingColor,
          orElse: () => _teamColors[i % _teamColors.length],
        );
        _teamColorMap[i] = colorData;
      } else {
        // Assign default color
        _teamColorMap[i] = _teamColors[i % _teamColors.length];
      }
    }
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
      // Create Team objects
      final teamNames = ['קבוצה א', 'קבוצה ב', 'קבוצה ג', 'קבוצה ד'];
      final teams = _teamPlayerIds.asMap().entries.map((entry) {
        final index = entry.key;
        final playerIds = entry.value;

        // Calculate total score using manager ratings
        final totalScore = _allPlayers
            .where((p) => playerIds.contains(p.uid))
            .fold<double>(0.0, (sum, player) => sum + _getPlayerRating(player));

        final colorData =
            _teamColorMap[index] ?? _teamColors[index % _teamColors.length];
        return Team(
          teamId: 'team_$index',
          name: teamNames[index],
          playerIds: playerIds,
          totalScore: totalScore,
          color: colorData['name'] as String,
          colorValue: colorData['value'] as int,
        );
      }).toList();

      if (widget.isEvent && widget.eventId != null && widget.hubId != null) {
        // Save teams to Event
        final hubEventsRepo = ref.read(hubEventsRepositoryProvider);
        await hubEventsRepo.saveTeamsForEvent(
            widget.hubId!, widget.eventId!, teams);
      } else {
        // Save teams to Game (original behavior)
        final gamesRepo = ref.read(gamesRepositoryProvider);
        final teamsRepo = ref.read(teamsRepositoryProvider);

        // Save teams to game document
        await gamesRepo.saveTeamsForGame(widget.gameId, teams);

        // Also save to teams subcollection (for backward compatibility)
        await teamsRepo.setTeams(widget.gameId, teams);

        // Update game status to teamsFormed
        await gamesRepo.updateGameStatus(widget.gameId, GameStatus.teamsFormed);
      }

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

  void _shuffleAndDistribute() {
    final shuffled = List<User>.from(_allPlayers)..shuffle(Random());
    final newTeams = List.generate(widget.teamCount, (_) => <String>[]);
    for (int i = 0; i < shuffled.length; i++) {
      newTeams[i % widget.teamCount].add(shuffled[i].uid);
    }

    setState(() {
      _teamPlayerIds = newTeams;
    });
    _notifyTeamsChanged();
    _saveDraft();
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

        // Calculate total score using manager ratings
        final totalScore = _allPlayers
            .where((p) => playerIds.contains(p.uid))
            .fold<double>(0.0, (sum, player) => sum + _getPlayerRating(player));

        final colorData =
            _teamColorMap[index] ?? _teamColors[index % _teamColors.length];
        return Team(
          teamId: 'team_$index',
          name: teamNames[index],
          playerIds: playerIds,
          totalScore: totalScore,
          color: colorData['name'] as String,
          colorValue: colorData['value'] as int,
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
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _shuffleAndDistribute,
                icon: const Icon(Icons.shuffle),
                label: const Text('ערבב'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                ),
              ),
              const SizedBox(width: 12),
              if (widget.onTeamsChanged == null)
                Expanded(
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
            ],
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
                  border:
                      Border.all(color: Colors.grey, style: BorderStyle.solid),
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
                                  'דירוג: ${_getPlayerRating(player).toStringAsFixed(1)}',
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
    final teamPlayers =
        _allPlayers.where((player) => playerIds.contains(player.uid)).toList();

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(
          color:
              Color(_teamColorMap[teamIndex]?['value'] as int? ?? 0xFF2196F3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(
                      _teamColorMap[teamIndex]?['value'] as int? ?? 0xFF2196F3)
                  .withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Color picker button
                InkWell(
                  onTap: () => _showColorPicker(teamIndex),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(_teamColorMap[teamIndex]?['value'] as int? ??
                          0xFF2196F3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                // Team name and count
                Expanded(
                  child: Text(
                    '$teamName (${playerIds.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Spacer for alignment
                const SizedBox(width: 32),
              ],
            ),
          ),
          Expanded(
            child: DragTarget<String>(
              onAcceptWithDetails: (details) =>
                  _onPlayerDropped(details.data, teamIndex),
              builder: (context, candidateData, rejectedData) {
                return Container(
                  color: candidateData.isNotEmpty
                      ? Color(_teamColorMap[teamIndex]?['value'] as int? ??
                              0xFF2196F3)
                          .withValues(alpha: 0.2)
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

  Future<void> _showColorPicker(int teamIndex) async {
    final selectedColor = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('בחר צבע ל${teamNames[teamIndex]}'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _teamColors.length,
            itemBuilder: (context, index) {
              final colorData = _teamColors[index];
              final isSelected =
                  _teamColorMap[teamIndex]?['name'] == colorData['name'];

              return InkWell(
                onTap: () => Navigator.pop(context, colorData),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(colorData['value'] as int),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.grey,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : null,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );

    if (selectedColor != null) {
      setState(() {
        _teamColorMap[teamIndex] = selectedColor;
        _notifyTeamsChanged();
      });
    }
  }

  List<String> get teamNames => ['קבוצה א', 'קבוצה ב', 'קבוצה ג', 'קבוצה ד'];
}
