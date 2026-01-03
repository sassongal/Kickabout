// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hub_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HubSettings _$HubSettingsFromJson(Map<String, dynamic> json) {
  return _HubSettings.fromJson(json);
}

/// @nodoc
mixin _$HubSettings {
  /// Show manager contact information to members
  bool get showManagerContactInfo => throw _privateConstructorUsedError;

  /// Allow users to request to join the hub
  bool get allowJoinRequests => throw _privateConstructorUsedError;

  /// Allow moderators to create games from events
  /// (normally only managers can create games)
  bool get allowModeratorsToCreateGames => throw _privateConstructorUsedError;

  /// Require game results to be approved by manager before being recorded
  bool get requireResultApproval => throw _privateConstructorUsedError;

  /// Allow members to invite other players to the hub
  bool get allowMemberInvites => throw _privateConstructorUsedError;

  /// Enable polls feature for this hub
  bool get enablePolls => throw _privateConstructorUsedError;

  /// Enable chat feature for this hub
  bool get enableChat => throw _privateConstructorUsedError;

  /// Enable events feature for this hub
  bool get enableEvents => throw _privateConstructorUsedError;

  /// Maximum number of members allowed in the hub
  /// Default: 50 (standard hub size)
  /// Set to 0 for unlimited (not recommended for community management)
  int get maxMembers => throw _privateConstructorUsedError;

  /// Minimum number of games played to be considered a veteran
  int get veteranGamesThreshold => throw _privateConstructorUsedError;

  /// Invitation code for joining the hub
  /// If null, uses hubId.substring(0, 8) as fallback
  String? get invitationCode => throw _privateConstructorUsedError;

  /// Enable/disable invitations for this hub
  bool get invitationsEnabled => throw _privateConstructorUsedError;

  /// Join mode: auto (immediate) or approval (requires manager approval)
  @JoinModeConverter()
  JoinMode get joinMode => throw _privateConstructorUsedError;

  /// Match logging policy: who can log matches
  @MatchLoggingPolicyConverter()
  MatchLoggingPolicy get matchLoggingPolicy =>
      throw _privateConstructorUsedError;

  /// Enable Man of the Match voting (Sprint 3)
  /// When enabled, games created in this hub will have MOTM voting by default
  bool get enableMotmVoting => throw _privateConstructorUsedError;

  /// Serializes this HubSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HubSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HubSettingsCopyWith<HubSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HubSettingsCopyWith<$Res> {
  factory $HubSettingsCopyWith(
          HubSettings value, $Res Function(HubSettings) then) =
      _$HubSettingsCopyWithImpl<$Res, HubSettings>;
  @useResult
  $Res call(
      {bool showManagerContactInfo,
      bool allowJoinRequests,
      bool allowModeratorsToCreateGames,
      bool requireResultApproval,
      bool allowMemberInvites,
      bool enablePolls,
      bool enableChat,
      bool enableEvents,
      int maxMembers,
      int veteranGamesThreshold,
      String? invitationCode,
      bool invitationsEnabled,
      @JoinModeConverter() JoinMode joinMode,
      @MatchLoggingPolicyConverter() MatchLoggingPolicy matchLoggingPolicy,
      bool enableMotmVoting});
}

/// @nodoc
class _$HubSettingsCopyWithImpl<$Res, $Val extends HubSettings>
    implements $HubSettingsCopyWith<$Res> {
  _$HubSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HubSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? showManagerContactInfo = null,
    Object? allowJoinRequests = null,
    Object? allowModeratorsToCreateGames = null,
    Object? requireResultApproval = null,
    Object? allowMemberInvites = null,
    Object? enablePolls = null,
    Object? enableChat = null,
    Object? enableEvents = null,
    Object? maxMembers = null,
    Object? veteranGamesThreshold = null,
    Object? invitationCode = freezed,
    Object? invitationsEnabled = null,
    Object? joinMode = null,
    Object? matchLoggingPolicy = null,
    Object? enableMotmVoting = null,
  }) {
    return _then(_value.copyWith(
      showManagerContactInfo: null == showManagerContactInfo
          ? _value.showManagerContactInfo
          : showManagerContactInfo // ignore: cast_nullable_to_non_nullable
              as bool,
      allowJoinRequests: null == allowJoinRequests
          ? _value.allowJoinRequests
          : allowJoinRequests // ignore: cast_nullable_to_non_nullable
              as bool,
      allowModeratorsToCreateGames: null == allowModeratorsToCreateGames
          ? _value.allowModeratorsToCreateGames
          : allowModeratorsToCreateGames // ignore: cast_nullable_to_non_nullable
              as bool,
      requireResultApproval: null == requireResultApproval
          ? _value.requireResultApproval
          : requireResultApproval // ignore: cast_nullable_to_non_nullable
              as bool,
      allowMemberInvites: null == allowMemberInvites
          ? _value.allowMemberInvites
          : allowMemberInvites // ignore: cast_nullable_to_non_nullable
              as bool,
      enablePolls: null == enablePolls
          ? _value.enablePolls
          : enablePolls // ignore: cast_nullable_to_non_nullable
              as bool,
      enableChat: null == enableChat
          ? _value.enableChat
          : enableChat // ignore: cast_nullable_to_non_nullable
              as bool,
      enableEvents: null == enableEvents
          ? _value.enableEvents
          : enableEvents // ignore: cast_nullable_to_non_nullable
              as bool,
      maxMembers: null == maxMembers
          ? _value.maxMembers
          : maxMembers // ignore: cast_nullable_to_non_nullable
              as int,
      veteranGamesThreshold: null == veteranGamesThreshold
          ? _value.veteranGamesThreshold
          : veteranGamesThreshold // ignore: cast_nullable_to_non_nullable
              as int,
      invitationCode: freezed == invitationCode
          ? _value.invitationCode
          : invitationCode // ignore: cast_nullable_to_non_nullable
              as String?,
      invitationsEnabled: null == invitationsEnabled
          ? _value.invitationsEnabled
          : invitationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      joinMode: null == joinMode
          ? _value.joinMode
          : joinMode // ignore: cast_nullable_to_non_nullable
              as JoinMode,
      matchLoggingPolicy: null == matchLoggingPolicy
          ? _value.matchLoggingPolicy
          : matchLoggingPolicy // ignore: cast_nullable_to_non_nullable
              as MatchLoggingPolicy,
      enableMotmVoting: null == enableMotmVoting
          ? _value.enableMotmVoting
          : enableMotmVoting // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HubSettingsImplCopyWith<$Res>
    implements $HubSettingsCopyWith<$Res> {
  factory _$$HubSettingsImplCopyWith(
          _$HubSettingsImpl value, $Res Function(_$HubSettingsImpl) then) =
      __$$HubSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool showManagerContactInfo,
      bool allowJoinRequests,
      bool allowModeratorsToCreateGames,
      bool requireResultApproval,
      bool allowMemberInvites,
      bool enablePolls,
      bool enableChat,
      bool enableEvents,
      int maxMembers,
      int veteranGamesThreshold,
      String? invitationCode,
      bool invitationsEnabled,
      @JoinModeConverter() JoinMode joinMode,
      @MatchLoggingPolicyConverter() MatchLoggingPolicy matchLoggingPolicy,
      bool enableMotmVoting});
}

/// @nodoc
class __$$HubSettingsImplCopyWithImpl<$Res>
    extends _$HubSettingsCopyWithImpl<$Res, _$HubSettingsImpl>
    implements _$$HubSettingsImplCopyWith<$Res> {
  __$$HubSettingsImplCopyWithImpl(
      _$HubSettingsImpl _value, $Res Function(_$HubSettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of HubSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? showManagerContactInfo = null,
    Object? allowJoinRequests = null,
    Object? allowModeratorsToCreateGames = null,
    Object? requireResultApproval = null,
    Object? allowMemberInvites = null,
    Object? enablePolls = null,
    Object? enableChat = null,
    Object? enableEvents = null,
    Object? maxMembers = null,
    Object? veteranGamesThreshold = null,
    Object? invitationCode = freezed,
    Object? invitationsEnabled = null,
    Object? joinMode = null,
    Object? matchLoggingPolicy = null,
    Object? enableMotmVoting = null,
  }) {
    return _then(_$HubSettingsImpl(
      showManagerContactInfo: null == showManagerContactInfo
          ? _value.showManagerContactInfo
          : showManagerContactInfo // ignore: cast_nullable_to_non_nullable
              as bool,
      allowJoinRequests: null == allowJoinRequests
          ? _value.allowJoinRequests
          : allowJoinRequests // ignore: cast_nullable_to_non_nullable
              as bool,
      allowModeratorsToCreateGames: null == allowModeratorsToCreateGames
          ? _value.allowModeratorsToCreateGames
          : allowModeratorsToCreateGames // ignore: cast_nullable_to_non_nullable
              as bool,
      requireResultApproval: null == requireResultApproval
          ? _value.requireResultApproval
          : requireResultApproval // ignore: cast_nullable_to_non_nullable
              as bool,
      allowMemberInvites: null == allowMemberInvites
          ? _value.allowMemberInvites
          : allowMemberInvites // ignore: cast_nullable_to_non_nullable
              as bool,
      enablePolls: null == enablePolls
          ? _value.enablePolls
          : enablePolls // ignore: cast_nullable_to_non_nullable
              as bool,
      enableChat: null == enableChat
          ? _value.enableChat
          : enableChat // ignore: cast_nullable_to_non_nullable
              as bool,
      enableEvents: null == enableEvents
          ? _value.enableEvents
          : enableEvents // ignore: cast_nullable_to_non_nullable
              as bool,
      maxMembers: null == maxMembers
          ? _value.maxMembers
          : maxMembers // ignore: cast_nullable_to_non_nullable
              as int,
      veteranGamesThreshold: null == veteranGamesThreshold
          ? _value.veteranGamesThreshold
          : veteranGamesThreshold // ignore: cast_nullable_to_non_nullable
              as int,
      invitationCode: freezed == invitationCode
          ? _value.invitationCode
          : invitationCode // ignore: cast_nullable_to_non_nullable
              as String?,
      invitationsEnabled: null == invitationsEnabled
          ? _value.invitationsEnabled
          : invitationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      joinMode: null == joinMode
          ? _value.joinMode
          : joinMode // ignore: cast_nullable_to_non_nullable
              as JoinMode,
      matchLoggingPolicy: null == matchLoggingPolicy
          ? _value.matchLoggingPolicy
          : matchLoggingPolicy // ignore: cast_nullable_to_non_nullable
              as MatchLoggingPolicy,
      enableMotmVoting: null == enableMotmVoting
          ? _value.enableMotmVoting
          : enableMotmVoting // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HubSettingsImpl extends _HubSettings {
  const _$HubSettingsImpl(
      {this.showManagerContactInfo = true,
      this.allowJoinRequests = true,
      this.allowModeratorsToCreateGames = false,
      this.requireResultApproval = false,
      this.allowMemberInvites = true,
      this.enablePolls = true,
      this.enableChat = true,
      this.enableEvents = true,
      this.maxMembers = 50,
      this.veteranGamesThreshold = 10,
      this.invitationCode,
      this.invitationsEnabled = true,
      @JoinModeConverter() this.joinMode = JoinMode.auto,
      @MatchLoggingPolicyConverter()
      this.matchLoggingPolicy = MatchLoggingPolicy.managerOnly,
      this.enableMotmVoting = false})
      : super._();

  factory _$HubSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$HubSettingsImplFromJson(json);

  /// Show manager contact information to members
  @override
  @JsonKey()
  final bool showManagerContactInfo;

  /// Allow users to request to join the hub
  @override
  @JsonKey()
  final bool allowJoinRequests;

  /// Allow moderators to create games from events
  /// (normally only managers can create games)
  @override
  @JsonKey()
  final bool allowModeratorsToCreateGames;

  /// Require game results to be approved by manager before being recorded
  @override
  @JsonKey()
  final bool requireResultApproval;

  /// Allow members to invite other players to the hub
  @override
  @JsonKey()
  final bool allowMemberInvites;

  /// Enable polls feature for this hub
  @override
  @JsonKey()
  final bool enablePolls;

  /// Enable chat feature for this hub
  @override
  @JsonKey()
  final bool enableChat;

  /// Enable events feature for this hub
  @override
  @JsonKey()
  final bool enableEvents;

  /// Maximum number of members allowed in the hub
  /// Default: 50 (standard hub size)
  /// Set to 0 for unlimited (not recommended for community management)
  @override
  @JsonKey()
  final int maxMembers;

  /// Minimum number of games played to be considered a veteran
  @override
  @JsonKey()
  final int veteranGamesThreshold;

  /// Invitation code for joining the hub
  /// If null, uses hubId.substring(0, 8) as fallback
  @override
  final String? invitationCode;

  /// Enable/disable invitations for this hub
  @override
  @JsonKey()
  final bool invitationsEnabled;

  /// Join mode: auto (immediate) or approval (requires manager approval)
  @override
  @JsonKey()
  @JoinModeConverter()
  final JoinMode joinMode;

  /// Match logging policy: who can log matches
  @override
  @JsonKey()
  @MatchLoggingPolicyConverter()
  final MatchLoggingPolicy matchLoggingPolicy;

  /// Enable Man of the Match voting (Sprint 3)
  /// When enabled, games created in this hub will have MOTM voting by default
  @override
  @JsonKey()
  final bool enableMotmVoting;

  @override
  String toString() {
    return 'HubSettings(showManagerContactInfo: $showManagerContactInfo, allowJoinRequests: $allowJoinRequests, allowModeratorsToCreateGames: $allowModeratorsToCreateGames, requireResultApproval: $requireResultApproval, allowMemberInvites: $allowMemberInvites, enablePolls: $enablePolls, enableChat: $enableChat, enableEvents: $enableEvents, maxMembers: $maxMembers, veteranGamesThreshold: $veteranGamesThreshold, invitationCode: $invitationCode, invitationsEnabled: $invitationsEnabled, joinMode: $joinMode, matchLoggingPolicy: $matchLoggingPolicy, enableMotmVoting: $enableMotmVoting)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HubSettingsImpl &&
            (identical(other.showManagerContactInfo, showManagerContactInfo) ||
                other.showManagerContactInfo == showManagerContactInfo) &&
            (identical(other.allowJoinRequests, allowJoinRequests) ||
                other.allowJoinRequests == allowJoinRequests) &&
            (identical(other.allowModeratorsToCreateGames,
                    allowModeratorsToCreateGames) ||
                other.allowModeratorsToCreateGames ==
                    allowModeratorsToCreateGames) &&
            (identical(other.requireResultApproval, requireResultApproval) ||
                other.requireResultApproval == requireResultApproval) &&
            (identical(other.allowMemberInvites, allowMemberInvites) ||
                other.allowMemberInvites == allowMemberInvites) &&
            (identical(other.enablePolls, enablePolls) ||
                other.enablePolls == enablePolls) &&
            (identical(other.enableChat, enableChat) ||
                other.enableChat == enableChat) &&
            (identical(other.enableEvents, enableEvents) ||
                other.enableEvents == enableEvents) &&
            (identical(other.maxMembers, maxMembers) ||
                other.maxMembers == maxMembers) &&
            (identical(other.veteranGamesThreshold, veteranGamesThreshold) ||
                other.veteranGamesThreshold == veteranGamesThreshold) &&
            (identical(other.invitationCode, invitationCode) ||
                other.invitationCode == invitationCode) &&
            (identical(other.invitationsEnabled, invitationsEnabled) ||
                other.invitationsEnabled == invitationsEnabled) &&
            (identical(other.joinMode, joinMode) ||
                other.joinMode == joinMode) &&
            (identical(other.matchLoggingPolicy, matchLoggingPolicy) ||
                other.matchLoggingPolicy == matchLoggingPolicy) &&
            (identical(other.enableMotmVoting, enableMotmVoting) ||
                other.enableMotmVoting == enableMotmVoting));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      showManagerContactInfo,
      allowJoinRequests,
      allowModeratorsToCreateGames,
      requireResultApproval,
      allowMemberInvites,
      enablePolls,
      enableChat,
      enableEvents,
      maxMembers,
      veteranGamesThreshold,
      invitationCode,
      invitationsEnabled,
      joinMode,
      matchLoggingPolicy,
      enableMotmVoting);

  /// Create a copy of HubSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HubSettingsImplCopyWith<_$HubSettingsImpl> get copyWith =>
      __$$HubSettingsImplCopyWithImpl<_$HubSettingsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HubSettingsImplToJson(
      this,
    );
  }
}

abstract class _HubSettings extends HubSettings {
  const factory _HubSettings(
      {final bool showManagerContactInfo,
      final bool allowJoinRequests,
      final bool allowModeratorsToCreateGames,
      final bool requireResultApproval,
      final bool allowMemberInvites,
      final bool enablePolls,
      final bool enableChat,
      final bool enableEvents,
      final int maxMembers,
      final int veteranGamesThreshold,
      final String? invitationCode,
      final bool invitationsEnabled,
      @JoinModeConverter() final JoinMode joinMode,
      @MatchLoggingPolicyConverter()
      final MatchLoggingPolicy matchLoggingPolicy,
      final bool enableMotmVoting}) = _$HubSettingsImpl;
  const _HubSettings._() : super._();

  factory _HubSettings.fromJson(Map<String, dynamic> json) =
      _$HubSettingsImpl.fromJson;

  /// Show manager contact information to members
  @override
  bool get showManagerContactInfo;

  /// Allow users to request to join the hub
  @override
  bool get allowJoinRequests;

  /// Allow moderators to create games from events
  /// (normally only managers can create games)
  @override
  bool get allowModeratorsToCreateGames;

  /// Require game results to be approved by manager before being recorded
  @override
  bool get requireResultApproval;

  /// Allow members to invite other players to the hub
  @override
  bool get allowMemberInvites;

  /// Enable polls feature for this hub
  @override
  bool get enablePolls;

  /// Enable chat feature for this hub
  @override
  bool get enableChat;

  /// Enable events feature for this hub
  @override
  bool get enableEvents;

  /// Maximum number of members allowed in the hub
  /// Default: 50 (standard hub size)
  /// Set to 0 for unlimited (not recommended for community management)
  @override
  int get maxMembers;

  /// Minimum number of games played to be considered a veteran
  @override
  int get veteranGamesThreshold;

  /// Invitation code for joining the hub
  /// If null, uses hubId.substring(0, 8) as fallback
  @override
  String? get invitationCode;

  /// Enable/disable invitations for this hub
  @override
  bool get invitationsEnabled;

  /// Join mode: auto (immediate) or approval (requires manager approval)
  @override
  @JoinModeConverter()
  JoinMode get joinMode;

  /// Match logging policy: who can log matches
  @override
  @MatchLoggingPolicyConverter()
  MatchLoggingPolicy get matchLoggingPolicy;

  /// Enable Man of the Match voting (Sprint 3)
  /// When enabled, games created in this hub will have MOTM voting by default
  @override
  bool get enableMotmVoting;

  /// Create a copy of HubSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HubSettingsImplCopyWith<_$HubSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
