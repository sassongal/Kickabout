import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/shared/infrastructure/firestore/converters/timestamp_firestore_converter.dart';

part 'match_record.freezed.dart';
part 'match_record.g.dart';

@freezed
class MatchRecord with _$MatchRecord {
  const factory MatchRecord({
    required String id,
    required String eventId,
    required String hubId,

    // Teams involved (Team IDs or Names/Colors)
    required String teamAId,
    required String teamBId,
    required String teamAName,
    required String teamBName,

    // Score
    required int scoreTeamA,
    required int scoreTeamB,

    // Stats
    @Default({}) Map<String, int> scorers, // PlayerID -> Goals
    @Default({}) Map<String, int> assists, // PlayerID -> Assists
    String? mvpPlayerId,

    // Metadata
    required int durationSeconds,
    @TimestampConverter() required DateTime timestamp,
    required String recordedBy, // UserID of the scorer
  }) = _MatchRecord;

  factory MatchRecord.fromJson(Map<String, dynamic> json) =>
      _$MatchRecordFromJson(json);

  // Helper to determine winner (returns teamId or null for draw)
  const MatchRecord._();
  String? get winnerId {
    if (scoreTeamA > scoreTeamB) return teamAId;
    if (scoreTeamB > scoreTeamA) return teamBId;
    return null; // Draw
  }
}
