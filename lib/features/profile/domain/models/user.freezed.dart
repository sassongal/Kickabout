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
  String? get displayName =>
      throw _privateConstructorUsedError; // Custom nickname (shown to others) - independent from firstName/lastName
  String? get firstName => throw _privateConstructorUsedError;
  String? get lastName => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get birthDate =>
      throw _privateConstructorUsedError; // ✅ Required field
  String? get favoriteTeamId =>
      throw _privateConstructorUsedError; // DEPRECATED: Old field, use favoriteProTeamId instead
  String? get favoriteProTeamId =>
      throw _privateConstructorUsedError; // ID of favorite professional team (Israeli Premier/National League)
  String? get facebookProfileUrl => throw _privateConstructorUsedError;
  String? get instagramProfileUrl => throw _privateConstructorUsedError;
  bool get showSocialLinks =>
      throw _privateConstructorUsedError; // Control visibility of social links to other users
  String get availabilityStatus =>
      throw _privateConstructorUsedError; // available, busy, notAvailable (deprecated, use isActive)
  bool get isActive =>
      throw _privateConstructorUsedError; // true = פתוח להאבים והזמנות, false = לא פתוח
  bool get isFictitious =>
      throw _privateConstructorUsedError; // Marks manual players created by managers
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  List<String> get hubIds =>
      throw _privateConstructorUsedError; // DEPRECATED: currentRankScore - Use managerRatings in Hub model instead
// Keeping for backward compatibility, but should not be used for new features
  double get currentRankScore =>
      throw _privateConstructorUsedError; // DEPRECATED: Use Hub.managerRatings instead
  String get preferredPosition =>
      throw _privateConstructorUsedError; // 'Goalkeeper', 'Defender', 'Midfielder', 'Attacker'
// REMOVED: playingStyle - merged into preferredPosition
// Physical data (optional, metric units)
  double? get heightCm =>
      throw _privateConstructorUsedError; // גובה בסנטימטרים (140-220)
  double? get weightKg =>
      throw _privateConstructorUsedError; // משקל בקילוגרמים (40-150)
  int get totalParticipations =>
      throw _privateConstructorUsedError; // Total games played (for milestone badges)
  int get gamesPlayed =>
      throw _privateConstructorUsedError; // Compatibility field used throughout the app
// DEPRECATED: Old location fields - use userLocation instead
// Kept for backward compatibility during migration
  @NullableGeographicPointFirestoreConverter()
  GeographicPoint? get location => throw _privateConstructorUsedError;
  String? get geohash => throw _privateConstructorUsedError;
  String? get region =>
      throw _privateConstructorUsedError; // אזור: צפון, מרכז, דרום, ירושלים
// NEW: Location value object (Phase 4 - dual-write pattern)
  UserLocation? get userLocation => throw _privateConstructorUsedError;
  bool get isProfileComplete =>
      throw _privateConstructorUsedError; // Denormalized fields (updated by Cloud Functions, not written by client)
  int get followerCount =>
      throw _privateConstructorUsedError; // Denormalized: Count of followers (updated by onFollowCreated)
// Player Stats (denormalized from game participations)
  int get wins => throw _privateConstructorUsedError;
  int get losses => throw _privateConstructorUsedError;
  int get draws => throw _privateConstructorUsedError;
  int get goals => throw _privateConstructorUsedError;
  int get assists =>
      throw _privateConstructorUsedError; // DEPRECATED: Old privacy settings map - use privacy instead
// Kept for backward compatibility during migration
  Map<String, bool> get privacySettings =>
      throw _privateConstructorUsedError; // NEW: Privacy value object (Phase 4 - dual-write pattern)
  PrivacySettings? get privacy =>
      throw _privateConstructorUsedError; // DEPRECATED: Old notification preferences map - use notifications instead
// Kept for backward compatibility during migration
  Map<String, bool> get notificationPreferences =>
      throw _privateConstructorUsedError; // NEW: Notification preferences value object (Phase 4 - dual-write pattern)
  NotificationPreferences? get notifications =>
      throw _privateConstructorUsedError; // Blocked users - users this user has blocked
  List<String> get blockedUserIds => throw _privateConstructorUsedError;

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
      String? displayName,
      String? firstName,
      String? lastName,
      @TimestampConverter() DateTime birthDate,
      String? favoriteTeamId,
      String? favoriteProTeamId,
      String? facebookProfileUrl,
      String? instagramProfileUrl,
      bool showSocialLinks,
      String availabilityStatus,
      bool isActive,
      bool isFictitious,
      @TimestampConverter() DateTime createdAt,
      List<String> hubIds,
      double currentRankScore,
      String preferredPosition,
      double? heightCm,
      double? weightKg,
      int totalParticipations,
      int gamesPlayed,
      @NullableGeographicPointFirestoreConverter() GeographicPoint? location,
      String? geohash,
      String? region,
      UserLocation? userLocation,
      bool isProfileComplete,
      int followerCount,
      int wins,
      int losses,
      int draws,
      int goals,
      int assists,
      Map<String, bool> privacySettings,
      PrivacySettings? privacy,
      Map<String, bool> notificationPreferences,
      NotificationPreferences? notifications,
      List<String> blockedUserIds});

  $GeographicPointCopyWith<$Res>? get location;
  $UserLocationCopyWith<$Res>? get userLocation;
  $PrivacySettingsCopyWith<$Res>? get privacy;
  $NotificationPreferencesCopyWith<$Res>? get notifications;
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
    Object? displayName = freezed,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? birthDate = null,
    Object? favoriteTeamId = freezed,
    Object? favoriteProTeamId = freezed,
    Object? facebookProfileUrl = freezed,
    Object? instagramProfileUrl = freezed,
    Object? showSocialLinks = null,
    Object? availabilityStatus = null,
    Object? isActive = null,
    Object? isFictitious = null,
    Object? createdAt = null,
    Object? hubIds = null,
    Object? currentRankScore = null,
    Object? preferredPosition = null,
    Object? heightCm = freezed,
    Object? weightKg = freezed,
    Object? totalParticipations = null,
    Object? gamesPlayed = null,
    Object? location = freezed,
    Object? geohash = freezed,
    Object? region = freezed,
    Object? userLocation = freezed,
    Object? isProfileComplete = null,
    Object? followerCount = null,
    Object? wins = null,
    Object? losses = null,
    Object? draws = null,
    Object? goals = null,
    Object? assists = null,
    Object? privacySettings = null,
    Object? privacy = freezed,
    Object? notificationPreferences = null,
    Object? notifications = freezed,
    Object? blockedUserIds = null,
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
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      birthDate: null == birthDate
          ? _value.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      favoriteTeamId: freezed == favoriteTeamId
          ? _value.favoriteTeamId
          : favoriteTeamId // ignore: cast_nullable_to_non_nullable
              as String?,
      favoriteProTeamId: freezed == favoriteProTeamId
          ? _value.favoriteProTeamId
          : favoriteProTeamId // ignore: cast_nullable_to_non_nullable
              as String?,
      facebookProfileUrl: freezed == facebookProfileUrl
          ? _value.facebookProfileUrl
          : facebookProfileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      instagramProfileUrl: freezed == instagramProfileUrl
          ? _value.instagramProfileUrl
          : instagramProfileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      showSocialLinks: null == showSocialLinks
          ? _value.showSocialLinks
          : showSocialLinks // ignore: cast_nullable_to_non_nullable
              as bool,
      availabilityStatus: null == availabilityStatus
          ? _value.availabilityStatus
          : availabilityStatus // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      isFictitious: null == isFictitious
          ? _value.isFictitious
          : isFictitious // ignore: cast_nullable_to_non_nullable
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
      heightCm: freezed == heightCm
          ? _value.heightCm
          : heightCm // ignore: cast_nullable_to_non_nullable
              as double?,
      weightKg: freezed == weightKg
          ? _value.weightKg
          : weightKg // ignore: cast_nullable_to_non_nullable
              as double?,
      totalParticipations: null == totalParticipations
          ? _value.totalParticipations
          : totalParticipations // ignore: cast_nullable_to_non_nullable
              as int,
      gamesPlayed: null == gamesPlayed
          ? _value.gamesPlayed
          : gamesPlayed // ignore: cast_nullable_to_non_nullable
              as int,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeographicPoint?,
      geohash: freezed == geohash
          ? _value.geohash
          : geohash // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
      userLocation: freezed == userLocation
          ? _value.userLocation
          : userLocation // ignore: cast_nullable_to_non_nullable
              as UserLocation?,
      isProfileComplete: null == isProfileComplete
          ? _value.isProfileComplete
          : isProfileComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      followerCount: null == followerCount
          ? _value.followerCount
          : followerCount // ignore: cast_nullable_to_non_nullable
              as int,
      wins: null == wins
          ? _value.wins
          : wins // ignore: cast_nullable_to_non_nullable
              as int,
      losses: null == losses
          ? _value.losses
          : losses // ignore: cast_nullable_to_non_nullable
              as int,
      draws: null == draws
          ? _value.draws
          : draws // ignore: cast_nullable_to_non_nullable
              as int,
      goals: null == goals
          ? _value.goals
          : goals // ignore: cast_nullable_to_non_nullable
              as int,
      assists: null == assists
          ? _value.assists
          : assists // ignore: cast_nullable_to_non_nullable
              as int,
      privacySettings: null == privacySettings
          ? _value.privacySettings
          : privacySettings // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>,
      privacy: freezed == privacy
          ? _value.privacy
          : privacy // ignore: cast_nullable_to_non_nullable
              as PrivacySettings?,
      notificationPreferences: null == notificationPreferences
          ? _value.notificationPreferences
          : notificationPreferences // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>,
      notifications: freezed == notifications
          ? _value.notifications
          : notifications // ignore: cast_nullable_to_non_nullable
              as NotificationPreferences?,
      blockedUserIds: null == blockedUserIds
          ? _value.blockedUserIds
          : blockedUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GeographicPointCopyWith<$Res>? get location {
    if (_value.location == null) {
      return null;
    }

    return $GeographicPointCopyWith<$Res>(_value.location!, (value) {
      return _then(_value.copyWith(location: value) as $Val);
    });
  }

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserLocationCopyWith<$Res>? get userLocation {
    if (_value.userLocation == null) {
      return null;
    }

    return $UserLocationCopyWith<$Res>(_value.userLocation!, (value) {
      return _then(_value.copyWith(userLocation: value) as $Val);
    });
  }

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrivacySettingsCopyWith<$Res>? get privacy {
    if (_value.privacy == null) {
      return null;
    }

    return $PrivacySettingsCopyWith<$Res>(_value.privacy!, (value) {
      return _then(_value.copyWith(privacy: value) as $Val);
    });
  }

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NotificationPreferencesCopyWith<$Res>? get notifications {
    if (_value.notifications == null) {
      return null;
    }

    return $NotificationPreferencesCopyWith<$Res>(_value.notifications!,
        (value) {
      return _then(_value.copyWith(notifications: value) as $Val);
    });
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
      String? displayName,
      String? firstName,
      String? lastName,
      @TimestampConverter() DateTime birthDate,
      String? favoriteTeamId,
      String? favoriteProTeamId,
      String? facebookProfileUrl,
      String? instagramProfileUrl,
      bool showSocialLinks,
      String availabilityStatus,
      bool isActive,
      bool isFictitious,
      @TimestampConverter() DateTime createdAt,
      List<String> hubIds,
      double currentRankScore,
      String preferredPosition,
      double? heightCm,
      double? weightKg,
      int totalParticipations,
      int gamesPlayed,
      @NullableGeographicPointFirestoreConverter() GeographicPoint? location,
      String? geohash,
      String? region,
      UserLocation? userLocation,
      bool isProfileComplete,
      int followerCount,
      int wins,
      int losses,
      int draws,
      int goals,
      int assists,
      Map<String, bool> privacySettings,
      PrivacySettings? privacy,
      Map<String, bool> notificationPreferences,
      NotificationPreferences? notifications,
      List<String> blockedUserIds});

  @override
  $GeographicPointCopyWith<$Res>? get location;
  @override
  $UserLocationCopyWith<$Res>? get userLocation;
  @override
  $PrivacySettingsCopyWith<$Res>? get privacy;
  @override
  $NotificationPreferencesCopyWith<$Res>? get notifications;
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
    Object? displayName = freezed,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? birthDate = null,
    Object? favoriteTeamId = freezed,
    Object? favoriteProTeamId = freezed,
    Object? facebookProfileUrl = freezed,
    Object? instagramProfileUrl = freezed,
    Object? showSocialLinks = null,
    Object? availabilityStatus = null,
    Object? isActive = null,
    Object? isFictitious = null,
    Object? createdAt = null,
    Object? hubIds = null,
    Object? currentRankScore = null,
    Object? preferredPosition = null,
    Object? heightCm = freezed,
    Object? weightKg = freezed,
    Object? totalParticipations = null,
    Object? gamesPlayed = null,
    Object? location = freezed,
    Object? geohash = freezed,
    Object? region = freezed,
    Object? userLocation = freezed,
    Object? isProfileComplete = null,
    Object? followerCount = null,
    Object? wins = null,
    Object? losses = null,
    Object? draws = null,
    Object? goals = null,
    Object? assists = null,
    Object? privacySettings = null,
    Object? privacy = freezed,
    Object? notificationPreferences = null,
    Object? notifications = freezed,
    Object? blockedUserIds = null,
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
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      birthDate: null == birthDate
          ? _value.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      favoriteTeamId: freezed == favoriteTeamId
          ? _value.favoriteTeamId
          : favoriteTeamId // ignore: cast_nullable_to_non_nullable
              as String?,
      favoriteProTeamId: freezed == favoriteProTeamId
          ? _value.favoriteProTeamId
          : favoriteProTeamId // ignore: cast_nullable_to_non_nullable
              as String?,
      facebookProfileUrl: freezed == facebookProfileUrl
          ? _value.facebookProfileUrl
          : facebookProfileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      instagramProfileUrl: freezed == instagramProfileUrl
          ? _value.instagramProfileUrl
          : instagramProfileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      showSocialLinks: null == showSocialLinks
          ? _value.showSocialLinks
          : showSocialLinks // ignore: cast_nullable_to_non_nullable
              as bool,
      availabilityStatus: null == availabilityStatus
          ? _value.availabilityStatus
          : availabilityStatus // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      isFictitious: null == isFictitious
          ? _value.isFictitious
          : isFictitious // ignore: cast_nullable_to_non_nullable
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
      heightCm: freezed == heightCm
          ? _value.heightCm
          : heightCm // ignore: cast_nullable_to_non_nullable
              as double?,
      weightKg: freezed == weightKg
          ? _value.weightKg
          : weightKg // ignore: cast_nullable_to_non_nullable
              as double?,
      totalParticipations: null == totalParticipations
          ? _value.totalParticipations
          : totalParticipations // ignore: cast_nullable_to_non_nullable
              as int,
      gamesPlayed: null == gamesPlayed
          ? _value.gamesPlayed
          : gamesPlayed // ignore: cast_nullable_to_non_nullable
              as int,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeographicPoint?,
      geohash: freezed == geohash
          ? _value.geohash
          : geohash // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String?,
      userLocation: freezed == userLocation
          ? _value.userLocation
          : userLocation // ignore: cast_nullable_to_non_nullable
              as UserLocation?,
      isProfileComplete: null == isProfileComplete
          ? _value.isProfileComplete
          : isProfileComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      followerCount: null == followerCount
          ? _value.followerCount
          : followerCount // ignore: cast_nullable_to_non_nullable
              as int,
      wins: null == wins
          ? _value.wins
          : wins // ignore: cast_nullable_to_non_nullable
              as int,
      losses: null == losses
          ? _value.losses
          : losses // ignore: cast_nullable_to_non_nullable
              as int,
      draws: null == draws
          ? _value.draws
          : draws // ignore: cast_nullable_to_non_nullable
              as int,
      goals: null == goals
          ? _value.goals
          : goals // ignore: cast_nullable_to_non_nullable
              as int,
      assists: null == assists
          ? _value.assists
          : assists // ignore: cast_nullable_to_non_nullable
              as int,
      privacySettings: null == privacySettings
          ? _value._privacySettings
          : privacySettings // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>,
      privacy: freezed == privacy
          ? _value.privacy
          : privacy // ignore: cast_nullable_to_non_nullable
              as PrivacySettings?,
      notificationPreferences: null == notificationPreferences
          ? _value._notificationPreferences
          : notificationPreferences // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>,
      notifications: freezed == notifications
          ? _value.notifications
          : notifications // ignore: cast_nullable_to_non_nullable
              as NotificationPreferences?,
      blockedUserIds: null == blockedUserIds
          ? _value._blockedUserIds
          : blockedUserIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
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
      this.displayName,
      this.firstName,
      this.lastName,
      @TimestampConverter() required this.birthDate,
      this.favoriteTeamId,
      this.favoriteProTeamId,
      this.facebookProfileUrl,
      this.instagramProfileUrl,
      this.showSocialLinks = false,
      this.availabilityStatus = 'available',
      this.isActive = true,
      this.isFictitious = false,
      @TimestampConverter() required this.createdAt,
      final List<String> hubIds = const [],
      this.currentRankScore = 5.0,
      this.preferredPosition = 'Midfielder',
      this.heightCm,
      this.weightKg,
      this.totalParticipations = 0,
      this.gamesPlayed = 0,
      @NullableGeographicPointFirestoreConverter() this.location,
      this.geohash,
      this.region,
      this.userLocation,
      this.isProfileComplete = false,
      this.followerCount = 0,
      this.wins = 0,
      this.losses = 0,
      this.draws = 0,
      this.goals = 0,
      this.assists = 0,
      final Map<String, bool> privacySettings = const {
        'hideFromSearch': false,
        'hideEmail': false,
        'hidePhone': false,
        'hideCity': false,
        'hideStats': false,
        'hideRatings': false,
        'allowHubInvites': true
      },
      this.privacy,
      final Map<String, bool> notificationPreferences = const {
        'game_reminder': true,
        'message': true,
        'like': true,
        'comment': true,
        'signup': true,
        'new_follower': true,
        'hub_chat': true,
        'new_comment': true,
        'new_game': true
      },
      this.notifications,
      final List<String> blockedUserIds = const []})
      : _hubIds = hubIds,
        _privacySettings = privacySettings,
        _notificationPreferences = notificationPreferences,
        _blockedUserIds = blockedUserIds;

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
  final String? displayName;
// Custom nickname (shown to others) - independent from firstName/lastName
  @override
  final String? firstName;
  @override
  final String? lastName;
  @override
  @TimestampConverter()
  final DateTime birthDate;
// ✅ Required field
  @override
  final String? favoriteTeamId;
// DEPRECATED: Old field, use favoriteProTeamId instead
  @override
  final String? favoriteProTeamId;
// ID of favorite professional team (Israeli Premier/National League)
  @override
  final String? facebookProfileUrl;
  @override
  final String? instagramProfileUrl;
  @override
  @JsonKey()
  final bool showSocialLinks;
// Control visibility of social links to other users
  @override
  @JsonKey()
  final String availabilityStatus;
// available, busy, notAvailable (deprecated, use isActive)
  @override
  @JsonKey()
  final bool isActive;
// true = פתוח להאבים והזמנות, false = לא פתוח
  @override
  @JsonKey()
  final bool isFictitious;
// Marks manual players created by managers
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
// 'Goalkeeper', 'Defender', 'Midfielder', 'Attacker'
// REMOVED: playingStyle - merged into preferredPosition
// Physical data (optional, metric units)
  @override
  final double? heightCm;
// גובה בסנטימטרים (140-220)
  @override
  final double? weightKg;
// משקל בקילוגרמים (40-150)
  @override
  @JsonKey()
  final int totalParticipations;
// Total games played (for milestone badges)
  @override
  @JsonKey()
  final int gamesPlayed;
// Compatibility field used throughout the app
// DEPRECATED: Old location fields - use userLocation instead
// Kept for backward compatibility during migration
  @override
  @NullableGeographicPointFirestoreConverter()
  final GeographicPoint? location;
  @override
  final String? geohash;
  @override
  final String? region;
// אזור: צפון, מרכז, דרום, ירושלים
// NEW: Location value object (Phase 4 - dual-write pattern)
  @override
  final UserLocation? userLocation;
  @override
  @JsonKey()
  final bool isProfileComplete;
// Denormalized fields (updated by Cloud Functions, not written by client)
  @override
  @JsonKey()
  final int followerCount;
// Denormalized: Count of followers (updated by onFollowCreated)
// Player Stats (denormalized from game participations)
  @override
  @JsonKey()
  final int wins;
  @override
  @JsonKey()
  final int losses;
  @override
  @JsonKey()
  final int draws;
  @override
  @JsonKey()
  final int goals;
  @override
  @JsonKey()
  final int assists;
// DEPRECATED: Old privacy settings map - use privacy instead
// Kept for backward compatibility during migration
  final Map<String, bool> _privacySettings;
// DEPRECATED: Old privacy settings map - use privacy instead
// Kept for backward compatibility during migration
  @override
  @JsonKey()
  Map<String, bool> get privacySettings {
    if (_privacySettings is EqualUnmodifiableMapView) return _privacySettings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_privacySettings);
  }

// NEW: Privacy value object (Phase 4 - dual-write pattern)
  @override
  final PrivacySettings? privacy;
// DEPRECATED: Old notification preferences map - use notifications instead
// Kept for backward compatibility during migration
  final Map<String, bool> _notificationPreferences;
// DEPRECATED: Old notification preferences map - use notifications instead
// Kept for backward compatibility during migration
  @override
  @JsonKey()
  Map<String, bool> get notificationPreferences {
    if (_notificationPreferences is EqualUnmodifiableMapView)
      return _notificationPreferences;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_notificationPreferences);
  }

// NEW: Notification preferences value object (Phase 4 - dual-write pattern)
  @override
  final NotificationPreferences? notifications;
// Blocked users - users this user has blocked
  final List<String> _blockedUserIds;
// Blocked users - users this user has blocked
  @override
  @JsonKey()
  List<String> get blockedUserIds {
    if (_blockedUserIds is EqualUnmodifiableListView) return _blockedUserIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_blockedUserIds);
  }

  @override
  String toString() {
    return 'User(uid: $uid, name: $name, email: $email, photoUrl: $photoUrl, avatarColor: $avatarColor, phoneNumber: $phoneNumber, city: $city, displayName: $displayName, firstName: $firstName, lastName: $lastName, birthDate: $birthDate, favoriteTeamId: $favoriteTeamId, favoriteProTeamId: $favoriteProTeamId, facebookProfileUrl: $facebookProfileUrl, instagramProfileUrl: $instagramProfileUrl, showSocialLinks: $showSocialLinks, availabilityStatus: $availabilityStatus, isActive: $isActive, isFictitious: $isFictitious, createdAt: $createdAt, hubIds: $hubIds, currentRankScore: $currentRankScore, preferredPosition: $preferredPosition, heightCm: $heightCm, weightKg: $weightKg, totalParticipations: $totalParticipations, gamesPlayed: $gamesPlayed, location: $location, geohash: $geohash, region: $region, userLocation: $userLocation, isProfileComplete: $isProfileComplete, followerCount: $followerCount, wins: $wins, losses: $losses, draws: $draws, goals: $goals, assists: $assists, privacySettings: $privacySettings, privacy: $privacy, notificationPreferences: $notificationPreferences, notifications: $notifications, blockedUserIds: $blockedUserIds)';
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
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.birthDate, birthDate) ||
                other.birthDate == birthDate) &&
            (identical(other.favoriteTeamId, favoriteTeamId) ||
                other.favoriteTeamId == favoriteTeamId) &&
            (identical(other.favoriteProTeamId, favoriteProTeamId) ||
                other.favoriteProTeamId == favoriteProTeamId) &&
            (identical(other.facebookProfileUrl, facebookProfileUrl) ||
                other.facebookProfileUrl == facebookProfileUrl) &&
            (identical(other.instagramProfileUrl, instagramProfileUrl) ||
                other.instagramProfileUrl == instagramProfileUrl) &&
            (identical(other.showSocialLinks, showSocialLinks) ||
                other.showSocialLinks == showSocialLinks) &&
            (identical(other.availabilityStatus, availabilityStatus) ||
                other.availabilityStatus == availabilityStatus) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.isFictitious, isFictitious) ||
                other.isFictitious == isFictitious) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(other._hubIds, _hubIds) &&
            (identical(other.currentRankScore, currentRankScore) ||
                other.currentRankScore == currentRankScore) &&
            (identical(other.preferredPosition, preferredPosition) ||
                other.preferredPosition == preferredPosition) &&
            (identical(other.heightCm, heightCm) ||
                other.heightCm == heightCm) &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.totalParticipations, totalParticipations) ||
                other.totalParticipations == totalParticipations) &&
            (identical(other.gamesPlayed, gamesPlayed) ||
                other.gamesPlayed == gamesPlayed) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.geohash, geohash) || other.geohash == geohash) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.userLocation, userLocation) ||
                other.userLocation == userLocation) &&
            (identical(other.isProfileComplete, isProfileComplete) ||
                other.isProfileComplete == isProfileComplete) &&
            (identical(other.followerCount, followerCount) ||
                other.followerCount == followerCount) &&
            (identical(other.wins, wins) || other.wins == wins) &&
            (identical(other.losses, losses) || other.losses == losses) &&
            (identical(other.draws, draws) || other.draws == draws) &&
            (identical(other.goals, goals) || other.goals == goals) &&
            (identical(other.assists, assists) || other.assists == assists) &&
            const DeepCollectionEquality()
                .equals(other._privacySettings, _privacySettings) &&
            (identical(other.privacy, privacy) || other.privacy == privacy) &&
            const DeepCollectionEquality().equals(
                other._notificationPreferences, _notificationPreferences) &&
            (identical(other.notifications, notifications) ||
                other.notifications == notifications) &&
            const DeepCollectionEquality()
                .equals(other._blockedUserIds, _blockedUserIds));
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
        displayName,
        firstName,
        lastName,
        birthDate,
        favoriteTeamId,
        favoriteProTeamId,
        facebookProfileUrl,
        instagramProfileUrl,
        showSocialLinks,
        availabilityStatus,
        isActive,
        isFictitious,
        createdAt,
        const DeepCollectionEquality().hash(_hubIds),
        currentRankScore,
        preferredPosition,
        heightCm,
        weightKg,
        totalParticipations,
        gamesPlayed,
        location,
        geohash,
        region,
        userLocation,
        isProfileComplete,
        followerCount,
        wins,
        losses,
        draws,
        goals,
        assists,
        const DeepCollectionEquality().hash(_privacySettings),
        privacy,
        const DeepCollectionEquality().hash(_notificationPreferences),
        notifications,
        const DeepCollectionEquality().hash(_blockedUserIds)
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
      final String? displayName,
      final String? firstName,
      final String? lastName,
      @TimestampConverter() required final DateTime birthDate,
      final String? favoriteTeamId,
      final String? favoriteProTeamId,
      final String? facebookProfileUrl,
      final String? instagramProfileUrl,
      final bool showSocialLinks,
      final String availabilityStatus,
      final bool isActive,
      final bool isFictitious,
      @TimestampConverter() required final DateTime createdAt,
      final List<String> hubIds,
      final double currentRankScore,
      final String preferredPosition,
      final double? heightCm,
      final double? weightKg,
      final int totalParticipations,
      final int gamesPlayed,
      @NullableGeographicPointFirestoreConverter()
      final GeographicPoint? location,
      final String? geohash,
      final String? region,
      final UserLocation? userLocation,
      final bool isProfileComplete,
      final int followerCount,
      final int wins,
      final int losses,
      final int draws,
      final int goals,
      final int assists,
      final Map<String, bool> privacySettings,
      final PrivacySettings? privacy,
      final Map<String, bool> notificationPreferences,
      final NotificationPreferences? notifications,
      final List<String> blockedUserIds}) = _$UserImpl;

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
  String?
      get displayName; // Custom nickname (shown to others) - independent from firstName/lastName
  @override
  String? get firstName;
  @override
  String? get lastName;
  @override
  @TimestampConverter()
  DateTime get birthDate; // ✅ Required field
  @override
  String?
      get favoriteTeamId; // DEPRECATED: Old field, use favoriteProTeamId instead
  @override
  String?
      get favoriteProTeamId; // ID of favorite professional team (Israeli Premier/National League)
  @override
  String? get facebookProfileUrl;
  @override
  String? get instagramProfileUrl;
  @override
  bool get showSocialLinks; // Control visibility of social links to other users
  @override
  String
      get availabilityStatus; // available, busy, notAvailable (deprecated, use isActive)
  @override
  bool get isActive; // true = פתוח להאבים והזמנות, false = לא פתוח
  @override
  bool get isFictitious; // Marks manual players created by managers
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
  String
      get preferredPosition; // 'Goalkeeper', 'Defender', 'Midfielder', 'Attacker'
// REMOVED: playingStyle - merged into preferredPosition
// Physical data (optional, metric units)
  @override
  double? get heightCm; // גובה בסנטימטרים (140-220)
  @override
  double? get weightKg; // משקל בקילוגרמים (40-150)
  @override
  int get totalParticipations; // Total games played (for milestone badges)
  @override
  int get gamesPlayed; // Compatibility field used throughout the app
// DEPRECATED: Old location fields - use userLocation instead
// Kept for backward compatibility during migration
  @override
  @NullableGeographicPointFirestoreConverter()
  GeographicPoint? get location;
  @override
  String? get geohash;
  @override
  String? get region; // אזור: צפון, מרכז, דרום, ירושלים
// NEW: Location value object (Phase 4 - dual-write pattern)
  @override
  UserLocation? get userLocation;
  @override
  bool
      get isProfileComplete; // Denormalized fields (updated by Cloud Functions, not written by client)
  @override
  int get followerCount; // Denormalized: Count of followers (updated by onFollowCreated)
// Player Stats (denormalized from game participations)
  @override
  int get wins;
  @override
  int get losses;
  @override
  int get draws;
  @override
  int get goals;
  @override
  int get assists; // DEPRECATED: Old privacy settings map - use privacy instead
// Kept for backward compatibility during migration
  @override
  Map<String, bool>
      get privacySettings; // NEW: Privacy value object (Phase 4 - dual-write pattern)
  @override
  PrivacySettings?
      get privacy; // DEPRECATED: Old notification preferences map - use notifications instead
// Kept for backward compatibility during migration
  @override
  Map<String, bool>
      get notificationPreferences; // NEW: Notification preferences value object (Phase 4 - dual-write pattern)
  @override
  NotificationPreferences?
      get notifications; // Blocked users - users this user has blocked
  @override
  List<String> get blockedUserIds;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
