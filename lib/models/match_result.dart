import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/models/converters/timestamp_converter.dart';

part 'match_result.freezed.dart';
part 'match_result.g.dart';

/// MatchResult model - represents a single match outcome within a Session/Event
/// Example: Blue team beat Red team 3-2
/// This represents one match within a series (e.g., "Best of 3" tournament)
@freezed
class MatchResult with _$MatchResult {
  const factory MatchResult({
    required String matchId, // Unique UUID for this match
    required String teamAColor, // Color of first team (e.g., "Blue", "Red")
    required String teamBColor, // Color of second team
    required int scoreA, // Score for team A
    required int scoreB, // Score for team B
    @Default([]) List<String> scorerIds, // User IDs of goal scorers (for team A + B combined)
    @Default([]) List<String> assistIds, // User IDs of assisters (for team A + B combined)
    @TimestampConverter() required DateTime createdAt, // When this match was logged
    String? loggedBy, // User ID who logged this match (manager)
    @Default(12) int matchDurationMinutes, // Duration of this specific match in minutes
  }) = _MatchResult;

  factory MatchResult.fromJson(Map<String, dynamic> json) => _$MatchResultFromJson(json);
}

