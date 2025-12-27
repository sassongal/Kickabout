// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'privacy_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PrivacySettings _$PrivacySettingsFromJson(Map<String, dynamic> json) {
  return _PrivacySettings.fromJson(json);
}

/// @nodoc
mixin _$PrivacySettings {
  bool get hideFromSearch => throw _privateConstructorUsedError;
  bool get hideEmail => throw _privateConstructorUsedError;
  bool get hidePhone => throw _privateConstructorUsedError;
  bool get hideCity => throw _privateConstructorUsedError;
  bool get hideStats => throw _privateConstructorUsedError;
  bool get hideRatings => throw _privateConstructorUsedError;
  bool get allowHubInvites => throw _privateConstructorUsedError;

  /// Serializes this PrivacySettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PrivacySettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PrivacySettingsCopyWith<PrivacySettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PrivacySettingsCopyWith<$Res> {
  factory $PrivacySettingsCopyWith(
          PrivacySettings value, $Res Function(PrivacySettings) then) =
      _$PrivacySettingsCopyWithImpl<$Res, PrivacySettings>;
  @useResult
  $Res call(
      {bool hideFromSearch,
      bool hideEmail,
      bool hidePhone,
      bool hideCity,
      bool hideStats,
      bool hideRatings,
      bool allowHubInvites});
}

/// @nodoc
class _$PrivacySettingsCopyWithImpl<$Res, $Val extends PrivacySettings>
    implements $PrivacySettingsCopyWith<$Res> {
  _$PrivacySettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PrivacySettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hideFromSearch = null,
    Object? hideEmail = null,
    Object? hidePhone = null,
    Object? hideCity = null,
    Object? hideStats = null,
    Object? hideRatings = null,
    Object? allowHubInvites = null,
  }) {
    return _then(_value.copyWith(
      hideFromSearch: null == hideFromSearch
          ? _value.hideFromSearch
          : hideFromSearch // ignore: cast_nullable_to_non_nullable
              as bool,
      hideEmail: null == hideEmail
          ? _value.hideEmail
          : hideEmail // ignore: cast_nullable_to_non_nullable
              as bool,
      hidePhone: null == hidePhone
          ? _value.hidePhone
          : hidePhone // ignore: cast_nullable_to_non_nullable
              as bool,
      hideCity: null == hideCity
          ? _value.hideCity
          : hideCity // ignore: cast_nullable_to_non_nullable
              as bool,
      hideStats: null == hideStats
          ? _value.hideStats
          : hideStats // ignore: cast_nullable_to_non_nullable
              as bool,
      hideRatings: null == hideRatings
          ? _value.hideRatings
          : hideRatings // ignore: cast_nullable_to_non_nullable
              as bool,
      allowHubInvites: null == allowHubInvites
          ? _value.allowHubInvites
          : allowHubInvites // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PrivacySettingsImplCopyWith<$Res>
    implements $PrivacySettingsCopyWith<$Res> {
  factory _$$PrivacySettingsImplCopyWith(_$PrivacySettingsImpl value,
          $Res Function(_$PrivacySettingsImpl) then) =
      __$$PrivacySettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool hideFromSearch,
      bool hideEmail,
      bool hidePhone,
      bool hideCity,
      bool hideStats,
      bool hideRatings,
      bool allowHubInvites});
}

/// @nodoc
class __$$PrivacySettingsImplCopyWithImpl<$Res>
    extends _$PrivacySettingsCopyWithImpl<$Res, _$PrivacySettingsImpl>
    implements _$$PrivacySettingsImplCopyWith<$Res> {
  __$$PrivacySettingsImplCopyWithImpl(
      _$PrivacySettingsImpl _value, $Res Function(_$PrivacySettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of PrivacySettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hideFromSearch = null,
    Object? hideEmail = null,
    Object? hidePhone = null,
    Object? hideCity = null,
    Object? hideStats = null,
    Object? hideRatings = null,
    Object? allowHubInvites = null,
  }) {
    return _then(_$PrivacySettingsImpl(
      hideFromSearch: null == hideFromSearch
          ? _value.hideFromSearch
          : hideFromSearch // ignore: cast_nullable_to_non_nullable
              as bool,
      hideEmail: null == hideEmail
          ? _value.hideEmail
          : hideEmail // ignore: cast_nullable_to_non_nullable
              as bool,
      hidePhone: null == hidePhone
          ? _value.hidePhone
          : hidePhone // ignore: cast_nullable_to_non_nullable
              as bool,
      hideCity: null == hideCity
          ? _value.hideCity
          : hideCity // ignore: cast_nullable_to_non_nullable
              as bool,
      hideStats: null == hideStats
          ? _value.hideStats
          : hideStats // ignore: cast_nullable_to_non_nullable
              as bool,
      hideRatings: null == hideRatings
          ? _value.hideRatings
          : hideRatings // ignore: cast_nullable_to_non_nullable
              as bool,
      allowHubInvites: null == allowHubInvites
          ? _value.allowHubInvites
          : allowHubInvites // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PrivacySettingsImpl implements _PrivacySettings {
  const _$PrivacySettingsImpl(
      {this.hideFromSearch = false,
      this.hideEmail = false,
      this.hidePhone = false,
      this.hideCity = false,
      this.hideStats = false,
      this.hideRatings = false,
      this.allowHubInvites = true});

  factory _$PrivacySettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$PrivacySettingsImplFromJson(json);

  @override
  @JsonKey()
  final bool hideFromSearch;
  @override
  @JsonKey()
  final bool hideEmail;
  @override
  @JsonKey()
  final bool hidePhone;
  @override
  @JsonKey()
  final bool hideCity;
  @override
  @JsonKey()
  final bool hideStats;
  @override
  @JsonKey()
  final bool hideRatings;
  @override
  @JsonKey()
  final bool allowHubInvites;

  @override
  String toString() {
    return 'PrivacySettings(hideFromSearch: $hideFromSearch, hideEmail: $hideEmail, hidePhone: $hidePhone, hideCity: $hideCity, hideStats: $hideStats, hideRatings: $hideRatings, allowHubInvites: $allowHubInvites)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PrivacySettingsImpl &&
            (identical(other.hideFromSearch, hideFromSearch) ||
                other.hideFromSearch == hideFromSearch) &&
            (identical(other.hideEmail, hideEmail) ||
                other.hideEmail == hideEmail) &&
            (identical(other.hidePhone, hidePhone) ||
                other.hidePhone == hidePhone) &&
            (identical(other.hideCity, hideCity) ||
                other.hideCity == hideCity) &&
            (identical(other.hideStats, hideStats) ||
                other.hideStats == hideStats) &&
            (identical(other.hideRatings, hideRatings) ||
                other.hideRatings == hideRatings) &&
            (identical(other.allowHubInvites, allowHubInvites) ||
                other.allowHubInvites == allowHubInvites));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, hideFromSearch, hideEmail,
      hidePhone, hideCity, hideStats, hideRatings, allowHubInvites);

  /// Create a copy of PrivacySettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PrivacySettingsImplCopyWith<_$PrivacySettingsImpl> get copyWith =>
      __$$PrivacySettingsImplCopyWithImpl<_$PrivacySettingsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PrivacySettingsImplToJson(
      this,
    );
  }
}

abstract class _PrivacySettings implements PrivacySettings {
  const factory _PrivacySettings(
      {final bool hideFromSearch,
      final bool hideEmail,
      final bool hidePhone,
      final bool hideCity,
      final bool hideStats,
      final bool hideRatings,
      final bool allowHubInvites}) = _$PrivacySettingsImpl;

  factory _PrivacySettings.fromJson(Map<String, dynamic> json) =
      _$PrivacySettingsImpl.fromJson;

  @override
  bool get hideFromSearch;
  @override
  bool get hideEmail;
  @override
  bool get hidePhone;
  @override
  bool get hideCity;
  @override
  bool get hideStats;
  @override
  bool get hideRatings;
  @override
  bool get allowHubInvites;

  /// Create a copy of PrivacySettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PrivacySettingsImplCopyWith<_$PrivacySettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
