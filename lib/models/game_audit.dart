import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/models/game_audit_event.dart';

part 'game_audit.freezed.dart';
part 'game_audit.g.dart';

@freezed
class GameAudit with _$GameAudit {
  const factory GameAudit({
    @Default([]) List<GameAuditEvent> auditLog,
  }) = _GameAudit;

  factory GameAudit.fromJson(Map<String, dynamic> json) =>
      _$GameAuditFromJson(json);
}
