// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hub.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Hub _$HubFromJson(Map<String, dynamic> json) {
  return _Hub.fromJson(json);
}

/// @nodoc
mixin _$Hub {
// Core identity
  String get hubId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt =>
      throw _privateConstructorUsedError; // Member count (denormalized for display, kept in sync by Cloud Function)
  int get memberCount =>
      throw _privateConstructorUsedError; // Denormalized member arrays (CRITICAL for Firestore Rules optimization)
// These eliminate costly get() calls in security rules by denormalizing
// membership data directly into the Hub document.
// ⚠️ MUST be kept in sync by repository methods (addMember, removeMember, updateMemberRole)
  List<String> get activeMemberIds =>
      throw _privateConstructorUsedError; // All active member user IDs
  List<String> get managerIds =>
      throw _privateConstructorUsedError; // User IDs with 'manager' role
  List<String> get moderatorIds =>
      throw _privateConstructorUsedError; // User IDs with 'moderator' role
// Settings (typed for compile-time safety)
  @HubSettingsConverter()
  HubSettings get settings =>
      throw _privateConstructorUsedError; // @deprecated Legacy settings map - kept for backward compatibility during migration
// Use `settings` field instead. Will be removed after all data is migrated.
  @Deprecated('Use settings field instead')
  Map<String, dynamic>? get legacySettings =>
      throw _privateConstructorUsedError; // Custom permissions (RARE overrides only)
// Example: Allow specific user to create events even if not moderator
// Format: {'canCreateEvents': ['userId1', 'userId2']}
  Map<String, dynamic> get permissions =>
      throw _privateConstructorUsedError; // Location & venues
  @NullableGeoPointConverter()
  GeoPoint? get location =>
      throw _privateConstructorUsedError; // Primary location (deprecated, use venues)
  String? get geohash => throw _privateConstructorUsedError;
  double? get radius => throw _privateConstructorUsedError; // radius in km
  List<String> get venueIds =>
      throw _privateConstructorUsedError; // IDs of venues where this hub plays
  String? get mainVenueId =>
      throw _privateConstructorUsedError; // ID of the main venue (home field) - required
  String? get primaryVenueId =>
      throw _privateConstructorUsedError; // ID of the primary venue (for map display) - denormalized
  @NullableGeoPointConverter()
  GeoPoint? get primaryVenueLocation =>
      throw _privateConstructorUsedError; // Location of primary venue - denormalized
// Branding
  String? get profileImageUrl =>
      throw _privateConstructorUsedError; // Profile picture chosen by hub manager
  String? get logoUrl =>
      throw _privateConstructorUsedError; // Hub logo URL (used for feed posts)
  String? get bannerUrl =>
      throw _privateConstructorUsedError; // Hero banner for hub profile
// Rules & region
  String? get hubRules =>
      throw _privateConstructorUsedError; // Rules and guidelines for the hub
  String? get region =>
      throw _privateConstructorUsedError; // אזור: צפון, מרכז, דרום, ירושלים
  String? get city =>
      throw _privateConstructorUsedError; // עיר ראשית של ההאב (auto-calculates region)
// Privacy
  bool get isPrivate =>
      throw _privateConstructorUsedError; // If true, requires "Request to Join"
// Payment
  String? get paymentLink =>
      throw _privateConstructorUsedError; // PayBox/Bit payment link URL
// Denormalized stats (updated by Cloud Functions, not written by client)
  int? get gameCount =>
      throw _privateConstructorUsedError; // Total games created (updated by onGameCreated)
  @TimestampConverter()
  DateTime? get lastActivity =>
      throw _privateConstructorUsedError; // Last activity time (updated by Cloud Functions)
  double get activityScore => throw _privateConstructorUsedError;

  /// Serializes this Hub to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Hub
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HubCopyWith<Hub> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HubCopyWith<$Res> {
  factory $HubCopyWith(Hub value, $Res Function(Hub) then) =
      _$HubCopyWithImpl<$Res, Hub>;
  @useResult
  $Res call(
      {String hubId,
      String name,
      String? description,
      String createdBy,
      @TimestampConverter() DateTime createdAt,
      int memberCount,
      List<String> activeMemberIds,
      List<String> managerIds,
      List<String> moderatorIds,
      @HubSettingsConverter() HubSettings settings,
      @Deprecated('Use settings field instead')
      Map<String, dynamic>? legacySettings,
      Map<String, dynamic> permissions,
      @NullableGeoPointConverter() GeoPoint? location,
      String? geohash,
      double? radius,
      List<String> venueIds,
      String? mainVenueId,
      String? primaryVenueId,
      @NullableGeoPointConverter() GeoPoint? primaryVenueLocation,
      String? profileImageUrl,
      String? logoUrl,
      String? bannerUrl,
      String? hubRules,
      String? region,
      String? city,
      bool isPrivate,
      String? paymentLink,
      int? gameCount,
      @TimestampConverter() DateTime? lastActivity,
      double activityScore});

  $HubSettingsCopyWith<$Res> get settings;
}

/// @nodoc
class _$HubCopyWithImpl<$Res, $Val extends Hub> implements $HubCopyWith<$Res> {
  _$HubCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Hub
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hubId = null,
    Object? name = null,
    Object? description = freezed,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? memberCount = null,
    Object? activeMemberIds = null,
    Object? managerIds = null,
    Object? moderatorIds = null,
    Object? settings = null,
    Object? legacySettings = freezed,
    Object? permissions = null,
    Object? location = freezed,
    Object? geohash = freezed,
    Object? radius = freezed,
    Object? venueIds = null,
    Object? mainVenueId = freezed,
    Object? primaryVenueId = freezed,
    Object? primaryVenueLocation = freezed,
    Object? profileImageUrl = freezed,
    Object? logoUrl = freezed,
    Object? bannerUrl = freezed,
    Object? hubRules = freezed,
    Object? region = freezed,
    Object? city = freezed,
    Object? isPrivate = null,
    Object? paymentLink = freezed,
    Object? gameCount = freezed,
    Object? lastActivity = freezed,
    Object? activityScore = null,
  }) {
    return _then(_value.copyWith(
      hubId: null == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      memberCount: null == memberCount
          ? _value.memberCount
          : memberCount // ignore: cast_nullable_to_non_nullable
              as int,
      activeMemberIds: null == activeMemberIds
          ? _value.activeMemberIds
          : activeMemberIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      managerIds: null == managerIds
          ? _value.managerIds
          : managerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      moderatorIds: null == moderatorIds
          ? _value.moderatorIds
          : moderatorIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      settings: null == settings
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as HubSettings,
      legacySettings: freezed == legacySettings
          ? _value.legacySettings
          : legacySettings // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      permissions: null == permissions
          ? _value.permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeoPoint?,
      geohash: freezed == geohash
          ? _value.geohash
          : geohash // ignore: cast_nullable_to_non_nullable
              as String?,
      radius: freezed == radius
          ? _value.radius
          : radius // ignore: cast_nullable_to_non_nullable
              as double?,
      venueIds: null == venueIds
          ? _value.venueIds
          : venueIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      mainVenueId: freezed == mainVenueId
          ? _value.mainVenueId
          : mainVenueId // ignore: cast_nullable_to_non_nullable
              as String?,
      primaryVenueId: freezed == primaryVenueId
          ? _value.primaryVenueId
          : primaryVenueId // ignore: cast_nullable_to_non_nullable
              as String?,
      primaryVenueLocation: freezed == primaryVenueLocation
          ? _value.primaryVenueLocation
          : primaryVenueLocation // ignore: cast_nullable_to_non_nullable
              as GeoPoint?,
      profileImageUrl: freezed == profileImageUrl
          ? _value.profileImageUrl
          : profileImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      logoUrl: freezed == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      bannerUrl: freezed == bannerUrl
          ? _value.bannerUrl
          : bannerUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      hubRules: freezed == hubRules
          ? _value.hubRules
          : hubRules // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      isPrivate: null == isPrivate
          ? _value.isPrivate
          : isPrivate // ignore: cast_nullable_to_non_nullable
              as bool,
      paymentLink: freezed == paymentLink
          ? _value.paymentLink
          : paymentLink // ignore: cast_nullable_to_non_nullable
              as String?,
      gameCount: freezed == gameCount
          ? _value.gameCount
          : gameCount // ignore: cast_nullable_to_non_nullable
              as int?,
      lastActivity: freezed == lastActivity
          ? _value.lastActivity
          : lastActivity // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      activityScore: null == activityScore
          ? _value.activityScore
          : activityScore // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }

  /// Create a copy of Hub
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HubSettingsCopyWith<$Res> get settings {
    return $HubSettingsCopyWith<$Res>(_value.settings, (value) {
      return _then(_value.copyWith(settings: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$HubImplCopyWith<$Res> implements $HubCopyWith<$Res> {
  factory _$$HubImplCopyWith(_$HubImpl value, $Res Function(_$HubImpl) then) =
      __$$HubImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String hubId,
      String name,
      String? description,
      String createdBy,
      @TimestampConverter() DateTime createdAt,
      int memberCount,
      List<String> activeMemberIds,
      List<String> managerIds,
      List<String> moderatorIds,
      @HubSettingsConverter() HubSettings settings,
      @Deprecated('Use settings field instead')
      Map<String, dynamic>? legacySettings,
      Map<String, dynamic> permissions,
      @NullableGeoPointConverter() GeoPoint? location,
      String? geohash,
      double? radius,
      List<String> venueIds,
      String? mainVenueId,
      String? primaryVenueId,
      @NullableGeoPointConverter() GeoPoint? primaryVenueLocation,
      String? profileImageUrl,
      String? logoUrl,
      String? bannerUrl,
      String? hubRules,
      String? region,
      String? city,
      bool isPrivate,
      String? paymentLink,
      int? gameCount,
      @TimestampConverter() DateTime? lastActivity,
      double activityScore});

  @override
  $HubSettingsCopyWith<$Res> get settings;
}

/// @nodoc
class __$$HubImplCopyWithImpl<$Res> extends _$HubCopyWithImpl<$Res, _$HubImpl>
    implements _$$HubImplCopyWith<$Res> {
  __$$HubImplCopyWithImpl(_$HubImpl _value, $Res Function(_$HubImpl) _then)
      : super(_value, _then);

  /// Create a copy of Hub
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hubId = null,
    Object? name = null,
    Object? description = freezed,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? memberCount = null,
    Object? activeMemberIds = null,
    Object? managerIds = null,
    Object? moderatorIds = null,
    Object? settings = null,
    Object? legacySettings = freezed,
    Object? permissions = null,
    Object? location = freezed,
    Object? geohash = freezed,
    Object? radius = freezed,
    Object? venueIds = null,
    Object? mainVenueId = freezed,
    Object? primaryVenueId = freezed,
    Object? primaryVenueLocation = freezed,
    Object? profileImageUrl = freezed,
    Object? logoUrl = freezed,
    Object? bannerUrl = freezed,
    Object? hubRules = freezed,
    Object? region = freezed,
    Object? city = freezed,
    Object? isPrivate = null,
    Object? paymentLink = freezed,
    Object? gameCount = freezed,
    Object? lastActivity = freezed,
    Object? activityScore = null,
  }) {
    return _then(_$HubImpl(
      hubId: null == hubId
          ? _value.hubId
          : hubId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      memberCount: null == memberCount
          ? _value.memberCount
          : memberCount // ignore: cast_nullable_to_non_nullable
              as int,
      activeMemberIds: null == activeMemberIds
          ? _value._activeMemberIds
          : activeMemberIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      managerIds: null == managerIds
          ? _value._managerIds
          : managerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      moderatorIds: null == moderatorIds
          ? _value._moderatorIds
          : moderatorIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      settings: null == settings
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as HubSettings,
      legacySettings: freezed == legacySettings
          ? _value._legacySettings
          : legacySettings // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      permissions: null == permissions
          ? _value._permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeoPoint?,
      geohash: freezed == geohash
          ? _value.geohash
          : geohash // ignore: cast_nullable_to_non_nullable
              as String?,
      radius: freezed == radius
          ? _value.radius
          : radius // ignore: cast_nullable_to_non_nullable
              as double?,
      venueIds: null == venueIds
          ? _value._venueIds
          : venueIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      mainVenueId: freezed == mainVenueId
          ? _value.mainVenueId
          : mainVenueId // ignore: cast_nullable_to_non_nullable
              as String?,
      primaryVenueId: freezed == primaryVenueId
          ? _value.primaryVenueId
          : primaryVenueId // ignore: cast_nullable_to_non_nullable
              as String?,
      primaryVenueLocation: freezed == primaryVenueLocation
          ? _value.primaryVenueLocation
          : primaryVenueLocation // ignore: cast_nullable_to_non_nullable
              as GeoPoint?,
      profileImageUrl: freezed == profileImageUrl
          ? _value.profileImageUrl
          : profileImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      logoUrl: freezed == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      bannerUrl: freezed == bannerUrl
          ? _value.bannerUrl
          : bannerUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      hubRules: freezed == hubRules
          ? _value.hubRules
          : hubRules // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      isPrivate: null == isPrivate
          ? _value.isPrivate
          : isPrivate // ignore: cast_nullable_to_non_nullable
              as bool,
      paymentLink: freezed == paymentLink
          ? _value.paymentLink
          : paymentLink // ignore: cast_nullable_to_non_nullable
              as String?,
      gameCount: freezed == gameCount
          ? _value.gameCount
          : gameCount // ignore: cast_nullable_to_non_nullable
              as int?,
      lastActivity: freezed == lastActivity
          ? _value.lastActivity
          : lastActivity // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      activityScore: null == activityScore
          ? _value.activityScore
          : activityScore // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HubImpl implements _Hub {
  const _$HubImpl(
      {required this.hubId,
      required this.name,
      this.description,
      required this.createdBy,
      @TimestampConverter() required this.createdAt,
      this.memberCount = 0,
      final List<String> activeMemberIds = const [],
      final List<String> managerIds = const [],
      final List<String> moderatorIds = const [],
      @HubSettingsConverter() this.settings = const HubSettings(),
      @Deprecated('Use settings field instead')
      final Map<String, dynamic>? legacySettings,
      final Map<String, dynamic> permissions = const {},
      @NullableGeoPointConverter() this.location,
      this.geohash,
      this.radius,
      final List<String> venueIds = const [],
      this.mainVenueId,
      this.primaryVenueId,
      @NullableGeoPointConverter() this.primaryVenueLocation,
      this.profileImageUrl,
      this.logoUrl,
      this.bannerUrl,
      this.hubRules,
      this.region,
      this.city,
      this.isPrivate = false,
      this.paymentLink,
      this.gameCount,
      @TimestampConverter() this.lastActivity,
      this.activityScore = 0})
      : _activeMemberIds = activeMemberIds,
        _managerIds = managerIds,
        _moderatorIds = moderatorIds,
        _legacySettings = legacySettings,
        _permissions = permissions,
        _venueIds = venueIds;

  factory _$HubImpl.fromJson(Map<String, dynamic> json) =>
      _$$HubImplFromJson(json);

// Core identity
  @override
  final String hubId;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String createdBy;
  @override
  @TimestampConverter()
  final DateTime createdAt;
// Member count (denormalized for display, kept in sync by Cloud Function)
  @override
  @JsonKey()
  final int memberCount;
// Denormalized member arrays (CRITICAL for Firestore Rules optimization)
// These eliminate costly get() calls in security rules by denormalizing
// membership data directly into the Hub document.
// ⚠️ MUST be kept in sync by repository methods (addMember, removeMember, updateMemberRole)
  final List<String> _activeMemberIds;
// Denormalized member arrays (CRITICAL for Firestore Rules optimization)
// These eliminate costly get() calls in security rules by denormalizing
// membership data directly into the Hub document.
// ⚠️ MUST be kept in sync by repository methods (addMember, removeMember, updateMemberRole)
  @override
  @JsonKey()
  List<String> get activeMemberIds {
    if (_activeMemberIds is EqualUnmodifiableListView) return _activeMemberIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_activeMemberIds);
  }

// All active member user IDs
  final List<String> _managerIds;
// All active member user IDs
  @override
  @JsonKey()
  List<String> get managerIds {
    if (_managerIds is EqualUnmodifiableListView) return _managerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_managerIds);
  }

// User IDs with 'manager' role
  final List<String> _moderatorIds;
// User IDs with 'manager' role
  @override
  @JsonKey()
  List<String> get moderatorIds {
    if (_moderatorIds is EqualUnmodifiableListView) return _moderatorIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_moderatorIds);
  }

// User IDs with 'moderator' role
// Settings (typed for compile-time safety)
  @override
  @JsonKey()
  @HubSettingsConverter()
  final HubSettings settings;
// @deprecated Legacy settings map - kept for backward compatibility during migration
// Use `settings` field instead. Will be removed after all data is migrated.
  final Map<String, dynamic>? _legacySettings;
// @deprecated Legacy settings map - kept for backward compatibility during migration
// Use `settings` field instead. Will be removed after all data is migrated.
  @override
  @Deprecated('Use settings field instead')
  Map<String, dynamic>? get legacySettings {
    final value = _legacySettings;
    if (value == null) return null;
    if (_legacySettings is EqualUnmodifiableMapView) return _legacySettings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

// Custom permissions (RARE overrides only)
// Example: Allow specific user to create events even if not moderator
// Format: {'canCreateEvents': ['userId1', 'userId2']}
  final Map<String, dynamic> _permissions;
// Custom permissions (RARE overrides only)
// Example: Allow specific user to create events even if not moderator
// Format: {'canCreateEvents': ['userId1', 'userId2']}
  @override
  @JsonKey()
  Map<String, dynamic> get permissions {
    if (_permissions is EqualUnmodifiableMapView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_permissions);
  }

// Location & venues
  @override
  @NullableGeoPointConverter()
  final GeoPoint? location;
// Primary location (deprecated, use venues)
  @override
  final String? geohash;
  @override
  final double? radius;
// radius in km
  final List<String> _venueIds;
// radius in km
  @override
  @JsonKey()
  List<String> get venueIds {
    if (_venueIds is EqualUnmodifiableListView) return _venueIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_venueIds);
  }

// IDs of venues where this hub plays
  @override
  final String? mainVenueId;
// ID of the main venue (home field) - required
  @override
  final String? primaryVenueId;
// ID of the primary venue (for map display) - denormalized
  @override
  @NullableGeoPointConverter()
  final GeoPoint? primaryVenueLocation;
// Location of primary venue - denormalized
// Branding
  @override
  final String? profileImageUrl;
// Profile picture chosen by hub manager
  @override
  final String? logoUrl;
// Hub logo URL (used for feed posts)
  @override
  final String? bannerUrl;
// Hero banner for hub profile
// Rules & region
  @override
  final String? hubRules;
// Rules and guidelines for the hub
  @override
  final String? region;
// אזור: צפון, מרכז, דרום, ירושלים
  @override
  final String? city;
// עיר ראשית של ההאב (auto-calculates region)
// Privacy
  @override
  @JsonKey()
  final bool isPrivate;
// If true, requires "Request to Join"
// Payment
  @override
  final String? paymentLink;
// PayBox/Bit payment link URL
// Denormalized stats (updated by Cloud Functions, not written by client)
  @override
  final int? gameCount;
// Total games created (updated by onGameCreated)
  @override
  @TimestampConverter()
  final DateTime? lastActivity;
// Last activity time (updated by Cloud Functions)
  @override
  @JsonKey()
  final double activityScore;

  @override
  String toString() {
    return 'Hub(hubId: $hubId, name: $name, description: $description, createdBy: $createdBy, createdAt: $createdAt, memberCount: $memberCount, activeMemberIds: $activeMemberIds, managerIds: $managerIds, moderatorIds: $moderatorIds, settings: $settings, legacySettings: $legacySettings, permissions: $permissions, location: $location, geohash: $geohash, radius: $radius, venueIds: $venueIds, mainVenueId: $mainVenueId, primaryVenueId: $primaryVenueId, primaryVenueLocation: $primaryVenueLocation, profileImageUrl: $profileImageUrl, logoUrl: $logoUrl, bannerUrl: $bannerUrl, hubRules: $hubRules, region: $region, city: $city, isPrivate: $isPrivate, paymentLink: $paymentLink, gameCount: $gameCount, lastActivity: $lastActivity, activityScore: $activityScore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HubImpl &&
            (identical(other.hubId, hubId) || other.hubId == hubId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.memberCount, memberCount) ||
                other.memberCount == memberCount) &&
            const DeepCollectionEquality()
                .equals(other._activeMemberIds, _activeMemberIds) &&
            const DeepCollectionEquality()
                .equals(other._managerIds, _managerIds) &&
            const DeepCollectionEquality()
                .equals(other._moderatorIds, _moderatorIds) &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
            const DeepCollectionEquality()
                .equals(other._legacySettings, _legacySettings) &&
            const DeepCollectionEquality()
                .equals(other._permissions, _permissions) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.geohash, geohash) || other.geohash == geohash) &&
            (identical(other.radius, radius) || other.radius == radius) &&
            const DeepCollectionEquality().equals(other._venueIds, _venueIds) &&
            (identical(other.mainVenueId, mainVenueId) ||
                other.mainVenueId == mainVenueId) &&
            (identical(other.primaryVenueId, primaryVenueId) ||
                other.primaryVenueId == primaryVenueId) &&
            (identical(other.primaryVenueLocation, primaryVenueLocation) ||
                other.primaryVenueLocation == primaryVenueLocation) &&
            (identical(other.profileImageUrl, profileImageUrl) ||
                other.profileImageUrl == profileImageUrl) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.bannerUrl, bannerUrl) ||
                other.bannerUrl == bannerUrl) &&
            (identical(other.hubRules, hubRules) ||
                other.hubRules == hubRules) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.isPrivate, isPrivate) ||
                other.isPrivate == isPrivate) &&
            (identical(other.paymentLink, paymentLink) ||
                other.paymentLink == paymentLink) &&
            (identical(other.gameCount, gameCount) ||
                other.gameCount == gameCount) &&
            (identical(other.lastActivity, lastActivity) ||
                other.lastActivity == lastActivity) &&
            (identical(other.activityScore, activityScore) ||
                other.activityScore == activityScore));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        hubId,
        name,
        description,
        createdBy,
        createdAt,
        memberCount,
        const DeepCollectionEquality().hash(_activeMemberIds),
        const DeepCollectionEquality().hash(_managerIds),
        const DeepCollectionEquality().hash(_moderatorIds),
        settings,
        const DeepCollectionEquality().hash(_legacySettings),
        const DeepCollectionEquality().hash(_permissions),
        location,
        geohash,
        radius,
        const DeepCollectionEquality().hash(_venueIds),
        mainVenueId,
        primaryVenueId,
        primaryVenueLocation,
        profileImageUrl,
        logoUrl,
        bannerUrl,
        hubRules,
        region,
        city,
        isPrivate,
        paymentLink,
        gameCount,
        lastActivity,
        activityScore
      ]);

  /// Create a copy of Hub
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HubImplCopyWith<_$HubImpl> get copyWith =>
      __$$HubImplCopyWithImpl<_$HubImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HubImplToJson(
      this,
    );
  }
}

abstract class _Hub implements Hub {
  const factory _Hub(
      {required final String hubId,
      required final String name,
      final String? description,
      required final String createdBy,
      @TimestampConverter() required final DateTime createdAt,
      final int memberCount,
      final List<String> activeMemberIds,
      final List<String> managerIds,
      final List<String> moderatorIds,
      @HubSettingsConverter() final HubSettings settings,
      @Deprecated('Use settings field instead')
      final Map<String, dynamic>? legacySettings,
      final Map<String, dynamic> permissions,
      @NullableGeoPointConverter() final GeoPoint? location,
      final String? geohash,
      final double? radius,
      final List<String> venueIds,
      final String? mainVenueId,
      final String? primaryVenueId,
      @NullableGeoPointConverter() final GeoPoint? primaryVenueLocation,
      final String? profileImageUrl,
      final String? logoUrl,
      final String? bannerUrl,
      final String? hubRules,
      final String? region,
      final String? city,
      final bool isPrivate,
      final String? paymentLink,
      final int? gameCount,
      @TimestampConverter() final DateTime? lastActivity,
      final double activityScore}) = _$HubImpl;

  factory _Hub.fromJson(Map<String, dynamic> json) = _$HubImpl.fromJson;

// Core identity
  @override
  String get hubId;
  @override
  String get name;
  @override
  String? get description;
  @override
  String get createdBy;
  @override
  @TimestampConverter()
  DateTime
      get createdAt; // Member count (denormalized for display, kept in sync by Cloud Function)
  @override
  int get memberCount; // Denormalized member arrays (CRITICAL for Firestore Rules optimization)
// These eliminate costly get() calls in security rules by denormalizing
// membership data directly into the Hub document.
// ⚠️ MUST be kept in sync by repository methods (addMember, removeMember, updateMemberRole)
  @override
  List<String> get activeMemberIds; // All active member user IDs
  @override
  List<String> get managerIds; // User IDs with 'manager' role
  @override
  List<String> get moderatorIds; // User IDs with 'moderator' role
// Settings (typed for compile-time safety)
  @override
  @HubSettingsConverter()
  HubSettings
      get settings; // @deprecated Legacy settings map - kept for backward compatibility during migration
// Use `settings` field instead. Will be removed after all data is migrated.
  @override
  @Deprecated('Use settings field instead')
  Map<String, dynamic>?
      get legacySettings; // Custom permissions (RARE overrides only)
// Example: Allow specific user to create events even if not moderator
// Format: {'canCreateEvents': ['userId1', 'userId2']}
  @override
  Map<String, dynamic> get permissions; // Location & venues
  @override
  @NullableGeoPointConverter()
  GeoPoint? get location; // Primary location (deprecated, use venues)
  @override
  String? get geohash;
  @override
  double? get radius; // radius in km
  @override
  List<String> get venueIds; // IDs of venues where this hub plays
  @override
  String? get mainVenueId; // ID of the main venue (home field) - required
  @override
  String?
      get primaryVenueId; // ID of the primary venue (for map display) - denormalized
  @override
  @NullableGeoPointConverter()
  GeoPoint?
      get primaryVenueLocation; // Location of primary venue - denormalized
// Branding
  @override
  String? get profileImageUrl; // Profile picture chosen by hub manager
  @override
  String? get logoUrl; // Hub logo URL (used for feed posts)
  @override
  String? get bannerUrl; // Hero banner for hub profile
// Rules & region
  @override
  String? get hubRules; // Rules and guidelines for the hub
  @override
  String? get region; // אזור: צפון, מרכז, דרום, ירושלים
  @override
  String? get city; // עיר ראשית של ההאב (auto-calculates region)
// Privacy
  @override
  bool get isPrivate; // If true, requires "Request to Join"
// Payment
  @override
  String? get paymentLink; // PayBox/Bit payment link URL
// Denormalized stats (updated by Cloud Functions, not written by client)
  @override
  int? get gameCount; // Total games created (updated by onGameCreated)
  @override
  @TimestampConverter()
  DateTime? get lastActivity; // Last activity time (updated by Cloud Functions)
  @override
  double get activityScore;

  /// Create a copy of Hub
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HubImplCopyWith<_$HubImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
