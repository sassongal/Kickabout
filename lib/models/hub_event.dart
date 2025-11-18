import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kickadoor/models/converters/timestamp_converter.dart';
import 'package:kickadoor/models/converters/geopoint_converter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'hub_event.freezed.dart';
part 'hub_event.g.dart';

/// Hub Event model - events created by hub managers (tournaments, training, etc.)
@freezed
class HubEvent with _$HubEvent {
  const factory HubEvent({
    required String eventId,
    required String hubId,
    required String createdBy,
    required String title,
    String? description,
    @TimestampConverter() required DateTime eventDate,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    @Default([]) List<String> registeredPlayerIds, // Players who registered
    @Default('upcoming') String status, // upcoming, ongoing, completed, cancelled
    String? location,
    @NullableGeoPointConverter() GeoPoint? locationPoint,
    String? geohash,
    @Default(3) int teamCount, // Number of teams (default: 3)
    String? gameType, // 3v3, 4v4, 5v5, 6v6, 7v7, 8v8, 9v9, 10v10, 11v11
    int? durationMinutes, // Game duration in minutes (default: 12)
    @Default(15) int maxParticipants, // Maximum number of participants (default: 15, required)
    @Default(false) bool notifyMembers, // Send notification to all hub members when event is created
  }) = _HubEvent;

  factory HubEvent.fromJson(Map<String, dynamic> json) => _$HubEventFromJson(json);
}

