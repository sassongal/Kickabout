import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/shared/domain/models/value_objects/join_mode.dart';
import 'package:kattrick/shared/domain/models/value_objects/match_logging_policy.dart';

part 'hub_settings.freezed.dart';
part 'hub_settings.g.dart';

/// Typed hub settings model - replaces Map<String, dynamic> for type safety
///
/// This model centralizes all hub configuration settings with compile-time
/// type checking and default values.
@freezed
class HubSettings with _$HubSettings {
  const factory HubSettings({
    /// Show manager contact information to members
    @Default(true) bool showManagerContactInfo,

    /// Allow users to request to join the hub
    @Default(true) bool allowJoinRequests,

    /// Allow moderators to create games from events
    /// (normally only managers can create games)
    @Default(false) bool allowModeratorsToCreateGames,

    /// Require game results to be approved by manager before being recorded
    @Default(false) bool requireResultApproval,

    /// Allow members to invite other players to the hub
    @Default(true) bool allowMemberInvites,

    /// Enable polls feature for this hub
    @Default(true) bool enablePolls,

    /// Enable chat feature for this hub
    @Default(true) bool enableChat,

    /// Enable events feature for this hub
    @Default(true) bool enableEvents,

    /// Maximum number of members allowed in the hub
    /// Default: 50 (standard hub size)
    /// Set to 0 for unlimited (not recommended for community management)
    @Default(50) int maxMembers,

    /// Minimum number of games played to be considered a veteran
    @Default(10) int veteranGamesThreshold,

    /// Invitation code for joining the hub
    /// If null, uses hubId.substring(0, 8) as fallback
    String? invitationCode,

    /// Enable/disable invitations for this hub
    @Default(true) bool invitationsEnabled,

    /// Join mode: auto (immediate) or approval (requires manager approval)
    @JoinModeConverter() @Default(JoinMode.auto) JoinMode joinMode,

    /// Match logging policy: who can log matches
    @MatchLoggingPolicyConverter() @Default(MatchLoggingPolicy.managerOnly) MatchLoggingPolicy matchLoggingPolicy,

    /// Enable Man of the Match voting (Sprint 3)
    /// When enabled, games created in this hub will have MOTM voting by default
    @Default(false) bool enableMotmVoting,

    /// Payment link for hub (Bit/PayBox deep link)
    /// When set, players can click "Pay Now" button to directly open payment app
    /// Format: https://payboxapp.page.link/... or bit.ly/...
    String? paymentLink,
  }) = _HubSettings;

  const HubSettings._();

  factory HubSettings.fromJson(Map<String, dynamic> json) =>
      _$HubSettingsFromJson(json);

  /// Backward compatibility: Create from legacy Map<String, dynamic>
  /// Handles missing keys gracefully with defaults
  factory HubSettings.fromLegacyMap(Map<String, dynamic>? map) {
    if (map == null) return const HubSettings();

    return HubSettings(
      showManagerContactInfo: map['showManagerContactInfo'] as bool? ?? true,
      allowJoinRequests: map['allowJoinRequests'] as bool? ?? true,
      allowModeratorsToCreateGames:
          map['allowModeratorsToCreateGames'] as bool? ?? false,
      requireResultApproval: map['requireResultApproval'] as bool? ?? false,
      allowMemberInvites: map['allowMemberInvites'] as bool? ?? true,
      enablePolls: map['enablePolls'] as bool? ?? true,
      enableChat: map['enableChat'] as bool? ?? true,
      enableEvents: map['enableEvents'] as bool? ?? true,
      maxMembers: map['maxMembers'] as int? ?? 50,
      veteranGamesThreshold: map['veteranGamesThreshold'] as int? ?? 10,
      invitationCode: map['invitationCode'] as String?,
      invitationsEnabled: map['invitationsEnabled'] as bool? ?? true,
      joinMode: JoinMode.fromFirestore(map['joinMode'] as String? ?? 'auto'),
      matchLoggingPolicy: MatchLoggingPolicy.fromFirestore(
        map['matchLoggingPolicy'] as String? ?? 'managerOnly',
      ),
      enableMotmVoting: map['enableMotmVoting'] as bool? ?? false,
      paymentLink: map['paymentLink'] as String?,
    );
  }

  /// Convert to Map for Firestore storage (backward compatibility)
  Map<String, dynamic> toLegacyMap() => toJson();
}

/// Firestore converter for HubSettings
class HubSettingsConverter
    implements JsonConverter<HubSettings, Map<String, dynamic>> {
  const HubSettingsConverter();

  @override
  HubSettings fromJson(Map<String, dynamic> json) =>
      HubSettings.fromLegacyMap(json);

  @override
  Map<String, dynamic> toJson(HubSettings object) => object.toJson();
}
