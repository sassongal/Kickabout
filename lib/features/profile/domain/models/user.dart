import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/shared/domain/models/age_group.dart';
import 'package:kattrick/shared/infrastructure/firestore/converters/timestamp_firestore_converter.dart';
import 'package:kattrick/shared/domain/models/value_objects/geographic_point.dart';
import 'package:kattrick/shared/domain/models/value_objects/notification_preferences.dart';
import 'package:kattrick/shared/domain/models/value_objects/privacy_settings.dart';
import 'package:kattrick/shared/domain/models/value_objects/user_location.dart';
import 'package:kattrick/shared/infrastructure/firestore/converters/geographic_point_firestore_converter.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// User model matching Firestore schema: /users/{uid}
@freezed
class User with _$User {
  const factory User({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
    String? avatarColor, // Hex color for avatar background (e.g., "#FF5733")
    String? phoneNumber,
    String? city, // עיר מגורים
    // New profile fields
    String?
        displayName, // Custom nickname (shown to others) - independent from firstName/lastName
    String? firstName,
    String? lastName,
    @TimestampConverter() required DateTime birthDate, // ✅ Required field
    String?
        favoriteTeamId, // DEPRECATED: Old field, use favoriteProTeamId instead
    String?
        favoriteProTeamId, // ID of favorite professional team (Israeli Premier/National League)
    String? facebookProfileUrl,
    String? instagramProfileUrl,
    @Default(false)
    bool showSocialLinks, // Control visibility of social links to other users
    @Default('available')
    String
        availabilityStatus, // available, busy, notAvailable (deprecated, use isActive)
    @Default(true) bool isActive, // true = פתוח להאבים והזמנות, false = לא פתוח
    @Default(false)
    bool isFictitious, // Marks manual players created by managers
    @TimestampConverter() required DateTime createdAt,
    @Default([]) List<String> hubIds,
    // DEPRECATED: currentRankScore - Use managerRatings in Hub model instead
    // Keeping for backward compatibility, but should not be used for new features
    @Default(5.0)
    double currentRankScore, // DEPRECATED: Use Hub.managerRatings instead
    @Default('Midfielder')
    String
        preferredPosition, // 'Goalkeeper', 'Defender', 'Midfielder', 'Attacker'
    // REMOVED: playingStyle - merged into preferredPosition
    // Physical data (optional, metric units)
    double? heightCm, // גובה בסנטימטרים (140-220)
    double? weightKg, // משקל בקילוגרמים (40-150)
    String? preferredFoot, // 'left', 'right', 'both'
    @Default(false) bool hasCar, // Has a car for ride-sharing (Trempiyada feature)
    @Default(0)
    int totalParticipations, // Total games played (for milestone badges)
    @Default(0) int gamesPlayed, // Compatibility field used throughout the app

    // DEPRECATED: Old location fields - use userLocation instead
    // Kept for backward compatibility during migration
    @NullableGeographicPointFirestoreConverter() GeographicPoint? location,
    String? geohash,
    String? region, // אזור: צפון, מרכז, דרום, ירושלים

    // NEW: Location value object (Phase 4 - dual-write pattern)
    UserLocation? userLocation,
    @Default(false) bool isProfileComplete,
    // Denormalized fields (updated by Cloud Functions, not written by client)
    @Default(0)
    int followerCount, // Denormalized: Count of followers (updated by onFollowCreated)
    // Player Stats (denormalized from game participations)
    @Default(0) int wins,
    @Default(0) int losses,
    @Default(0) int draws,
    @Default(0) int goals,
    @Default(0) int assists,

    // DEPRECATED: Old privacy settings map - use privacy instead
    // Kept for backward compatibility during migration
    @Default({
      'hideFromSearch': false,
      'hideEmail': false,
      'hidePhone': false,
      'hideCity': false,
      'hideStats': false,
      'hideRatings': false,
      'allowHubInvites': true,
    })
    Map<String, bool> privacySettings,

    // NEW: Privacy value object (Phase 4 - dual-write pattern)
    PrivacySettings? privacy,

    // DEPRECATED: Old notification preferences map - use notifications instead
    // Kept for backward compatibility during migration
    @Default({
      'game_reminder': true,
      'message': true,
      'like': true,
      'comment': true,
      'signup': true,
      'new_follower': true,
      'hub_chat': true,
      'new_comment': true,
      'new_game': true,
    })
    Map<String, bool> notificationPreferences,

    // NEW: Notification preferences value object (Phase 4 - dual-write pattern)
    NotificationPreferences? notifications,

    // Blocked users - users this user has blocked
    @Default([]) List<String> blockedUserIds,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

/// Extension for Phase 4 backward compatibility
///
/// Provides getters that read from BOTH new value objects AND old map fields.
/// Priority: new value objects > old maps (for gradual migration)
extension UserValueObjects on User {
  /// Get privacy settings - uses new privacy object or falls back to old map
  PrivacySettings get effectivePrivacy {
    return privacy ?? PrivacySettings.fromLegacyMap(privacySettings);
  }

  /// Get notification preferences - uses new notifications object or falls back to old map
  NotificationPreferences get effectiveNotifications {
    return notifications ??
        NotificationPreferences.fromLegacyMap(notificationPreferences);
  }

  /// Get user location - uses new userLocation object or constructs from old fields
  UserLocation? get effectiveLocation {
    if (userLocation != null) return userLocation;
    if (location != null) {
      return UserLocation(
        location: location,
        geohash: geohash,
        city: city,
        region: region,
      );
    }
    return null;
  }
}

/// Extension to add displayName getter to User
extension UserDisplayName on User {
  /// Get display name - prioritizes firstName + lastName, then name, then optional custom nickname
  String get displayName {
    final hasFirst = firstName != null && firstName!.isNotEmpty;
    final hasLast = lastName != null && lastName!.isNotEmpty;

    if (hasFirst && hasLast) return '$firstName $lastName';
    if (hasFirst) return firstName!;
    if (hasLast) return lastName!;

    // Fall back to canonical name, then optional custom nickname
    if (name.isNotEmpty) return name;
    if (this.displayName != null && this.displayName!.isNotEmpty) {
      return this.displayName!;
    }
    return 'שחקן';
  }
}

/// Extension to add age-related getters to User
extension UserAgeExtension on User {
  /// Get user's current age
  /// birthDate is now required, so this always returns a value
  int get age {
    return AgeUtils.calculateAge(birthDate);
  }

  /// Get user's age group
  /// Returns null if age < 13
  AgeGroup? get ageGroup {
    try {
      return AgeUtils.getAgeGroup(birthDate);
    } catch (e) {
      return null;
    }
  }

  /// Get age category (Kids, Young, Adults, Veterans, Legends)
  String get ageCategory {
    return AgeUtils.getAgeCategory(birthDate);
  }

  /// Check if user meets minimum age requirement (13+)
  bool get meetsMinimumAge {
    return AgeUtils.isAgeValid(birthDate);
  }
}

/// Firestore converter for User
class UserConverter implements JsonConverter<User, Map<String, dynamic>> {
  const UserConverter();

  @override
  User fromJson(Map<String, dynamic> json) => User.fromJson(json);

  @override
  Map<String, dynamic> toJson(User object) => object.toJson();
}
