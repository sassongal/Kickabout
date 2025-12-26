import 'package:json_annotation/json_annotation.dart';

/// Join mode for hubs - how members can join
enum JoinMode {
  /// Automatic join - users join immediately without approval
  auto,

  /// Requires approval - manager must approve join requests
  approval;

  /// Firestore storage value
  String get firestoreValue => name;

  /// Display name in Hebrew
  String get displayName {
    switch (this) {
      case JoinMode.auto:
        return 'הצטרפות אוטומטית';
      case JoinMode.approval:
        return 'מצריך אישור';
    }
  }

  /// Whether this mode requires manager approval
  bool get requiresApproval => this == JoinMode.approval;

  /// Whether this mode allows automatic joining
  bool get allowsAutoJoin => this == JoinMode.auto;

  /// Parse from Firestore string value
  static JoinMode fromFirestore(String value) {
    return JoinMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => JoinMode.auto,
    );
  }
}

/// JSON converter for JoinMode
class JoinModeConverter implements JsonConverter<JoinMode, String> {
  const JoinModeConverter();

  @override
  JoinMode fromJson(String json) => JoinMode.fromFirestore(json);

  @override
  String toJson(JoinMode object) => object.firestoreValue;
}
