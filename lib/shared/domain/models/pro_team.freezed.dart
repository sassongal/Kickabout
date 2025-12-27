// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pro_team.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProTeam _$ProTeamFromJson(Map<String, dynamic> json) {
  return _ProTeam.fromJson(json);
}

/// @nodoc
mixin _$ProTeam {
  String get teamId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get nameEn =>
      throw _privateConstructorUsedError; // English name for sorting/search
  String get league =>
      throw _privateConstructorUsedError; // 'premier' or 'national'
  String get logoUrl => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;

  /// Serializes this ProTeam to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProTeam
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProTeamCopyWith<ProTeam> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProTeamCopyWith<$Res> {
  factory $ProTeamCopyWith(ProTeam value, $Res Function(ProTeam) then) =
      _$ProTeamCopyWithImpl<$Res, ProTeam>;
  @useResult
  $Res call(
      {String teamId,
      String name,
      String nameEn,
      String league,
      String logoUrl,
      bool isActive});
}

/// @nodoc
class _$ProTeamCopyWithImpl<$Res, $Val extends ProTeam>
    implements $ProTeamCopyWith<$Res> {
  _$ProTeamCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProTeam
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? teamId = null,
    Object? name = null,
    Object? nameEn = null,
    Object? league = null,
    Object? logoUrl = null,
    Object? isActive = null,
  }) {
    return _then(_value.copyWith(
      teamId: null == teamId
          ? _value.teamId
          : teamId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      nameEn: null == nameEn
          ? _value.nameEn
          : nameEn // ignore: cast_nullable_to_non_nullable
              as String,
      league: null == league
          ? _value.league
          : league // ignore: cast_nullable_to_non_nullable
              as String,
      logoUrl: null == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProTeamImplCopyWith<$Res> implements $ProTeamCopyWith<$Res> {
  factory _$$ProTeamImplCopyWith(
          _$ProTeamImpl value, $Res Function(_$ProTeamImpl) then) =
      __$$ProTeamImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String teamId,
      String name,
      String nameEn,
      String league,
      String logoUrl,
      bool isActive});
}

/// @nodoc
class __$$ProTeamImplCopyWithImpl<$Res>
    extends _$ProTeamCopyWithImpl<$Res, _$ProTeamImpl>
    implements _$$ProTeamImplCopyWith<$Res> {
  __$$ProTeamImplCopyWithImpl(
      _$ProTeamImpl _value, $Res Function(_$ProTeamImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProTeam
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? teamId = null,
    Object? name = null,
    Object? nameEn = null,
    Object? league = null,
    Object? logoUrl = null,
    Object? isActive = null,
  }) {
    return _then(_$ProTeamImpl(
      teamId: null == teamId
          ? _value.teamId
          : teamId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      nameEn: null == nameEn
          ? _value.nameEn
          : nameEn // ignore: cast_nullable_to_non_nullable
              as String,
      league: null == league
          ? _value.league
          : league // ignore: cast_nullable_to_non_nullable
              as String,
      logoUrl: null == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProTeamImpl implements _ProTeam {
  const _$ProTeamImpl(
      {required this.teamId,
      required this.name,
      required this.nameEn,
      required this.league,
      required this.logoUrl,
      this.isActive = true});

  factory _$ProTeamImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProTeamImplFromJson(json);

  @override
  final String teamId;
  @override
  final String name;
  @override
  final String nameEn;
// English name for sorting/search
  @override
  final String league;
// 'premier' or 'national'
  @override
  final String logoUrl;
  @override
  @JsonKey()
  final bool isActive;

  @override
  String toString() {
    return 'ProTeam(teamId: $teamId, name: $name, nameEn: $nameEn, league: $league, logoUrl: $logoUrl, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProTeamImpl &&
            (identical(other.teamId, teamId) || other.teamId == teamId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.nameEn, nameEn) || other.nameEn == nameEn) &&
            (identical(other.league, league) || other.league == league) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, teamId, name, nameEn, league, logoUrl, isActive);

  /// Create a copy of ProTeam
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProTeamImplCopyWith<_$ProTeamImpl> get copyWith =>
      __$$ProTeamImplCopyWithImpl<_$ProTeamImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProTeamImplToJson(
      this,
    );
  }
}

abstract class _ProTeam implements ProTeam {
  const factory _ProTeam(
      {required final String teamId,
      required final String name,
      required final String nameEn,
      required final String league,
      required final String logoUrl,
      final bool isActive}) = _$ProTeamImpl;

  factory _ProTeam.fromJson(Map<String, dynamic> json) = _$ProTeamImpl.fromJson;

  @override
  String get teamId;
  @override
  String get name;
  @override
  String get nameEn; // English name for sorting/search
  @override
  String get league; // 'premier' or 'national'
  @override
  String get logoUrl;
  @override
  bool get isActive;

  /// Create a copy of ProTeam
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProTeamImplCopyWith<_$ProTeamImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
