import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/models/converters/timestamp_converter.dart';
import 'package:kattrick/models/converters/geopoint_converter.dart';
import 'package:kattrick/models/age_group.dart';

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
    String? favoriteTeamId, // ID of favorite team from Firestore
    String? facebookProfileUrl,
    String? instagramProfileUrl,
    @Default(false)
    bool showSocialLinks, // Control visibility of social links to other users
    @Default('available')
    String
        availabilityStatus, // available, busy, notAvailable (deprecated, use isActive)
    @Default(true) bool isActive, // true = פתוח להאבים והזמנות, false = לא פתוח
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
    @Default(0)
    int totalParticipations, // Total games played (for milestone badges)
    @Default(0) int gamesPlayed, // Compatibility field used throughout the app

    @NullableGeoPointConverter() GeoPoint? location,
    String? geohash,
    String? region, // אזור: צפון, מרכז, דרום, ירושלים
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
    // Privacy settings - control what data is visible in search and profile
    @Default({
      'hideFromSearch': false,
      'hideEmail': false,
      'hidePhone': false,
      'hideCity': false,
      'hideStats': false,
      'hideRatings': false,
    })
    Map<String, bool> privacySettings,
    // Notification preferences - control which notifications user wants to receive
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
    // Blocked users - users this user has blocked
    @Default([]) List<String> blockedUserIds,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
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
