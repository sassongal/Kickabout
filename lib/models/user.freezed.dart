// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

User _$UserFromJson(Map<String, dynamic> json) {
  return _User.fromJson(json);
}

/// @nodoc
mixin _$User {
  String get uid => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  String? get avatarColor =>
      throw _privateConstructorUsedError; // Hex color for avatar background (e.g., "#FF5733")
  String? get phoneNumber => throw _privateConstructorUsedError;
  String? get city => throw _privateConstructorUsedError; // עיר מגורים
// New profile fields
  String? get firstName => throw _privateConstructorUsedError;
  String? get lastName => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get birthDate => throw _privateConstructorUsedError;
  String? get favoriteTeamId =>
      throw _privateConstructorUsedError; // ID of favorite team from Firestore
  String? get facebookProfileUrl => throw _privateConstructorUsedError;
  String? get instagramProfileUrl => throw _privateConstructorUsedError;
  String get availabilityStatus =>
      throw _privateConstructorUsedError; // available, busy, notAvailable (deprecated, use isActive)
  bool get isActive =>
      throw _privateConstructorUsedError; // true = פתוח להאבים והזמנות, false = לא פתוח
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  List<String> get hubIds =>
      throw _privateConstructorUsedError; // DEPRECATED: currentRankScore - Use managerRatings in Hub model instead
// Keeping for backward compatibility, but should not be used for new features
  double get currentRankScore =>
      throw _privateConstructorUsedError; // DEPRECATED: Use Hub.managerRatings instead
  String get preferredPosition =>
      throw _privateConstructorUsedError; // Optional - for team balancing display
  String? get playingStyle =>
      throw _privateConstructorUsedError; // goalkeeper, defensive, offensive (optional - for team balancing)
  int get totalParticipations =>
      throw _privateConstructorUsedError; // Total games played (for milestone badges)
  @NullableGeoPointConverter()
  GeoPoint? get location => throw _privateConstructorUsedError;
  String? get geohash => throw _privateConstructorUsedError;
  String? get region =>
      throw _privateConstructorUsedError; // אזור: צפון, מרכז, דרום, ירושלים
// Denormalized fields (updated by Cloud Functions, not written by client)
  int get followerCount =>
      throw _privateConstructorUsedError; // Denormalized: Count of followers (updated by onFollowCreated)
// Privacy settings - control what data is visible in search and profile
  Map<String, bool> get privacySettings => throw _privateConstructorUsedError;

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserCopyWith<User> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCopyWith<$Res> {
  factory $UserCopyWith(User value, $Res Function(User) then) =
      _$UserCopyWithImpl<$Res, User>;
  @useResult
  $Res call(
      {String uid,
      String name,
      String email,
      String? photoUrl,
      String? avatarColor,
      String? phoneNumber,
      String? city,
      String? firstName,
      String? lastName,
      @TimestampConverter() DateTime? birthDate,
      String? favoriteTeamId,
      String? facebookProfileUrl,
      String? instagramProfileUrl,
      String availabilityStatus,
      bool isActive,
      @TimestampConverter() DateTime createdAt,
      List<String> hubIds,
      double currentRankScore,
      String preferredPosition,
      String? playingStyle,
      int totalParticipations,
      @NullableGeoPointConverter() GeoPoint? location,
      String? geohash,
      String? region,
      int followerCount,
      Map<String, bool> privacySettings});
}

/// @nodoc
class _$UserCopyWithImpl<$Res, $Val extends User>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? name = null,
    Object? email = null,
    Object? photoUrl = freezed,
    Object? avatarColor = freezed,
    Object? phoneNumber = freezed,
    Object? city = freezed,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? birthDate = freezed,
    Object? favoriteTeamId = freezed,
    Object? facebookProfileUrl = freezed,
    Object? instagramProfileUrl = freezed,
    Object? availabilityStatus = null,
    Object? isActive = null,
    Object? createdAt = null,
    Object? hubIds = null,
    Object? currentRankScore = null,
    Object? preferredPosition = null,
    Object? playingStyle = freezed,
    Object? totalParticipations = null,
    Object? location = freezed,
    Object? geohash = freezed,
    Object? region = freezed,
    Object? followerCount = null,
    Object? privacySettings = null,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarColor: freezed == avatarColor
          ? _value.avatarColor
          : avatarColor // ignore: cast_nullable_to_non_nullable
              as String?,
      phoneNumber: freezed == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      birthDate: freezed == birthDate
          ? _value.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      favoriteTeamId: freezed == favoriteTeamId
          ? _value.favoriteTeamId
          : favoriteTeamId // ignore: cast_nullable_to_non_nullable
              as String?,
      facebookProfileUrl: freezed == facebookProfileUrl
          ? _value.facebookProfileUrl
          : facebookProfileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      instagramProfileUrl: freezed == instagramProfileUrl
          ? _value.instagramProfileUrl
          : instagramProfileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      availabilityStatus: null == availabilityStatus
          ? _value.availabilityStatus
          : availabilityStatus // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      hubIds: null == hubIds
          ? _value.hubIds
          : hubIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentRankScore: null == currentRankScore
          ? _value.currentRankScore
          : currentRankScore // ignore: cast_nullable_to_non_nullable
              as double,
      preferredPosition: null == preferredPosition
          ? _value.preferredPosition
          : preferredPosition // ignore: cast_nullable_to_non_nullable
              as String,
      playingStyle: freezed == playingStyle
          ? _value.playingStyle
          : playingStyle // ignore: cast_nullable_to_non_nullable
              as String?,
      totalParticipations: null == totalParticipations
          ? _value.totalParticipations
          : totalParticipations // ignore: cast_nullable_to_non_nullable
              as int,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeoPoint?,
      geohash: freezed == geohash
          ? _value.geohash
          : geohash // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
      followerCount: null == followerCount
          ? _value.followerCount
          : followerCount // ignore: cast_nullable_to_non_nullable
              as int,
      privacySettings: null == privacySettings
          ? _value.privacySettings
          : privacySettings // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserImplCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$$UserImplCopyWith(
          _$UserImpl value, $Res Function(_$UserImpl) then) =
      __$$UserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String uid,
      String name,
      String email,
      String? photoUrl,
      String? avatarColor,
      String? phoneNumber,
      String? city,
      String? firstName,
      String? lastName,
      @TimestampConverter() DateTime? birthDate,
      String? favoriteTeamId,
      String? facebookProfileUrl,
      String? instagramProfileUrl,
      String availabilityStatus,
      bool isActive,
      @TimestampConverter() DateTime createdAt,
      List<String> hubIds,
      double currentRankScore,
      String preferredPosition,
      String? playingStyle,
      int totalParticipations,
      @NullableGeoPointConverter() GeoPoint? location,
      String? geohash,
      String? region,
      int followerCount,
      Map<String, bool> privacySettings});
}

/// @nodoc
class __$$UserImplCopyWithImpl<$Res>
    extends _$UserCopyWithImpl<$Res, _$UserImpl>
    implements _$$UserImplCopyWith<$Res> {
  __$$UserImplCopyWithImpl(_$UserImpl _value, $Res Function(_$UserImpl) _then)
      : super(_value, _then);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? name = null,
    Object? email = null,
    Object? photoUrl = freezed,
    Object? avatarColor = freezed,
    Object? phoneNumber = freezed,
    Object? city = freezed,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? birthDate = freezed,
    Object? favoriteTeamId = freezed,
    Object? facebookProfileUrl = freezed,
    Object? instagramProfileUrl = freezed,
    Object? availabilityStatus = null,
    Object? isActive = null,
    Object? createdAt = null,
    Object? hubIds = null,
    Object? currentRankScore = null,
    Object? preferredPosition = null,
    Object? playingStyle = freezed,
    Object? totalParticipations = null,
    Object? location = freezed,
    Object? geohash = freezed,
    Object? region = freezed,
    Object? followerCount = null,
    Object? privacySettings = null,
  }) {
    return _then(_$UserImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarColor: freezed == avatarColor
          ? _value.avatarColor
          : avatarColor // ignore: cast_nullable_to_non_nullable
              as String?,
      phoneNumber: freezed == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      city: freezed == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String?,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      birthDate: freezed == birthDate
          ? _value.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      favoriteTeamId: freezed == favoriteTeamId
          ? _value.favoriteTeamId
          : favoriteTeamId // ignore: cast_nullable_to_non_nullable
              as String?,
      facebookProfileUrl: freezed == facebookProfileUrl
          ? _value.facebookProfileUrl
          : facebookProfileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      instagramProfileUrl: freezed == instagramProfileUrl
          ? _value.instagramProfileUrl
          : instagramProfileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      availabilityStatus: null == availabilityStatus
          ? _value.availabilityStatus
          : availabilityStatus // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      hubIds: null == hubIds
          ? _value._hubIds
          : hubIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentRankScore: null == currentRankScore
          ? _value.currentRankScore
          : currentRankScore // ignore: cast_nullable_to_non_nullable
              as double,
      preferredPosition: null == preferredPosition
          ? _value.preferredPosition
          : preferredPosition // ignore: cast_nullable_to_non_nullable
              as String,
      playingStyle: freezed == playingStyle
          ? _value.playingStyle
          : playingStyle // ignore: cast_nullable_to_non_nullable
              as String?,
      totalParticipations: null == totalParticipations
          ? _value.totalParticipations
          : totalParticipations // ignore: cast_nullable_to_non_nullable
              as int,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeoPoint?,
      geohash: freezed == geohash
          ? _value.geohash
          : geohash // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
      followerCount: null == followerCount
          ? _value.followerCount
          : followerCount // ignore: cast_nullable_to_non_nullable
              as int,
      privacySettings: null == privacySettings
          ? _value._privacySettings
          : privacySettings // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserImpl implements _User {
  const _$UserImpl(
      {required this.uid,
      required this.name,
      required this.email,
      this.photoUrl,
      this.avatarColor,
      this.phoneNumber,
      this.city,
      this.firstName,
      this.lastName,
      @TimestampConverter() this.birthDate,
      this.favoriteTeamId,
      this.facebookProfileUrl,
      this.instagramProfileUrl,
      this.availabilityStatus = 'available',
      this.isActive = true,
      @TimestampConverter() required this.createdAt,
      final List<String> hubIds = const [],
      this.currentRankScore = 5.0,
      this.preferredPosition = 'Midfielder',
      this.playingStyle,
      this.totalParticipations = 0,
      @NullableGeoPointConverter() this.location,
      this.geohash,
      this.region,
      this.followerCount = 0,
      final Map<String, bool> privacySettings = const {
        'hideFromSearch': false,
        'hideEmail': false,
        'hidePhone': false,
        'hideCity': false,
        'hideStats': false,
        'hideRatings': false
      }})
      : _hubIds = hubIds,
        _privacySettings = privacySettings;

  factory _$UserImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserImplFromJson(json);

  @override
  final String uid;
  @override
  final String name;
  @override
  final String email;
  @override
  final String? photoUrl;
  @override
  final String? avatarColor;
// Hex color for avatar background (e.g., "#FF5733")
  @override
  final String? phoneNumber;
  @override
  final String? city;
// עיר מגורים
// New profile fields
  @override
  final String? firstName;
  @override
  final String? lastName;
  @override
  @TimestampConverter()
  final DateTime? birthDate;
  @override
  final String? favoriteTeamId;
// ID of favorite team from Firestore
  @override
  final String? facebookProfileUrl;
  @override
  final String? instagramProfileUrl;
  @override
  @JsonKey()
  final String availabilityStatus;
// available, busy, notAvailable (deprecated, use isActive)
  @override
  @JsonKey()
  final bool isActive;
// true = פתוח להאבים והזמנות, false = לא פתוח
  @override
  @TimestampConverter()
  final DateTime createdAt;
  final List<String> _hubIds;
  @override
  @JsonKey()
  List<String> get hubIds {
    if (_hubIds is EqualUnmodifiableListView) return _hubIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hubIds);
  }

// DEPRECATED: currentRankScore - Use managerRatings in Hub model instead
// Keeping for backward compatibility, but should not be used for new features
  @override
  @JsonKey()
  final double currentRankScore;
// DEPRECATED: Use Hub.managerRatings instead
  @override
  @JsonKey()
  final String preferredPosition;
// Optional - for team balancing display
  @override
  final String? playingStyle;
// goalkeeper, defensive, offensive (optional - for team balancing)
  @override
  @JsonKey()
  final int totalParticipations;
// Total games played (for milestone badges)
  @override
  @NullableGeoPointConverter()
  final GeoPoint? location;
  @override
  final String? geohash;
  @override
  final String? region;
// אזור: צפון, מרכז, דרום, ירושלים
// Denormalized fields (updated by Cloud Functions, not written by client)
  @override
  @JsonKey()
  final int followerCount;
// Denormalized: Count of followers (updated by onFollowCreated)
// Privacy settings - control what data is visible in search and profile
  final Map<String, bool> _privacySettings;
// Denormalized: Count of followers (updated by onFollowCreated)
// Privacy settings - control what data is visible in search and profile
  @override
  @JsonKey()
  Map<String, bool> get privacySettings {
    if (_privacySettings is EqualUnmodifiableMapView) return _privacySettings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_privacySettings);
  }

  @override
  String toString() {
    return 'User(uid: $uid, name: $name, email: $email, photoUrl: $photoUrl, avatarColor: $avatarColor, phoneNumber: $phoneNumber, city: $city, firstName: $firstName, lastName: $lastName, birthDate: $birthDate, favoriteTeamId: $favoriteTeamId, facebookProfileUrl: $facebookProfileUrl, instagramProfileUrl: $instagramProfileUrl, availabilityStatus: $availabilityStatus, isActive: $isActive, createdAt: $createdAt, hubIds: $hubIds, currentRankScore: $currentRankScore, preferredPosition: $preferredPosition, playingStyle: $playingStyle, totalParticipations: $totalParticipations, location: $location, geohash: $geohash, region: $region, followerCount: $followerCount, privacySettings: $privacySettings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.avatarColor, avatarColor) ||
                other.avatarColor == avatarColor) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.birthDate, birthDate) ||
                other.birthDate == birthDate) &&
            (identical(other.favoriteTeamId, favoriteTeamId) ||
                other.favoriteTeamId == favoriteTeamId) &&
            (identical(other.facebookProfileUrl, facebookProfileUrl) ||
                other.facebookProfileUrl == facebookProfileUrl) &&
            (identical(other.instagramProfileUrl, instagramProfileUrl) ||
                other.instagramProfileUrl == instagramProfileUrl) &&
            (identical(other.availabilityStatus, availabilityStatus) ||
                other.availabilityStatus == availabilityStatus) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(other._hubIds, _hubIds) &&
            (identical(other.currentRankScore, currentRankScore) ||
                other.currentRankScore == currentRankScore) &&
            (identical(other.preferredPosition, preferredPosition) ||
                other.preferredPosition == preferredPosition) &&
            (identical(other.playingStyle, playingStyle) ||
                other.playingStyle == playingStyle) &&
            (identical(other.totalParticipations, totalParticipations) ||
                other.totalParticipations == totalParticipations) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.geohash, geohash) || other.geohash == geohash) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.followerCount, followerCount) ||
                other.followerCount == followerCount) &&
            const DeepCollectionEquality()
                .equals(other._privacySettings, _privacySettings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        uid,
        name,
        email,
        photoUrl,
        avatarColor,
        phoneNumber,
        city,
        firstName,
        lastName,
        birthDate,
        favoriteTeamId,
        facebookProfileUrl,
        instagramProfileUrl,
        availabilityStatus,
        isActive,
        createdAt,
        const DeepCollectionEquality().hash(_hubIds),
        currentRankScore,
        preferredPosition,
        playingStyle,
        totalParticipations,
        location,
        geohash,
        region,
        followerCount,
        const DeepCollectionEquality().hash(_privacySettings)
      ]);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      __$$UserImplCopyWithImpl<_$UserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserImplToJson(
      this,
    );
  }
}

abstract class _User implements User {
  const factory _User(
      {required final String uid,
      required final String name,
      required final String email,
      final String? photoUrl,
      final String? avatarColor,
      final String? phoneNumber,
      final String? city,
      final String? firstName,
      final String? lastName,
      @TimestampConverter() final DateTime? birthDate,
      final String? favoriteTeamId,
      final String? facebookProfileUrl,
      final String? instagramProfileUrl,
      final String availabilityStatus,
      final bool isActive,
      @TimestampConverter() required final DateTime createdAt,
      final List<String> hubIds,
      final double currentRankScore,
      final String preferredPosition,
      final String? playingStyle,
      final int totalParticipations,
      @NullableGeoPointConverter() final GeoPoint? location,
      final String? geohash,
      final String? region,
      final int followerCount,
      final Map<String, bool> privacySettings}) = _$UserImpl;

  factory _User.fromJson(Map<String, dynamic> json) = _$UserImpl.fromJson;

  @override
  String get uid;
  @override
  String get name;
  @override
  String get email;
  @override
  String? get photoUrl;
  @override
  String? get avatarColor; // Hex color for avatar background (e.g., "#FF5733")
  @override
  String? get phoneNumber;
  @override
  String? get city; // עיר מגורים
// New profile fields
  @override
  String? get firstName;
  @override
  String? get lastName;
  @override
  @TimestampConverter()
  DateTime? get birthDate;
  @override
  String? get favoriteTeamId; // ID of favorite team from Firestore
  @override
  String? get facebookProfileUrl;
  @override
  String? get instagramProfileUrl;
  @override
  String
      get availabilityStatus; // available, busy, notAvailable (deprecated, use isActive)
  @override
  bool get isActive; // true = פתוח להאבים והזמנות, false = לא פתוח
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  List<String>
      get hubIds; // DEPRECATED: currentRankScore - Use managerRatings in Hub model instead
// Keeping for backward compatibility, but should not be used for new features
  @override
  double get currentRankScore; // DEPRECATED: Use Hub.managerRatings instead
  @override
  String get preferredPosition; // Optional - for team balancing display
  @override
  String?
      get playingStyle; // goalkeeper, defensive, offensive (optional - for team balancing)
  @override
  int get totalParticipations; // Total games played (for milestone badges)
  @override
  @NullableGeoPointConverter()
  GeoPoint? get location;
  @override
  String? get geohash;
  @override
  String? get region; // אזור: צפון, מרכז, דרום, ירושלים
// Denormalized fields (updated by Cloud Functions, not written by client)
  @override
  int get followerCount; // Denormalized: Count of followers (updated by onFollowCreated)
// Privacy settings - control what data is visible in search and profile
  @override
  Map<String, bool> get privacySettings;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
