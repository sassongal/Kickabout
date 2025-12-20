import 'package:flutter/foundation.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/utils/stopwatch_utility.dart';
import 'package:kattrick/data/offline_event_queue.dart';

/// Game-specific stopwatch for recording goals and events during an active game
///
/// Features:
/// - Stopwatch for game duration
/// - Record goals with timestamps
/// - Record assists with timestamps
/// - Record other events (cards, saves, etc.)
/// - Export game events
/// - 🔒 OFFLINE PERSISTENCE: Events saved to local DB to prevent data loss
class GameStopwatch extends ChangeNotifier {
  final StopwatchUtility _stopwatch = StopwatchUtility();
  final List<GameEventRecord> _events = [];
  final String gameId;
  final String hubId;

  GameStopwatch({
    required this.gameId,
    required this.hubId,
  }) {
    _stopwatch.addListener(_onStopwatchUpdate);
  }

  /// Current elapsed game time
  Duration get elapsed => _stopwatch.elapsed;

  /// Is the game stopwatch running?
  bool get isRunning => _stopwatch.isRunning;

  /// Is the game stopwatch paused?
  bool get isPaused => _stopwatch.isPaused;

  /// List of all recorded events
  List<GameEventRecord> get events => List.unmodifiable(_events);

  /// Goals recorded
  List<GameEventRecord> get goals => _events.where((e) => e.type == EventType.goal).toList();

  /// Assists recorded
  List<GameEventRecord> get assists => _events.where((e) => e.type == EventType.assist).toList();

  /// Start the game stopwatch
  void start() {
    _stopwatch.start();
  }

  /// Pause the game stopwatch
  void pause() {
    _stopwatch.pause();
  }

  /// Resume the game stopwatch
  void resume() {
    _stopwatch.start();
  }

  /// Stop the game stopwatch
  void stop() {
    _stopwatch.stop();
  }

  /// Reset the game stopwatch and clear all events
  void reset() {
    _stopwatch.reset();
    _events.clear();
    notifyListeners();
  }

  /// Record a goal
  ///
  /// [playerId] - ID of the player who scored
  /// [playerName] - Name of the player (for display)
  /// [team] - Which team (A or B)
  /// [assistPlayerId] - Optional: ID of player who assisted
  /// [assistPlayerName] - Optional: Name of assist provider
  void recordGoal({
    required String playerId,
    required String playerName,
    required String team,
    String? assistPlayerId,
    String? assistPlayerName,
  }) {
    final recordedAt = DateTime.now();
    final timestamp = _stopwatch.elapsed;
    final metadata = {
      if (assistPlayerId != null) 'assistPlayerId': assistPlayerId,
      if (assistPlayerName != null) 'assistPlayerName': assistPlayerName,
    };

    final event = GameEventRecord(
      eventId: '',
      type: EventType.goal,
      playerId: playerId,
      playerName: playerName,
      team: team,
      timestamp: timestamp,
      recordedAt: recordedAt,
      metadata: metadata,
    );
    _events.add(event);
    notifyListeners();

    // 🔒 PERSIST TO OFFLINE QUEUE - Prevents data loss if app crashes
    offlineEventQueue.enqueue(
      gameId: gameId,
      hubId: hubId,
      eventType: EventType.goal,
      playerId: playerId,
      playerName: playerName,
      team: team,
      timestamp: timestamp,
      recordedAt: recordedAt,
      metadata: metadata,
    );
  }

  /// Record an assist
  ///
  /// [playerId] - ID of the player who provided the assist
  /// [playerName] - Name of the player
  /// [team] - Which team (A or B)
  /// [goalPlayerId] - ID of player who scored
  /// [goalPlayerName] - Name of goal scorer
  void recordAssist({
    required String playerId,
    required String playerName,
    required String team,
    required String goalPlayerId,
    required String goalPlayerName,
  }) {
    final recordedAt = DateTime.now();
    final timestamp = _stopwatch.elapsed;
    final metadata = {
      'goalPlayerId': goalPlayerId,
      'goalPlayerName': goalPlayerName,
    };

    final event = GameEventRecord(
      eventId: '',
      type: EventType.assist,
      playerId: playerId,
      playerName: playerName,
      team: team,
      timestamp: timestamp,
      recordedAt: recordedAt,
      metadata: metadata,
    );
    _events.add(event);
    notifyListeners();

    // 🔒 PERSIST TO OFFLINE QUEUE
    offlineEventQueue.enqueue(
      gameId: gameId,
      hubId: hubId,
      eventType: EventType.assist,
      playerId: playerId,
      playerName: playerName,
      team: team,
      timestamp: timestamp,
      recordedAt: recordedAt,
      metadata: metadata,
    );
  }

  /// Record a card (yellow/red)
  ///
  /// [playerId] - ID of the player
  /// [playerName] - Name of the player
  /// [team] - Which team (A or B)
  /// [cardType] - 'yellow' or 'red'
  void recordCard({
    required String playerId,
    required String playerName,
    required String team,
    required String cardType, // 'yellow' or 'red'
  }) {
    final recordedAt = DateTime.now();
    final timestamp = _stopwatch.elapsed;
    final metadata = {'cardType': cardType};

    final event = GameEventRecord(
      eventId: '',
      type: EventType.card,
      playerId: playerId,
      playerName: playerName,
      team: team,
      timestamp: timestamp,
      recordedAt: recordedAt,
      metadata: metadata,
    );
    _events.add(event);
    notifyListeners();

    // 🔒 PERSIST TO OFFLINE QUEUE
    offlineEventQueue.enqueue(
      gameId: gameId,
      hubId: hubId,
      eventType: EventType.card,
      playerId: playerId,
      playerName: playerName,
      team: team,
      timestamp: timestamp,
      recordedAt: recordedAt,
      metadata: metadata,
    );
  }

  /// Record a save (for goalkeepers)
  ///
  /// [playerId] - ID of the goalkeeper
  /// [playerName] - Name of the goalkeeper
  /// [team] - Which team (A or B)
  void recordSave({
    required String playerId,
    required String playerName,
    required String team,
  }) {
    final recordedAt = DateTime.now();
    final timestamp = _stopwatch.elapsed;
    final metadata = <String, dynamic>{};

    final event = GameEventRecord(
      eventId: '',
      type: EventType.save,
      playerId: playerId,
      playerName: playerName,
      team: team,
      timestamp: timestamp,
      recordedAt: recordedAt,
      metadata: metadata,
    );
    _events.add(event);
    notifyListeners();

    // 🔒 PERSIST TO OFFLINE QUEUE
    offlineEventQueue.enqueue(
      gameId: gameId,
      hubId: hubId,
      eventType: EventType.save,
      playerId: playerId,
      playerName: playerName,
      team: team,
      timestamp: timestamp,
      recordedAt: recordedAt,
      metadata: metadata,
    );
  }

  /// Record a custom event
  ///
  /// [type] - Event type
  /// [playerId] - ID of the player
  /// [playerName] - Name of the player
  /// [team] - Which team (A or B)
  /// [metadata] - Additional metadata
  void recordCustomEvent({
    required EventType type,
    required String playerId,
    required String playerName,
    required String team,
    Map<String, dynamic>? metadata,
  }) {
    final recordedAt = DateTime.now();
    final timestamp = _stopwatch.elapsed;
    final eventMetadata = metadata ?? {};

    final event = GameEventRecord(
      eventId: '',
      type: type,
      playerId: playerId,
      playerName: playerName,
      team: team,
      timestamp: timestamp,
      recordedAt: recordedAt,
      metadata: eventMetadata,
    );
    _events.add(event);
    notifyListeners();

    // 🔒 PERSIST TO OFFLINE QUEUE
    offlineEventQueue.enqueue(
      gameId: gameId,
      hubId: hubId,
      eventType: type,
      playerId: playerId,
      playerName: playerName,
      team: team,
      timestamp: timestamp,
      recordedAt: recordedAt,
      metadata: eventMetadata,
    );
  }

  /// Remove an event
  void removeEvent(GameEventRecord event) {
    _events.remove(event);
    notifyListeners();
  }

  /// Get events for a specific team
  List<GameEventRecord> getEventsForTeam(String team) {
    return _events.where((e) => e.team == team).toList();
  }

  /// Get events for a specific player
  List<GameEventRecord> getEventsForPlayer(String playerId) {
    return _events.where((e) => e.playerId == playerId).toList();
  }

  /// Get score for a team
  int getScoreForTeam(String team) {
    return _events.where((e) => e.type == EventType.goal && e.team == team).length;
  }

  /// Export events as GameEvent list (for saving to Firestore)
  List<GameEvent> exportAsGameEvents() {
    return _events.map((record) {
      return GameEvent(
        eventId: record.eventId,
        type: record.type,
        playerId: record.playerId,
        timestamp: record.recordedAt,
        metadata: {
          ...record.metadata,
          'gameTime': record.timestamp.inSeconds,
          'playerName': record.playerName,
          'team': record.team,
        },
      );
    }).toList();
  }

  void _onStopwatchUpdate() {
    notifyListeners();
  }

  @override
  void dispose() {
    _stopwatch.removeListener(_onStopwatchUpdate);
    _stopwatch.dispose();
    super.dispose();
  }
}

/// Record of a game event with timestamp
class GameEventRecord {
  final String eventId;
  final EventType type;
  final String playerId;
  final String playerName;
  final String team; // 'A' or 'B'
  final Duration timestamp; // Time in game when event occurred
  final DateTime recordedAt; // When event was recorded
  final Map<String, dynamic> metadata;

  GameEventRecord({
    required this.eventId,
    required this.type,
    required this.playerId,
    required this.playerName,
    required this.team,
    required this.timestamp,
    required this.recordedAt,
    required this.metadata,
  });

  /// Format timestamp as MM:SS
  String get formattedTime => StopwatchUtility.formatMMSS(timestamp);

  /// Get display name for event type
  String get typeDisplayName {
    switch (type) {
      case EventType.goal:
        return 'שער';
      case EventType.assist:
        return 'בישול';
      case EventType.card:
        return metadata['cardType'] == 'red' ? 'כרטיס אדום' : 'כרטיס צהוב';
      case EventType.save:
        return 'הצלה';
      default:
        return 'אירוע';
    }
  }
}

