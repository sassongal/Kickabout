import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/models/converters/timestamp_converter.dart';

part 'match_result.freezed.dart';
part 'match_result.g.dart';

/// Approval status for match results submitted by moderators
enum MatchApprovalStatus {
  pending,  // Submitted by moderator, awaiting manager approval
  approved, // Approved by manager or submitted by manager directly
  rejected; // Rejected by manager

  /// Convert from JSON string
  static MatchApprovalStatus fromJson(String value) {
    return MatchApprovalStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MatchApprovalStatus.approved,
    );
  }

  /// Convert to JSON string
  String toJson() => name;
}

/// JsonConverter for MatchApprovalStatus enum
class MatchApprovalStatusConverter implements JsonConverter<MatchApprovalStatus, String> {
  const MatchApprovalStatusConverter();

  @override
  MatchApprovalStatus fromJson(String json) {
    return MatchApprovalStatus.fromJson(json);
  }

  @override
  String toJson(MatchApprovalStatus object) {
    return object.toJson();
  }
}

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
    String? mvpId, // User ID of MVP (Most Valuable Player)
    @TimestampConverter() required DateTime createdAt, // When this match was logged
    String? loggedBy, // User ID who logged this match (manager or moderator)
    @Default(12) int matchDurationMinutes, // Duration of this specific match in minutes

    // Moderator approval workflow fields
    @MatchApprovalStatusConverter()
    @Default(MatchApprovalStatus.approved) MatchApprovalStatus approvalStatus,
    String? approvedBy, // User ID of manager who approved (if moderator submitted)
    @TimestampConverter() DateTime? approvedAt, // When manager approved
    String? rejectionReason, // Reason if rejected by manager
  }) = _MatchResult;

  factory MatchResult.fromJson(Map<String, dynamic> json) => _$MatchResultFromJson(json);
}

