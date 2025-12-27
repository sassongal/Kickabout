import 'package:kattrick/shared/domain/events/domain_event.dart';

/// Event fired when a new game is created
class GameCreatedEvent extends DomainEvent {
  /// The ID of the created game
  final String gameId;

  /// The ID of the hub this game belongs to (if any)
  final String? hubId;

  GameCreatedEvent({
    required this.gameId,
    this.hubId,
    DateTime? timestamp,
    String? eventId,
  }) : super(timestamp: timestamp, eventId: eventId);

  @override
  String toString() {
    return 'GameCreatedEvent(gameId: $gameId, hubId: $hubId, eventId: $eventId)';
  }
}

/// Event fired when a game is finalized with results
class GameFinalizedEvent extends DomainEvent {
  /// The ID of the finalized game
  final String gameId;

  /// The ID of the hub this game belongs to (if any)
  final String? hubId;

  /// List of player IDs who participated
  final List<String> playerIds;

  /// List of player IDs who won (if applicable)
  final List<String>? winnerIds;

  GameFinalizedEvent({
    required this.gameId,
    this.hubId,
    required this.playerIds,
    this.winnerIds,
    DateTime? timestamp,
    String? eventId,
  }) : super(timestamp: timestamp, eventId: eventId);

  @override
  String toString() {
    return 'GameFinalizedEvent(gameId: $gameId, hubId: $hubId, playerCount: ${playerIds.length}, eventId: $eventId)';
  }
}

/// Event fired when a game is cancelled
class GameCancelledEvent extends DomainEvent {
  /// The ID of the cancelled game
  final String gameId;

  /// The ID of the hub this game belongs to (if any)
  final String? hubId;

  /// Reason for cancellation (optional)
  final String? reason;

  GameCancelledEvent({
    required this.gameId,
    this.hubId,
    this.reason,
    DateTime? timestamp,
    String? eventId,
  }) : super(timestamp: timestamp, eventId: eventId);

  @override
  String toString() {
    return 'GameCancelledEvent(gameId: $gameId, hubId: $hubId, reason: $reason, eventId: $eventId)';
  }
}

/// Event fired when a game session starts (Winner Stays format)
class GameSessionStartedEvent extends DomainEvent {
  /// The ID of the game whose session started
  final String gameId;

  /// The ID of the hub this game belongs to (if any)
  final String? hubId;

  /// The ID of the user who started the session
  final String startedBy;

  GameSessionStartedEvent({
    required this.gameId,
    this.hubId,
    required this.startedBy,
    DateTime? timestamp,
    String? eventId,
  }) : super(timestamp: timestamp, eventId: eventId);

  @override
  String toString() {
    return 'GameSessionStartedEvent(gameId: $gameId, hubId: $hubId, startedBy: $startedBy, eventId: $eventId)';
  }
}

/// Event fired when a game session ends
class GameSessionEndedEvent extends DomainEvent {
  /// The ID of the game whose session ended
  final String gameId;

  /// The ID of the hub this game belongs to (if any)
  final String? hubId;

  /// The ID of the user who ended the session
  final String endedBy;

  /// Number of matches played in the session
  final int matchCount;

  GameSessionEndedEvent({
    required this.gameId,
    this.hubId,
    required this.endedBy,
    required this.matchCount,
    DateTime? timestamp,
    String? eventId,
  }) : super(timestamp: timestamp, eventId: eventId);

  @override
  String toString() {
    return 'GameSessionEndedEvent(gameId: $gameId, hubId: $hubId, matchCount: $matchCount, eventId: $eventId)';
  }
}

/// Event fired when a match is added to a session
class MatchAddedToSessionEvent extends DomainEvent {
  /// The ID of the game
  final String gameId;

  /// The ID of the hub this game belongs to (if any)
  final String? hubId;

  /// The ID of the match that was added
  final String matchId;

  /// Player IDs who participated in this match
  final List<String> playerIds;

  MatchAddedToSessionEvent({
    required this.gameId,
    this.hubId,
    required this.matchId,
    required this.playerIds,
    DateTime? timestamp,
    String? eventId,
  }) : super(timestamp: timestamp, eventId: eventId);

  @override
  String toString() {
    return 'MatchAddedToSessionEvent(gameId: $gameId, matchId: $matchId, playerCount: ${playerIds.length}, eventId: $eventId)';
  }
}
