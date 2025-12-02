import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/models/converters/timestamp_converter.dart';
import 'package:kattrick/models/converters/geopoint_converter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/models/team.dart';
import 'package:kattrick/models/match_result.dart';

// ignore_for_file: invalid_annotation_target

part 'hub_event.freezed.dart';
part 'hub_event.g.dart';

/// Hub Event model - events created by hub managers (tournaments, training, etc.)
/// Events represent the "Plan" - when converted to a Game, they become the "Record"
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
    @JsonKey(defaultValue: <String>[])
    @Default(<String>[])
    List<String> registeredPlayerIds, // Players who registered
    @JsonKey(defaultValue: <String>[])
    @Default(<String>[])
    List<String> waitingListPlayerIds, // Players on waiting list
    @Default('upcoming')
    String status, // upcoming, ongoing, completed, cancelled
    @Default(false) bool isStarted, // Explicit flag for in-progress session
    @TimestampConverter() DateTime? startedAt, // When manager marked start
    String? location,
    @NullableGeoPointConverter() GeoPoint? locationPoint,
    String? geohash,
    String? venueId, // Reference to venue
    @Default(3) int teamCount, // Number of teams (default: 3)
    String? gameType, // 3v3, 4v4, 5v5, 6v6, 7v7, 8v8, 9v9, 10v10, 11v11
    int? durationMinutes, // Game duration in minutes (default: 12)
    @Default(15)
    int maxParticipants, // Maximum number of participants (default: 15, required)
    @Default(false)
    bool
        notifyMembers, // Send notification to all hub members when event is created
    @Default(false)
    bool showInCommunityFeed, // Show this event in the community activity feed
    // Attendance confirmation settings
    @Default(true)
    bool enableAttendanceReminder, // Organizer can choose to send 2h reminders
    // Teams planned for this event (manager-only, saved when using TeamMaker)
    @JsonKey(defaultValue: <Team>[])
    @Default(<Team>[])
    List<Team> teams, // Teams planned for this event (manager-only)
    // Multi-match session support
    @JsonKey(defaultValue: <MatchResult>[])
    @Default(<MatchResult>[])
    List<MatchResult>
        matches, // List of individual match outcomes within this event
    @JsonKey(defaultValue: <String, int>{})
    @Default(<String, int>{})
    Map<String, int>
        aggregateWins, // Summary: {'Blue': 6, 'Red': 4, 'Green': 2}
    // Reference to Game if event was converted to game
    String? gameId, // If event was converted to game, reference it
  }) = _HubEvent;

  factory HubEvent.fromJson(Map<String, dynamic> json) =>
      _$HubEventFromJson(json);
}
