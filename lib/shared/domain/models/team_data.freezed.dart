// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'team_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TeamData _$TeamDataFromJson(Map<String, dynamic> json) {
  return _TeamData.fromJson(json);
}

/// @nodoc
mixin _$TeamData {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get league =>
      throw _privateConstructorUsedError; // "Premier" or "National"
  String get logoUrl => throw _privateConstructorUsedError;

  /// Serializes this TeamData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TeamData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TeamDataCopyWith<TeamData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TeamDataCopyWith<$Res> {
  factory $TeamDataCopyWith(TeamData value, $Res Function(TeamData) then) =
      _$TeamDataCopyWithImpl<$Res, TeamData>;
  @useResult
  $Res call({String id, String name, String league, String logoUrl});
}

/// @nodoc
class _$TeamDataCopyWithImpl<$Res, $Val extends TeamData>
    implements $TeamDataCopyWith<$Res> {
  _$TeamDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TeamData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? league = null,
    Object? logoUrl = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      league: null == league
          ? _value.league
          : league // ignore: cast_nullable_to_non_nullable
              as String,
      logoUrl: null == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TeamDataImplCopyWith<$Res>
    implements $TeamDataCopyWith<$Res> {
  factory _$$TeamDataImplCopyWith(
          _$TeamDataImpl value, $Res Function(_$TeamDataImpl) then) =
      __$$TeamDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String league, String logoUrl});
}

/// @nodoc
class __$$TeamDataImplCopyWithImpl<$Res>
    extends _$TeamDataCopyWithImpl<$Res, _$TeamDataImpl>
    implements _$$TeamDataImplCopyWith<$Res> {
  __$$TeamDataImplCopyWithImpl(
      _$TeamDataImpl _value, $Res Function(_$TeamDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of TeamData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? league = null,
    Object? logoUrl = null,
  }) {
    return _then(_$TeamDataImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      league: null == league
          ? _value.league
          : league // ignore: cast_nullable_to_non_nullable
              as String,
      logoUrl: null == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TeamDataImpl implements _TeamData {
  const _$TeamDataImpl(
      {this.id = '',
      required this.name,
      required this.league,
      required this.logoUrl});

  factory _$TeamDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeamDataImplFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  final String name;
  @override
  final String league;
// "Premier" or "National"
  @override
  final String logoUrl;

  @override
  String toString() {
    return 'TeamData(id: $id, name: $name, league: $league, logoUrl: $logoUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TeamDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.league, league) || other.league == league) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, league, logoUrl);

  /// Create a copy of TeamData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TeamDataImplCopyWith<_$TeamDataImpl> get copyWith =>
      __$$TeamDataImplCopyWithImpl<_$TeamDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TeamDataImplToJson(
      this,
    );
  }
}

abstract class _TeamData implements TeamData {
  const factory _TeamData(
      {final String id,
      required final String name,
      required final String league,
      required final String logoUrl}) = _$TeamDataImpl;

  factory _TeamData.fromJson(Map<String, dynamic> json) =
      _$TeamDataImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get league; // "Premier" or "National"
  @override
  String get logoUrl;

  /// Create a copy of TeamData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TeamDataImplCopyWith<_$TeamDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
