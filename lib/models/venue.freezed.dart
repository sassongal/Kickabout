// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'venue.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Venue _$VenueFromJson(Map<String, dynamic> json) {
  return _Venue.fromJson(json);
}

/// @nodoc
mixin _$Venue {
  String get venueId => throw _privateConstructorUsedError;
  int get venueNumber =>
      throw _privateConstructorUsedError; // Unique sequential number for this venue (like hubId)
  String get hubId =>
      throw _privateConstructorUsedError; // Which hub this venue belongs to
  String get name =>
      throw _privateConstructorUsedError; // e.g., "גן דניאל - מגרש 1"
  String? get description => throw _privateConstructorUsedError;
  @GeoPointConverter()
  GeoPoint get location =>
      throw _privateConstructorUsedError; // Exact location from Google Maps
  String? get address =>
      throw _privateConstructorUsedError; // Human-readable address
  String? get city => throw _privateConstructorUsedError; // עיר בה נמצא המגרש
  String? get region =>
      throw _privateConstructorUsedError; // אזור (מחושב אוטומטית מהעיר)
  String? get googlePlaceId =>
      throw _privateConstructorUsedError; // Google Places API ID for real venues
  List<String> get amenities =>
      throw _privateConstructorUsedError; // e.g., ["parking", "showers", "lights"]
  String get surfaceType =>
      throw _privateConstructorUsedError; // grass, artificial, concrete
  int get maxPlayers =>
      throw _privateConstructorUsedError; // Max players per team (default 11v11)
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String? get createdBy =>
      throw _privateConstructorUsedError; // User who added this venue
  bool get isActive =>
      throw _privateConstructorUsedError; // Can be deactivated without deleting
  bool get isMain =>
      throw _privateConstructorUsedError; // Is this the main/home venue for the hub
  int get hubCount =>
      throw _privateConstructorUsedError; // Number of hubs using this venue
  bool get isPublic =>
      throw _privateConstructorUsedError; // Whether this is a public venue
  String get source => throw _privateConstructorUsedError; // 'manual' or 'osm'
  String? get externalId => throw _privateConstructorUsedError;

  /// Serializes this Venue to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Venue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VenueCopyWith<Venue> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VenueCopyWith<$Res> {
  factory $VenueCopyWith(Venue value, $Res Function(Venue) then) =
      _$VenueCopyWithImpl<$Res, Venue>;
  @useResult
  $Res call(
      {String venueId,
      int venueNumber,
      String hubId,
      String name,
      String? description,
      @GeoPointConverter() GeoPoint location,
      String? address,
      String? city,
      String? region,
      String? googlePlaceId,
      List<String> amenities,
      String surfaceType,
      int maxPlayers,
      @TimestampConverter() DateTime createdAt,
      @TimestampConverter() DateTime updatedAt,
      String? createdBy,
      bool isActive,
      bool isMain,
      int hubCount,
      bool isPublic,
      String source,
      String? externalId});
}

/// @nodoc
class _$VenueCopyWithImpl<$Res, $Val extends Venue>
    implements $VenueCopyWith<$Res> {
  _$VenueCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Venue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? venueId = null,
    Object? venueNumber = null,
    Object? hubId = null,
    Object? name = null,
    Object? description = freezed,
    Object? location = null,
    Object? address = freezed,
    Object? city = freezed,
    Object? region = freezed,
    Object? googlePlaceId = freezed,
    Object? amenities = null,
    Object? surfaceType = null,
    Object? maxPlayers = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? createdBy = freezed,
    Object? isActive = null,
    Object? isMain = null,
    Object? hubCount = null,
    Object? isPublic = null,
    Object? source = null,
    Object? externalId = freezed,
  }) {
    return _then(_value.copyWith(
      venueId: null == venueId
          ? _value.venueId
          : venueId // ignore: cast_nullable_to_non_nullable
              as String,
      venueNumber: null == venueNumber
          ? _value.venueNumber
          : venueNumber // ignore: cast_nullable_to_non_nullable
              as int,
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
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeoPoint,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
      googlePlaceId: freezed == googlePlaceId
          ? _value.googlePlaceId
          : googlePlaceId // ignore: cast_nullable_to_non_nullable
              as String?,
      amenities: null == amenities
          ? _value.amenities
          : amenities // ignore: cast_nullable_to_non_nullable
              as List<String>,
      surfaceType: null == surfaceType
          ? _value.surfaceType
          : surfaceType // ignore: cast_nullable_to_non_nullable
              as String,
      maxPlayers: null == maxPlayers
          ? _value.maxPlayers
          : maxPlayers // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      isMain: null == isMain
          ? _value.isMain
          : isMain // ignore: cast_nullable_to_non_nullable
              as bool,
      hubCount: null == hubCount
          ? _value.hubCount
          : hubCount // ignore: cast_nullable_to_non_nullable
              as int,
      isPublic: null == isPublic
          ? _value.isPublic
          : isPublic // ignore: cast_nullable_to_non_nullable
              as bool,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      externalId: freezed == externalId
          ? _value.externalId
          : externalId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VenueImplCopyWith<$Res> implements $VenueCopyWith<$Res> {
  factory _$$VenueImplCopyWith(
          _$VenueImpl value, $Res Function(_$VenueImpl) then) =
      __$$VenueImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String venueId,
      int venueNumber,
      String hubId,
      String name,
      String? description,
      @GeoPointConverter() GeoPoint location,
      String? address,
      String? city,
      String? region,
      String? googlePlaceId,
      List<String> amenities,
      String surfaceType,
      int maxPlayers,
      @TimestampConverter() DateTime createdAt,
      @TimestampConverter() DateTime updatedAt,
      String? createdBy,
      bool isActive,
      bool isMain,
      int hubCount,
      bool isPublic,
      String source,
      String? externalId});
}

/// @nodoc
class __$$VenueImplCopyWithImpl<$Res>
    extends _$VenueCopyWithImpl<$Res, _$VenueImpl>
    implements _$$VenueImplCopyWith<$Res> {
  __$$VenueImplCopyWithImpl(
      _$VenueImpl _value, $Res Function(_$VenueImpl) _then)
      : super(_value, _then);

  /// Create a copy of Venue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? venueId = null,
    Object? venueNumber = null,
    Object? hubId = null,
    Object? name = null,
    Object? description = freezed,
    Object? location = null,
    Object? address = freezed,
    Object? city = freezed,
    Object? region = freezed,
    Object? googlePlaceId = freezed,
    Object? amenities = null,
    Object? surfaceType = null,
    Object? maxPlayers = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? createdBy = freezed,
    Object? isActive = null,
    Object? isMain = null,
    Object? hubCount = null,
    Object? isPublic = null,
    Object? source = null,
    Object? externalId = freezed,
  }) {
    return _then(_$VenueImpl(
      venueId: null == venueId
          ? _value.venueId
          : venueId // ignore: cast_nullable_to_non_nullable
              as String,
      venueNumber: null == venueNumber
          ? _value.venueNumber
          : venueNumber // ignore: cast_nullable_to_non_nullable
              as int,
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
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeoPoint,
      address: freezed == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
      googlePlaceId: freezed == googlePlaceId
          ? _value.googlePlaceId
          : googlePlaceId // ignore: cast_nullable_to_non_nullable
              as String?,
      amenities: null == amenities
          ? _value._amenities
          : amenities // ignore: cast_nullable_to_non_nullable
              as List<String>,
      surfaceType: null == surfaceType
          ? _value.surfaceType
          : surfaceType // ignore: cast_nullable_to_non_nullable
              as String,
      maxPlayers: null == maxPlayers
          ? _value.maxPlayers
          : maxPlayers // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      isMain: null == isMain
          ? _value.isMain
          : isMain // ignore: cast_nullable_to_non_nullable
              as bool,
      hubCount: null == hubCount
          ? _value.hubCount
          : hubCount // ignore: cast_nullable_to_non_nullable
              as int,
      isPublic: null == isPublic
          ? _value.isPublic
          : isPublic // ignore: cast_nullable_to_non_nullable
              as bool,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      externalId: freezed == externalId
          ? _value.externalId
          : externalId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VenueImpl implements _Venue {
  const _$VenueImpl(
      {required this.venueId,
      this.venueNumber = 0,
      required this.hubId,
      required this.name,
      this.description,
      @GeoPointConverter() required this.location,
      this.address,
      this.city,
      this.region,
      this.googlePlaceId,
      final List<String> amenities = const [],
      this.surfaceType = 'grass',
      this.maxPlayers = 11,
      @TimestampConverter() required this.createdAt,
      @TimestampConverter() required this.updatedAt,
      this.createdBy,
      this.isActive = true,
      this.isMain = false,
      this.hubCount = 0,
      this.isPublic = true,
      this.source = 'manual',
      this.externalId})
      : _amenities = amenities;

  factory _$VenueImpl.fromJson(Map<String, dynamic> json) =>
      _$$VenueImplFromJson(json);

  @override
  final String venueId;
  @override
  @JsonKey()
  final int venueNumber;
// Unique sequential number for this venue (like hubId)
  @override
  final String hubId;
// Which hub this venue belongs to
  @override
  final String name;
// e.g., "גן דניאל - מגרש 1"
  @override
  final String? description;
  @override
  @GeoPointConverter()
  final GeoPoint location;
// Exact location from Google Maps
  @override
  final String? address;
// Human-readable address
  @override
  final String? city;
// עיר בה נמצא המגרש
  @override
  final String? region;
// אזור (מחושב אוטומטית מהעיר)
  @override
  final String? googlePlaceId;
// Google Places API ID for real venues
  final List<String> _amenities;
// Google Places API ID for real venues
  @override
  @JsonKey()
  List<String> get amenities {
    if (_amenities is EqualUnmodifiableListView) return _amenities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_amenities);
  }

// e.g., ["parking", "showers", "lights"]
  @override
  @JsonKey()
  final String surfaceType;
// grass, artificial, concrete
  @override
  @JsonKey()
  final int maxPlayers;
// Max players per team (default 11v11)
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @TimestampConverter()
  final DateTime updatedAt;
  @override
  final String? createdBy;
// User who added this venue
  @override
  @JsonKey()
  final bool isActive;
// Can be deactivated without deleting
  @override
  @JsonKey()
  final bool isMain;
// Is this the main/home venue for the hub
  @override
  @JsonKey()
  final int hubCount;
// Number of hubs using this venue
  @override
  @JsonKey()
  final bool isPublic;
// Whether this is a public venue
  @override
  @JsonKey()
  final String source;
// 'manual' or 'osm'
  @override
  final String? externalId;

  @override
  String toString() {
    return 'Venue(venueId: $venueId, venueNumber: $venueNumber, hubId: $hubId, name: $name, description: $description, location: $location, address: $address, city: $city, region: $region, googlePlaceId: $googlePlaceId, amenities: $amenities, surfaceType: $surfaceType, maxPlayers: $maxPlayers, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, isActive: $isActive, isMain: $isMain, hubCount: $hubCount, isPublic: $isPublic, source: $source, externalId: $externalId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VenueImpl &&
            (identical(other.venueId, venueId) || other.venueId == venueId) &&
            (identical(other.venueNumber, venueNumber) ||
                other.venueNumber == venueNumber) &&
            (identical(other.hubId, hubId) || other.hubId == hubId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.googlePlaceId, googlePlaceId) ||
                other.googlePlaceId == googlePlaceId) &&
            const DeepCollectionEquality()
                .equals(other._amenities, _amenities) &&
            (identical(other.surfaceType, surfaceType) ||
                other.surfaceType == surfaceType) &&
            (identical(other.maxPlayers, maxPlayers) ||
                other.maxPlayers == maxPlayers) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.isMain, isMain) || other.isMain == isMain) &&
            (identical(other.hubCount, hubCount) ||
                other.hubCount == hubCount) &&
            (identical(other.isPublic, isPublic) ||
                other.isPublic == isPublic) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.externalId, externalId) ||
                other.externalId == externalId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        venueId,
        venueNumber,
        hubId,
        name,
        description,
        location,
        address,
        city,
        region,
        googlePlaceId,
        const DeepCollectionEquality().hash(_amenities),
        surfaceType,
        maxPlayers,
        createdAt,
        updatedAt,
        createdBy,
        isActive,
        isMain,
        hubCount,
        isPublic,
        source,
        externalId
      ]);

  /// Create a copy of Venue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VenueImplCopyWith<_$VenueImpl> get copyWith =>
      __$$VenueImplCopyWithImpl<_$VenueImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VenueImplToJson(
      this,
    );
  }
}

abstract class _Venue implements Venue {
  const factory _Venue(
      {required final String venueId,
      final int venueNumber,
      required final String hubId,
      required final String name,
      final String? description,
      @GeoPointConverter() required final GeoPoint location,
      final String? address,
      final String? city,
      final String? region,
      final String? googlePlaceId,
      final List<String> amenities,
      final String surfaceType,
      final int maxPlayers,
      @TimestampConverter() required final DateTime createdAt,
      @TimestampConverter() required final DateTime updatedAt,
      final String? createdBy,
      final bool isActive,
      final bool isMain,
      final int hubCount,
      final bool isPublic,
      final String source,
      final String? externalId}) = _$VenueImpl;

  factory _Venue.fromJson(Map<String, dynamic> json) = _$VenueImpl.fromJson;

  @override
  String get venueId;
  @override
  int get venueNumber; // Unique sequential number for this venue (like hubId)
  @override
  String get hubId; // Which hub this venue belongs to
  @override
  String get name; // e.g., "גן דניאל - מגרש 1"
  @override
  String? get description;
  @override
  @GeoPointConverter()
  GeoPoint get location; // Exact location from Google Maps
  @override
  String? get address; // Human-readable address
  @override
  String? get city; // עיר בה נמצא המגרש
  @override
  String? get region; // אזור (מחושב אוטומטית מהעיר)
  @override
  String? get googlePlaceId; // Google Places API ID for real venues
  @override
  List<String> get amenities; // e.g., ["parking", "showers", "lights"]
  @override
  String get surfaceType; // grass, artificial, concrete
  @override
  int get maxPlayers; // Max players per team (default 11v11)
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @TimestampConverter()
  DateTime get updatedAt;
  @override
  String? get createdBy; // User who added this venue
  @override
  bool get isActive; // Can be deactivated without deleting
  @override
  bool get isMain; // Is this the main/home venue for the hub
  @override
  int get hubCount; // Number of hubs using this venue
  @override
  bool get isPublic; // Whether this is a public venue
  @override
  String get source; // 'manual' or 'osm'
  @override
  String? get externalId;

  /// Create a copy of Venue
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VenueImplCopyWith<_$VenueImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
