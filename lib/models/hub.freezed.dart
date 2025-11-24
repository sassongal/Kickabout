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
  String get hubId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  List<String> get memberIds => throw _privateConstructorUsedError;
  @TimestampMapConverter()
  Map<String, Timestamp> get memberJoinDates =>
      throw _privateConstructorUsedError; // userId -> join date timestamp
  Map<String, dynamic> get settings => throw _privateConstructorUsedError;
  Map<String, String> get roles =>
      throw _privateConstructorUsedError; // userId -> role (manager, moderator, member)
  Map<String, dynamic> get permissions =>
      throw _privateConstructorUsedError; // Custom permissions: {canCreateEvents: [userId1, userId2], canCreatePosts: [userId1, userId2]}
  @NullableGeoPointConverter()
  GeoPoint? get location =>
      throw _privateConstructorUsedError; // Primary location (deprecated, use venues)
  String? get geohash => throw _privateConstructorUsedError;
  double? get radius => throw _privateConstructorUsedError; // radius in km
  List<String> get venueIds =>
      throw _privateConstructorUsedError; // IDs of venues where this hub plays
  String? get profileImageUrl =>
      throw _privateConstructorUsedError; // Profile picture chosen by hub manager
  String? get mainVenueId =>
      throw _privateConstructorUsedError; // ID of the main venue (home field) - required
  String? get primaryVenueId =>
      throw _privateConstructorUsedError; // ID of the primary venue (for map display) - denormalized
  @NullableGeoPointConverter()
  GeoPoint? get primaryVenueLocation =>
      throw _privateConstructorUsedError; // Location of primary venue - denormalized
  String? get logoUrl =>
      throw _privateConstructorUsedError; // Hub logo URL (used for feed posts)
  String? get hubRules =>
      throw _privateConstructorUsedError; // Rules and guidelines for the hub
  String? get region =>
      throw _privateConstructorUsedError; // אזור: צפון, מרכז, דרום, ירושלים
// Privacy settings
  bool get isPrivate =>
      throw _privateConstructorUsedError; // If true, requires "Request to Join" (create notification for manager)
// Manager-only ratings for team balancing (1-10 scale)
  Map<String, double> get managerRatings =>
      throw _privateConstructorUsedError; // userId -> rating (1-10, manager-only, for team balancing)
// Payment settings
  String? get paymentLink =>
      throw _privateConstructorUsedError; // PayBox/Bit payment link URL
// Denormalized fields (updated by Cloud Functions, not written by client)
  int? get gameCount =>
      throw _privateConstructorUsedError; // Denormalized: Total games created (updated by onGameCreated)
  @TimestampConverter()
  DateTime? get lastActivity => throw _privateConstructorUsedError;

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
      List<String> memberIds,
      @TimestampMapConverter() Map<String, Timestamp> memberJoinDates,
      Map<String, dynamic> settings,
      Map<String, String> roles,
      Map<String, dynamic> permissions,
      @NullableGeoPointConverter() GeoPoint? location,
      String? geohash,
      double? radius,
      List<String> venueIds,
      String? profileImageUrl,
      String? mainVenueId,
      String? primaryVenueId,
      @NullableGeoPointConverter() GeoPoint? primaryVenueLocation,
      String? logoUrl,
      String? hubRules,
      String? region,
      bool isPrivate,
      Map<String, double> managerRatings,
      String? paymentLink,
      int? gameCount,
      @TimestampConverter() DateTime? lastActivity});
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
    Object? memberIds = null,
    Object? memberJoinDates = null,
    Object? settings = null,
    Object? roles = null,
    Object? permissions = null,
    Object? location = freezed,
    Object? geohash = freezed,
    Object? radius = freezed,
    Object? venueIds = null,
    Object? profileImageUrl = freezed,
    Object? mainVenueId = freezed,
    Object? primaryVenueId = freezed,
    Object? primaryVenueLocation = freezed,
    Object? logoUrl = freezed,
    Object? hubRules = freezed,
    Object? region = freezed,
    Object? isPrivate = null,
    Object? managerRatings = null,
    Object? paymentLink = freezed,
    Object? gameCount = freezed,
    Object? lastActivity = freezed,
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
      memberIds: null == memberIds
          ? _value.memberIds
          : memberIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      memberJoinDates: null == memberJoinDates
          ? _value.memberJoinDates
          : memberJoinDates // ignore: cast_nullable_to_non_nullable
              as Map<String, Timestamp>,
      settings: null == settings
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      roles: null == roles
          ? _value.roles
          : roles // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
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
      profileImageUrl: freezed == profileImageUrl
          ? _value.profileImageUrl
          : profileImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
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
      logoUrl: freezed == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      hubRules: freezed == hubRules
          ? _value.hubRules
          : hubRules // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
      isPrivate: null == isPrivate
          ? _value.isPrivate
          : isPrivate // ignore: cast_nullable_to_non_nullable
              as bool,
      managerRatings: null == managerRatings
          ? _value.managerRatings
          : managerRatings // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
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
    ) as $Val);
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
      List<String> memberIds,
      @TimestampMapConverter() Map<String, Timestamp> memberJoinDates,
      Map<String, dynamic> settings,
      Map<String, String> roles,
      Map<String, dynamic> permissions,
      @NullableGeoPointConverter() GeoPoint? location,
      String? geohash,
      double? radius,
      List<String> venueIds,
      String? profileImageUrl,
      String? mainVenueId,
      String? primaryVenueId,
      @NullableGeoPointConverter() GeoPoint? primaryVenueLocation,
      String? logoUrl,
      String? hubRules,
      String? region,
      bool isPrivate,
      Map<String, double> managerRatings,
      String? paymentLink,
      int? gameCount,
      @TimestampConverter() DateTime? lastActivity});
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
    Object? memberIds = null,
    Object? memberJoinDates = null,
    Object? settings = null,
    Object? roles = null,
    Object? permissions = null,
    Object? location = freezed,
    Object? geohash = freezed,
    Object? radius = freezed,
    Object? venueIds = null,
    Object? profileImageUrl = freezed,
    Object? mainVenueId = freezed,
    Object? primaryVenueId = freezed,
    Object? primaryVenueLocation = freezed,
    Object? logoUrl = freezed,
    Object? hubRules = freezed,
    Object? region = freezed,
    Object? isPrivate = null,
    Object? managerRatings = null,
    Object? paymentLink = freezed,
    Object? gameCount = freezed,
    Object? lastActivity = freezed,
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
      memberIds: null == memberIds
          ? _value._memberIds
          : memberIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      memberJoinDates: null == memberJoinDates
          ? _value._memberJoinDates
          : memberJoinDates // ignore: cast_nullable_to_non_nullable
              as Map<String, Timestamp>,
      settings: null == settings
          ? _value._settings
          : settings // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      roles: null == roles
          ? _value._roles
          : roles // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
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
      profileImageUrl: freezed == profileImageUrl
          ? _value.profileImageUrl
          : profileImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
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
      logoUrl: freezed == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      hubRules: freezed == hubRules
          ? _value.hubRules
          : hubRules // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
      isPrivate: null == isPrivate
          ? _value.isPrivate
          : isPrivate // ignore: cast_nullable_to_non_nullable
              as bool,
      managerRatings: null == managerRatings
          ? _value._managerRatings
          : managerRatings // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
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
      final List<String> memberIds = const [],
      @TimestampMapConverter()
      final Map<String, Timestamp> memberJoinDates = const {},
      final Map<String, dynamic> settings = const {'ratingMode': 'basic'},
      final Map<String, String> roles = const {},
      final Map<String, dynamic> permissions = const {},
      @NullableGeoPointConverter() this.location,
      this.geohash,
      this.radius,
      final List<String> venueIds = const [],
      this.profileImageUrl,
      this.mainVenueId,
      this.primaryVenueId,
      @NullableGeoPointConverter() this.primaryVenueLocation,
      this.logoUrl,
      this.hubRules,
      this.region,
      this.isPrivate = false,
      final Map<String, double> managerRatings = const {},
      this.paymentLink,
      this.gameCount,
      @TimestampConverter() this.lastActivity})
      : _memberIds = memberIds,
        _memberJoinDates = memberJoinDates,
        _settings = settings,
        _roles = roles,
        _permissions = permissions,
        _venueIds = venueIds,
        _managerRatings = managerRatings;

  factory _$HubImpl.fromJson(Map<String, dynamic> json) =>
      _$$HubImplFromJson(json);

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
  final List<String> _memberIds;
  @override
  @JsonKey()
  List<String> get memberIds {
    if (_memberIds is EqualUnmodifiableListView) return _memberIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_memberIds);
  }

  final Map<String, Timestamp> _memberJoinDates;
  @override
  @JsonKey()
  @TimestampMapConverter()
  Map<String, Timestamp> get memberJoinDates {
    if (_memberJoinDates is EqualUnmodifiableMapView) return _memberJoinDates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_memberJoinDates);
  }

// userId -> join date timestamp
  final Map<String, dynamic> _settings;
// userId -> join date timestamp
  @override
  @JsonKey()
  Map<String, dynamic> get settings {
    if (_settings is EqualUnmodifiableMapView) return _settings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_settings);
  }

  final Map<String, String> _roles;
  @override
  @JsonKey()
  Map<String, String> get roles {
    if (_roles is EqualUnmodifiableMapView) return _roles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_roles);
  }

// userId -> role (manager, moderator, member)
  final Map<String, dynamic> _permissions;
// userId -> role (manager, moderator, member)
  @override
  @JsonKey()
  Map<String, dynamic> get permissions {
    if (_permissions is EqualUnmodifiableMapView) return _permissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_permissions);
  }

// Custom permissions: {canCreateEvents: [userId1, userId2], canCreatePosts: [userId1, userId2]}
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
  final String? profileImageUrl;
// Profile picture chosen by hub manager
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
  @override
  final String? logoUrl;
// Hub logo URL (used for feed posts)
  @override
  final String? hubRules;
// Rules and guidelines for the hub
  @override
  final String? region;
// אזור: צפון, מרכז, דרום, ירושלים
// Privacy settings
  @override
  @JsonKey()
  final bool isPrivate;
// If true, requires "Request to Join" (create notification for manager)
// Manager-only ratings for team balancing (1-10 scale)
  final Map<String, double> _managerRatings;
// If true, requires "Request to Join" (create notification for manager)
// Manager-only ratings for team balancing (1-10 scale)
  @override
  @JsonKey()
  Map<String, double> get managerRatings {
    if (_managerRatings is EqualUnmodifiableMapView) return _managerRatings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_managerRatings);
  }

// userId -> rating (1-10, manager-only, for team balancing)
// Payment settings
  @override
  final String? paymentLink;
// PayBox/Bit payment link URL
// Denormalized fields (updated by Cloud Functions, not written by client)
  @override
  final int? gameCount;
// Denormalized: Total games created (updated by onGameCreated)
  @override
  @TimestampConverter()
  final DateTime? lastActivity;

  @override
  String toString() {
    return 'Hub(hubId: $hubId, name: $name, description: $description, createdBy: $createdBy, createdAt: $createdAt, memberIds: $memberIds, memberJoinDates: $memberJoinDates, settings: $settings, roles: $roles, permissions: $permissions, location: $location, geohash: $geohash, radius: $radius, venueIds: $venueIds, profileImageUrl: $profileImageUrl, mainVenueId: $mainVenueId, primaryVenueId: $primaryVenueId, primaryVenueLocation: $primaryVenueLocation, logoUrl: $logoUrl, hubRules: $hubRules, region: $region, isPrivate: $isPrivate, managerRatings: $managerRatings, paymentLink: $paymentLink, gameCount: $gameCount, lastActivity: $lastActivity)';
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
            const DeepCollectionEquality()
                .equals(other._memberIds, _memberIds) &&
            const DeepCollectionEquality()
                .equals(other._memberJoinDates, _memberJoinDates) &&
            const DeepCollectionEquality().equals(other._settings, _settings) &&
            const DeepCollectionEquality().equals(other._roles, _roles) &&
            const DeepCollectionEquality()
                .equals(other._permissions, _permissions) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.geohash, geohash) || other.geohash == geohash) &&
            (identical(other.radius, radius) || other.radius == radius) &&
            const DeepCollectionEquality().equals(other._venueIds, _venueIds) &&
            (identical(other.profileImageUrl, profileImageUrl) ||
                other.profileImageUrl == profileImageUrl) &&
            (identical(other.mainVenueId, mainVenueId) ||
                other.mainVenueId == mainVenueId) &&
            (identical(other.primaryVenueId, primaryVenueId) ||
                other.primaryVenueId == primaryVenueId) &&
            (identical(other.primaryVenueLocation, primaryVenueLocation) ||
                other.primaryVenueLocation == primaryVenueLocation) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.hubRules, hubRules) ||
                other.hubRules == hubRules) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.isPrivate, isPrivate) ||
                other.isPrivate == isPrivate) &&
            const DeepCollectionEquality()
                .equals(other._managerRatings, _managerRatings) &&
            (identical(other.paymentLink, paymentLink) ||
                other.paymentLink == paymentLink) &&
            (identical(other.gameCount, gameCount) ||
                other.gameCount == gameCount) &&
            (identical(other.lastActivity, lastActivity) ||
                other.lastActivity == lastActivity));
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
        const DeepCollectionEquality().hash(_memberIds),
        const DeepCollectionEquality().hash(_memberJoinDates),
        const DeepCollectionEquality().hash(_settings),
        const DeepCollectionEquality().hash(_roles),
        const DeepCollectionEquality().hash(_permissions),
        location,
        geohash,
        radius,
        const DeepCollectionEquality().hash(_venueIds),
        profileImageUrl,
        mainVenueId,
        primaryVenueId,
        primaryVenueLocation,
        logoUrl,
        hubRules,
        region,
        isPrivate,
        const DeepCollectionEquality().hash(_managerRatings),
        paymentLink,
        gameCount,
        lastActivity
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
      final List<String> memberIds,
      @TimestampMapConverter() final Map<String, Timestamp> memberJoinDates,
      final Map<String, dynamic> settings,
      final Map<String, String> roles,
      final Map<String, dynamic> permissions,
      @NullableGeoPointConverter() final GeoPoint? location,
      final String? geohash,
      final double? radius,
      final List<String> venueIds,
      final String? profileImageUrl,
      final String? mainVenueId,
      final String? primaryVenueId,
      @NullableGeoPointConverter() final GeoPoint? primaryVenueLocation,
      final String? logoUrl,
      final String? hubRules,
      final String? region,
      final bool isPrivate,
      final Map<String, double> managerRatings,
      final String? paymentLink,
      final int? gameCount,
      @TimestampConverter() final DateTime? lastActivity}) = _$HubImpl;

  factory _Hub.fromJson(Map<String, dynamic> json) = _$HubImpl.fromJson;

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
  DateTime get createdAt;
  @override
  List<String> get memberIds;
  @override
  @TimestampMapConverter()
  Map<String, Timestamp> get memberJoinDates; // userId -> join date timestamp
  @override
  Map<String, dynamic> get settings;
  @override
  Map<String, String> get roles; // userId -> role (manager, moderator, member)
  @override
  Map<String, dynamic>
      get permissions; // Custom permissions: {canCreateEvents: [userId1, userId2], canCreatePosts: [userId1, userId2]}
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
  String? get profileImageUrl; // Profile picture chosen by hub manager
  @override
  String? get mainVenueId; // ID of the main venue (home field) - required
  @override
  String?
      get primaryVenueId; // ID of the primary venue (for map display) - denormalized
  @override
  @NullableGeoPointConverter()
  GeoPoint?
      get primaryVenueLocation; // Location of primary venue - denormalized
  @override
  String? get logoUrl; // Hub logo URL (used for feed posts)
  @override
  String? get hubRules; // Rules and guidelines for the hub
  @override
  String? get region; // אזור: צפון, מרכז, דרום, ירושלים
// Privacy settings
  @override
  bool
      get isPrivate; // If true, requires "Request to Join" (create notification for manager)
// Manager-only ratings for team balancing (1-10 scale)
  @override
  Map<String, double>
      get managerRatings; // userId -> rating (1-10, manager-only, for team balancing)
// Payment settings
  @override
  String? get paymentLink; // PayBox/Bit payment link URL
// Denormalized fields (updated by Cloud Functions, not written by client)
  @override
  int?
      get gameCount; // Denormalized: Total games created (updated by onGameCreated)
  @override
  @TimestampConverter()
  DateTime? get lastActivity;

  /// Create a copy of Hub
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HubImplCopyWith<_$HubImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
