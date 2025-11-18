import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/models/enums/event_type.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';

/// Screen for editing/logging game data (score, goals, assists, MVP)
class EditGameScreen extends ConsumerStatefulWidget {
  final String hubId;
  final String gameId;

  const EditGameScreen({
    super.key,
    required this.hubId,
    required this.gameId,
  });

  @override
  ConsumerState<EditGameScreen> createState() => _EditGameScreenState();
}

class _EditGameScreenState extends ConsumerState<EditGameScreen> {
  bool _isLoading = false;
  bool _isLoadingData = true;
  
  Game? _game;
  List<HubEvent> _events = [];
  List<User> _hubMembers = [];
  
  // Form fields
  String? _selectedEventId;
  final _teamAScoreController = TextEditingController();
  final _teamBScoreController = TextEditingController();
  
  // Selected players
  final Set<String> _selectedPlayerIds = {};
  final Set<String> _goalScorers = {};
  final Set<String> _assistProviders = {};
  String? _mvpPlayerId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _teamAScoreController.dispose();
    _teamBScoreController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    
    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);
      final eventsRepo = ref.read(hubEventsRepositoryProvider);
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final usersRepo = ref.read(usersRepositoryProvider);
      final gameEventsRepo = ref.read(eventsRepositoryProvider);
      
      // Load game
      final game = await gamesRepo.getGame(widget.gameId);
      if (game == null) {
        throw Exception('משחק לא נמצא');
      }
      
      // Load events
      final events = await eventsRepo.getHubEvents(widget.hubId);
      
      // Load hub members
      final hub = await hubsRepo.getHub(widget.hubId);
      final memberIds = hub?.memberIds ?? [];
      final members = await usersRepo.getUsers(memberIds);
      
      // Load game events (goals, assists, MVP)
      final gameEvents = await gameEventsRepo.getEvents(widget.gameId);
      
      // Extract data from game events
      final goalScorers = <String>{};
      final assistProviders = <String>{};
      String? mvpPlayerId;
      
      for (final event in gameEvents) {
        switch (event.type) {
          case EventType.goal:
            goalScorers.add(event.playerId);
            break;
          case EventType.assist:
            assistProviders.add(event.playerId);
            break;
          case EventType.mvpVote:
            mvpPlayerId = event.playerId;
            break;
          default:
            break;
        }
      }
      
      // Get players from teams
      final teams = await ref.read(teamsRepositoryProvider).getTeams(widget.gameId);
      final allPlayerIds = <String>{};
      for (final team in teams) {
        allPlayerIds.addAll(team.playerIds);
      }
      
      if (mounted) {
        setState(() {
          _game = game;
          _events = events;
          _hubMembers = members;
          _selectedEventId = game.eventId;
          _teamAScoreController.text = game.teamAScore?.toString() ?? '';
          _teamBScoreController.text = game.teamBScore?.toString() ?? '';
          _selectedPlayerIds.addAll(allPlayerIds);
          _goalScorers.addAll(goalScorers);
          _assistProviders.addAll(assistProviders);
          _mvpPlayerId = mvpPlayerId;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        SnackbarHelper.showError(context, 'שגיאה בטעינת נתונים: $e');
      }
    }
  }

  Future<void> _saveGame() async {
    if (_teamAScoreController.text.trim().isEmpty ||
        _teamBScoreController.text.trim().isEmpty) {
      SnackbarHelper.showError(context, 'נא למלא את תוצאת המשחק');
      return;
    }

    if (_selectedPlayerIds.isEmpty) {
      SnackbarHelper.showError(context, 'נא לבחור לפחות שחקן אחד');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);
      final eventsRepo = ref.read(eventsRepositoryProvider);
      final currentUserId = ref.read(currentUserIdProvider);
      
      if (currentUserId == null) {
        throw Exception('משתמש לא מחובר');
      }

      final teamAScore = int.tryParse(_teamAScoreController.text.trim()) ?? 0;
      final teamBScore = int.tryParse(_teamBScoreController.text.trim()) ?? 0;

      // Update game
      await gamesRepo.updateGame(widget.gameId, {
        'eventId': _selectedEventId,
        'teamAScore': teamAScore,
        'teamBScore': teamBScore,
        'status': 'completed',
      });

      // Delete existing events and create new ones
      final existingEvents = await eventsRepo.getEvents(widget.gameId);
      for (final event in existingEvents) {
        await eventsRepo.deleteEvent(widget.gameId, event.eventId);
      }

      // Create goal events
      for (final playerId in _goalScorers) {
        if (_selectedPlayerIds.contains(playerId)) {
          await eventsRepo.addEvent(widget.gameId, GameEvent(
            eventId: '',
            type: EventType.goal,
            playerId: playerId,
            timestamp: _game?.gameDate ?? DateTime.now(),
            metadata: {},
          ));
        }
      }

      // Create assist events
      for (final playerId in _assistProviders) {
        if (_selectedPlayerIds.contains(playerId)) {
          await eventsRepo.addEvent(widget.gameId, GameEvent(
            eventId: '',
            type: EventType.assist,
            playerId: playerId,
            timestamp: _game?.gameDate ?? DateTime.now(),
            metadata: {},
          ));
        }
      }

      // Create MVP event
      if (_mvpPlayerId != null && _selectedPlayerIds.contains(_mvpPlayerId)) {
        await eventsRepo.addEvent(widget.gameId, GameEvent(
          eventId: '',
          type: EventType.mvpVote,
          playerId: _mvpPlayerId!,
          timestamp: _game?.gameDate ?? DateTime.now(),
          metadata: {},
        ));
      }

      // Create feed post with game summary
      try {
        final feedRepo = ref.read(feedRepositoryProvider);
        final usersRepo = ref.read(usersRepositoryProvider);
        final creator = await usersRepo.getUser(_game?.createdBy ?? '');
        final creatorName = creator?.name ?? 'מישהו';
        
        // Build story text
        final storyParts = <String>[];
        storyParts.add('${creatorName} תיעד משחק');
        if (_selectedEventId != null) {
          final event = _events.firstWhere((e) => e.eventId == _selectedEventId, orElse: () => _events.first);
          storyParts.add('במסגרת "${event.title}"');
        }
        storyParts.add('תוצאה: $teamAScore - $teamBScore');
        
        if (_goalScorers.isNotEmpty) {
          final scorerNames = await usersRepo.getUsers(_goalScorers.toList());
          final names = scorerNames.map((u) => u.name).join(', ');
          storyParts.add('מבקיעים: $names');
        }
        
        if (_assistProviders.isNotEmpty) {
          final assistNames = await usersRepo.getUsers(_assistProviders.toList());
          final names = assistNames.map((u) => u.name).join(', ');
          storyParts.add('מבשלים: $names');
        }
        
        if (_mvpPlayerId != null) {
          final mvp = await usersRepo.getUser(_mvpPlayerId!);
          storyParts.add('MVP: ${mvp?.name ?? "לא ידוע"}');
        }
        
        final feedPost = FeedPost(
          postId: '',
          hubId: widget.hubId,
          authorId: currentUserId,
          type: 'game_logged',
          text: storyParts.join(' | '),
          entityId: widget.gameId,
          createdAt: DateTime.now(),
        );
        
        await feedRepo.createPost(feedPost);
      } catch (e) {
        debugPrint('Failed to create feed post: $e');
        // Don't fail if feed post fails
      }

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'המשחק עודכן בהצלחה!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בשמירה: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return AppScaffold(
        title: 'עריכת משחק',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_game == null) {
      return AppScaffold(
        title: 'עריכת משחק',
        body: const Center(child: Text('משחק לא נמצא')),
      );
    }

    return AppScaffold(
      title: 'עריכת משחק',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Game date
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('תאריך המשחק'),
                subtitle: Text(DateFormat('dd/MM/yyyy HH:mm', 'he').format(_game!.gameDate)),
              ),
            ),
            const SizedBox(height: 16),
            
            // Event selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'קישור לאירוע (אופציונלי)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedEventId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'בחר אירוע',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('ללא אירוע'),
                        ),
                        ..._events.map((event) => DropdownMenuItem<String>(
                          value: event.eventId,
                          child: Text(event.title),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedEventId = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Score
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'תוצאת המשחק',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _teamAScoreController,
                            decoration: const InputDecoration(
                              labelText: 'קבוצה א',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('-', style: TextStyle(fontSize: 24)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _teamBScoreController,
                            decoration: const InputDecoration(
                              labelText: 'קבוצה ב',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Players selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'שחקנים שהשתתפו',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._hubMembers.map((member) => CheckboxListTile(
                      title: Text(member.name),
                      value: _selectedPlayerIds.contains(member.uid),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedPlayerIds.add(member.uid);
                          } else {
                            _selectedPlayerIds.remove(member.uid);
                            _goalScorers.remove(member.uid);
                            _assistProviders.remove(member.uid);
                            if (_mvpPlayerId == member.uid) {
                              _mvpPlayerId = null;
                            }
                          }
                        });
                      },
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Goal scorers
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'מבקיעים',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _hubMembers
                          .where((m) => _selectedPlayerIds.contains(m.uid))
                          .map((member) => FilterChip(
                                label: Text(member.name),
                                selected: _goalScorers.contains(member.uid),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _goalScorers.add(member.uid);
                                    } else {
                                      _goalScorers.remove(member.uid);
                                    }
                                  });
                                },
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Assist providers
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'מבשלים',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _hubMembers
                          .where((m) => _selectedPlayerIds.contains(m.uid))
                          .map((member) => FilterChip(
                                label: Text(member.name),
                                selected: _assistProviders.contains(member.uid),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _assistProviders.add(member.uid);
                                    } else {
                                      _assistProviders.remove(member.uid);
                                    }
                                  });
                                },
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // MVP
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MVP',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _mvpPlayerId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'בחר MVP',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('ללא MVP'),
                        ),
                        ..._hubMembers
                            .where((m) => _selectedPlayerIds.contains(m.uid))
                            .map((member) => DropdownMenuItem<String>(
                                  value: member.uid,
                                  child: Text(member.name),
                                )),
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
            
            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveGame,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('שמור'),
            ),
          ],
        ),
      ),
    );
  }
}

