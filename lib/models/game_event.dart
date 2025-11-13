import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kickadoor/models/enums/event_type.dart';
import 'package:kickadoor/models/converters/timestamp_converter.dart';

part 'game_event.freezed.dart';
part 'game_event.g.dart';

/// Game event model matching Firestore schema: /games/{id}/events/{eventId}
@freezed
class GameEvent with _$GameEvent {
  const factory GameEvent({
    required String eventId,
    @EventTypeConverter() required EventType type,
    required String playerId,
    @TimestampConverter() required DateTime timestamp,
    @Default({}) Map<String, dynamic> metadata,
  }) = _GameEvent;

  factory GameEvent.fromJson(Map<String, dynamic> json) =>
      _$GameEventFromJson(json);
}

/// Firestore converter for GameEvent
class GameEventConverter
    implements JsonConverter<GameEvent, Map<String, dynamic>> {
  const GameEventConverter();

  @override
  GameEvent fromJson(Map<String, dynamic> json) => GameEvent.fromJson(json);

  @override
  Map<String, dynamic> toJson(GameEvent object) => object.toJson();
}

/// EventType converter for Firestore
class EventTypeConverter implements JsonConverter<EventType, String> {
  const EventTypeConverter();

  @override
  EventType fromJson(String json) => EventType.fromFirestore(json);

  @override
  String toJson(EventType object) => object.toFirestore();
}

