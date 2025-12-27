import 'package:freezed_annotation/freezed_annotation.dart';

part 'privacy_settings.freezed.dart';
part 'privacy_settings.g.dart';

/// Privacy settings value object
///
/// Extracted from User model to follow Single Responsibility Principle.
/// Encapsulates all privacy-related preferences in one cohesive object.
@freezed
class PrivacySettings with _$PrivacySettings {
  const factory PrivacySettings({
    @Default(false) bool hideFromSearch,
    @Default(false) bool hideEmail,
    @Default(false) bool hidePhone,
    @Default(false) bool hideCity,
    @Default(false) bool hideStats,
    @Default(false) bool hideRatings,
    @Default(true) bool allowHubInvites,
  }) = _PrivacySettings;

  factory PrivacySettings.fromJson(Map<String, dynamic> json) =>
      _$PrivacySettingsFromJson(json);

  /// Create from legacy Map<String, bool> format for backward compatibility
  factory PrivacySettings.fromLegacyMap(Map<String, dynamic>? map) {
    if (map == null) return const PrivacySettings();

    return PrivacySettings(
      hideFromSearch: map['hideFromSearch'] as bool? ?? false,
      hideEmail: map['hideEmail'] as bool? ?? false,
      hidePhone: map['hidePhone'] as bool? ?? false,
      hideCity: map['hideCity'] as bool? ?? false,
      hideStats: map['hideStats'] as bool? ?? false,
      hideRatings: map['hideRatings'] as bool? ?? false,
      allowHubInvites: map['allowHubInvites'] as bool? ?? true,
    );
  }
}
