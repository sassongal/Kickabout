import 'package:freezed_annotation/freezed_annotation.dart';

/// Age Groups enum for player categorization
/// Based on Gap Analysis #2 - Age = Current Year - Birth Year
enum AgeGroup {
  @JsonValue('kids_13_15')
  kids13_15, // 13-15
  
  @JsonValue('kids_16_18')
  kids16_18, // 16-18
  
  @JsonValue('young_18_21')
  young18_21, // 18-21
  
  @JsonValue('young_21_24')
  young21_24, // 21-24
  
  @JsonValue('adults_25_27')
  adults25_27, // 25-27
  
  @JsonValue('adults_28_30')
  adults28_30, // 28-30
  
  @JsonValue('adults_31_35')
  adults31_35, // 31-35
  
  @JsonValue('veterans_36_40')
  veterans36_40, // 36-40
  
  @JsonValue('veterans_41_45')
  veterans41_45, // 41-45
  
  @JsonValue('legends_46_50')
  legends46_50, // 46-50
  
  @JsonValue('legends_50_plus')
  legends50Plus, // 50+
}

/// Extension for AgeGroup helpers
extension AgeGroupExtension on AgeGroup {
  /// Get display name in Hebrew
  String get displayNameHe {
    switch (this) {
      case AgeGroup.kids13_15:
        return '13-15 (נוער)';
      case AgeGroup.kids16_18:
        return '16-18 (נוער)';
      case AgeGroup.young18_21:
        return '18-21 (צעירים)';
      case AgeGroup.young21_24:
        return '21-24 (צעירים)';
      case AgeGroup.adults25_27:
        return '25-27 (מבוגרים)';
      case AgeGroup.adults28_30:
        return '28-30 (מבוגרים)';
      case AgeGroup.adults31_35:
        return '31-35 (מבוגרים)';
      case AgeGroup.veterans36_40:
        return '36-40 (ותיקים)';
      case AgeGroup.veterans41_45:
        return '41-45 (ותיקים)';
      case AgeGroup.legends46_50:
        return '46-50 (אגדות)';
      case AgeGroup.legends50Plus:
        return '50+ (אגדות)';
    }
  }

  /// Get display name in English
  String get displayNameEn {
    switch (this) {
      case AgeGroup.kids13_15:
        return '13-15 (Kids)';
      case AgeGroup.kids16_18:
        return '16-18 (Kids)';
      case AgeGroup.young18_21:
        return '18-21 (Young)';
      case AgeGroup.young21_24:
        return '21-24 (Young)';
      case AgeGroup.adults25_27:
        return '25-27 (Adults)';
      case AgeGroup.adults28_30:
        return '28-30 (Adults)';
      case AgeGroup.adults31_35:
        return '31-35 (Adults)';
      case AgeGroup.veterans36_40:
        return '36-40 (Veterans)';
      case AgeGroup.veterans41_45:
        return '41-45 (Veterans)';
      case AgeGroup.legends46_50:
        return '46-50 (Legends)';
      case AgeGroup.legends50Plus:
        return '50+ (Legends)';
    }
  }

  /// Get age range (min, max)
  (int min, int max) get ageRange {
    switch (this) {
      case AgeGroup.kids13_15:
        return (13, 15);
      case AgeGroup.kids16_18:
        return (16, 18);
      case AgeGroup.young18_21:
        return (18, 21);
      case AgeGroup.young21_24:
        return (21, 24);
      case AgeGroup.adults25_27:
        return (25, 27);
      case AgeGroup.adults28_30:
        return (28, 30);
      case AgeGroup.adults31_35:
        return (31, 35);
      case AgeGroup.veterans36_40:
        return (36, 40);
      case AgeGroup.veterans41_45:
        return (41, 45);
      case AgeGroup.legends46_50:
        return (46, 50);
      case AgeGroup.legends50Plus:
        return (50, 150); // Max age
    }
  }
}

/// Age calculation and validation utilities
class AgeUtils {
  /// Minimum age allowed for signup (13 years)
  static const int minimumAge = 13;

  /// Calculate age from birth date
  /// Formula: Age = Current Year - Birth Year (as per Gap Analysis)
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    return now.year - birthDate.year;
  }

  /// Get age group from birth date
  /// Throws exception if age < 13
  static AgeGroup getAgeGroup(DateTime birthDate) {
    final age = calculateAge(birthDate);

    if (age < minimumAge) {
      throw ArgumentError(
        'User must be at least $minimumAge years old. Current age: $age',
      );
    }

    // Determine age group
    if (age >= 13 && age <= 15) return AgeGroup.kids13_15;
    if (age >= 16 && age <= 18) return AgeGroup.kids16_18;
    if (age >= 18 && age <= 21) return AgeGroup.young18_21;
    if (age >= 21 && age <= 24) return AgeGroup.young21_24;
    if (age >= 25 && age <= 27) return AgeGroup.adults25_27;
    if (age >= 28 && age <= 30) return AgeGroup.adults28_30;
    if (age >= 31 && age <= 35) return AgeGroup.adults31_35;
    if (age >= 36 && age <= 40) return AgeGroup.veterans36_40;
    if (age >= 41 && age <= 45) return AgeGroup.veterans41_45;
    if (age >= 46 && age <= 50) return AgeGroup.legends46_50;

    // 50+
    return AgeGroup.legends50Plus;
  }

  /// Validate if birth date meets minimum age requirement
  static bool isAgeValid(DateTime birthDate) {
    try {
      final age = calculateAge(birthDate);
      return age >= minimumAge;
    } catch (e) {
      return false;
    }
  }

  /// Get age category (Kids, Young, Adults, Veterans, Legends)
  static String getAgeCategory(DateTime birthDate) {
    final age = calculateAge(birthDate);

    if (age < 13) return 'Too Young';
    if (age <= 18) return 'Kids';
    if (age <= 24) return 'Young';
    if (age <= 35) return 'Adults';
    if (age <= 45) return 'Veterans';
    return 'Legends';
  }

  /// Get maximum birth date for minimum age (13 years ago from now)
  static DateTime get maxBirthDateForMinAge {
    final now = DateTime.now();
    return DateTime(now.year - minimumAge, now.month, now.day);
  }
}

