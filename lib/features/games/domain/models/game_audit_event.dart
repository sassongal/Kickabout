import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/shared/infrastructure/firestore/converters/timestamp_firestore_converter.dart';

part 'game_audit_event.freezed.dart';
part 'game_audit_event.g.dart';

/// Audit trail entry for game admin actions
/// Tracks who did what and when for accountability
@freezed
class GameAuditEvent with _$GameAuditEvent {
  const factory GameAuditEvent({
    /// Action type (e.g., "PLAYER_KICKED", "GAME_RESCHEDULED", "PLAYER_APPROVED")
    required String action,

    /// User ID who performed the action
    required String userId,

    /// When the action was performed
    @TimestampConverter() required DateTime timestamp,

    /// Optional reason/notes for the action
    String? reason,
  }) = _GameAuditEvent;

  factory GameAuditEvent.fromJson(Map<String, dynamic> json) =>
      _$GameAuditEventFromJson(json);
}
