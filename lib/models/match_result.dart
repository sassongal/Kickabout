import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kickadoor/models/converters/timestamp_converter.dart';

part 'match_result.freezed.dart';
part 'match_result.g.dart';

/// MatchResult model - represents a single match outcome within an Event
/// Example: Blue team beat Red team 3-2
@freezed
class MatchResult with _$MatchResult {
  const factory MatchResult({
    required String matchId, // Unique ID for this match
    required String teamAColor, // Color of first team (e.g., "Blue", "Red")
    required String teamBColor, // Color of second team
    required int scoreA, // Score for team A
    required int scoreB, // Score for team B
    @TimestampConverter() required DateTime createdAt, // When this match was logged
    String? loggedBy, // User ID who logged this match
  }) = _MatchResult;

  factory MatchResult.fromJson(Map<String, dynamic> json) => _$MatchResultFromJson(json);
}

