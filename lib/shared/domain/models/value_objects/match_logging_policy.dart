import 'package:json_annotation/json_annotation.dart';
import 'package:kattrick/features/hubs/domain/models/hub_member.dart';

/// Match logging policy - who can log matches in a hub
enum MatchLoggingPolicy {
  /// Only managers can log matches
  managerOnly,

  /// Managers and moderators can log matches
  moderators,

  /// Any participant in the match can log it
  anyParticipant;

  /// Firestore storage value
  String get firestoreValue => name;

  /// Display name in Hebrew
  String get displayName {
    switch (this) {
      case MatchLoggingPolicy.managerOnly:
        return 'מנהל בלבד';
      case MatchLoggingPolicy.moderators:
        return 'מנהלים ומנחים';
      case MatchLoggingPolicy.anyParticipant:
        return 'כל משתתף';
    }
  }

  /// Check if a user with given role and participation can log a match
  ///
  /// [role] - User's role in the hub
  /// [isParticipant] - Whether the user participated in the match
  bool canLog(HubMemberRole role, bool isParticipant) {
    switch (this) {
      case MatchLoggingPolicy.managerOnly:
        return role == HubMemberRole.manager;
      case MatchLoggingPolicy.moderators:
        return role.isAtLeast(HubMemberRole.moderator);
      case MatchLoggingPolicy.anyParticipant:
        return isParticipant;
    }
  }

  /// Parse from Firestore string value
  static MatchLoggingPolicy fromFirestore(String value) {
    return MatchLoggingPolicy.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MatchLoggingPolicy.managerOnly,
    );
  }
}

/// JSON converter for MatchLoggingPolicy
class MatchLoggingPolicyConverter implements JsonConverter<MatchLoggingPolicy, String> {
  const MatchLoggingPolicyConverter();

  @override
  MatchLoggingPolicy fromJson(String json) => MatchLoggingPolicy.fromFirestore(json);

  @override
  String toJson(MatchLoggingPolicy object) => object.firestoreValue;
}
