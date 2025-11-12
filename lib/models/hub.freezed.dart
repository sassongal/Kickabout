// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hub.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Hub _$HubFromJson(Map<String, dynamic> json) {
  return _Hub.fromJson(json);
}

/// @nodoc
mixin _$Hub {
  String get hubId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  List<String> get memberIds => throw _privateConstructorUsedError;
  Map<String, dynamic> get settings => throw _privateConstructorUsedError;

  /// Serializes this Hub to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Hub
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HubCopyWith<Hub> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HubCopyWith<$Res> {
  factory $HubCopyWith(Hub value, $Res Function(Hub) then) =
      _$HubCopyWithImpl<$Res, Hub>;
  @useResult
  $Res call(
      {String hubId,
      String name,
      String? description,
      String createdBy,
      @TimestampConverter() DateTime createdAt,
      List<String> memberIds,
      Map<String, dynamic> settings});
}

/// @nodoc
class _$HubCopyWithImpl<$Res, $Val extends Hub> implements $HubCopyWith<$Res> {
  _$HubCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Hub
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hubId = null,
    Object? name = null,
    Object? description = freezed,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? memberIds = null,
    Object? settings = null,
  }) {
    return _then(_value.copyWith(
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
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      memberIds: null == memberIds
          ? _value.memberIds
          : memberIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      settings: null == settings
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HubImplCopyWith<$Res> implements $HubCopyWith<$Res> {
  factory _$$HubImplCopyWith(_$HubImpl value, $Res Function(_$HubImpl) then) =
      __$$HubImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String hubId,
      String name,
      String? description,
      String createdBy,
      @TimestampConverter() DateTime createdAt,
      List<String> memberIds,
      Map<String, dynamic> settings});
}

/// @nodoc
class __$$HubImplCopyWithImpl<$Res> extends _$HubCopyWithImpl<$Res, _$HubImpl>
    implements _$$HubImplCopyWith<$Res> {
  __$$HubImplCopyWithImpl(_$HubImpl _value, $Res Function(_$HubImpl) _then)
      : super(_value, _then);

  /// Create a copy of Hub
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hubId = null,
    Object? name = null,
    Object? description = freezed,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? memberIds = null,
    Object? settings = null,
  }) {
    return _then(_$HubImpl(
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
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      memberIds: null == memberIds
          ? _value._memberIds
          : memberIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      settings: null == settings
          ? _value._settings
          : settings // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HubImpl implements _Hub {
  const _$HubImpl(
      {required this.hubId,
      required this.name,
      this.description,
      required this.createdBy,
      @TimestampConverter() required this.createdAt,
      final List<String> memberIds = const [],
      final Map<String, dynamic> settings = const {'ratingMode': 'basic'}})
      : _memberIds = memberIds,
        _settings = settings;

  factory _$HubImpl.fromJson(Map<String, dynamic> json) =>
      _$$HubImplFromJson(json);

  @override
  final String hubId;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String createdBy;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  final List<String> _memberIds;
  @override
  @JsonKey()
  List<String> get memberIds {
    if (_memberIds is EqualUnmodifiableListView) return _memberIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_memberIds);
  }

  final Map<String, dynamic> _settings;
  @override
  @JsonKey()
  Map<String, dynamic> get settings {
    if (_settings is EqualUnmodifiableMapView) return _settings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_settings);
  }

  @override
  String toString() {
    return 'Hub(hubId: $hubId, name: $name, description: $description, createdBy: $createdBy, createdAt: $createdAt, memberIds: $memberIds, settings: $settings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HubImpl &&
            (identical(other.hubId, hubId) || other.hubId == hubId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality()
                .equals(other._memberIds, _memberIds) &&
            const DeepCollectionEquality().equals(other._settings, _settings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      hubId,
      name,
      description,
      createdBy,
      createdAt,
      const DeepCollectionEquality().hash(_memberIds),
      const DeepCollectionEquality().hash(_settings));

  /// Create a copy of Hub
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HubImplCopyWith<_$HubImpl> get copyWith =>
      __$$HubImplCopyWithImpl<_$HubImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HubImplToJson(
      this,
    );
  }
}

abstract class _Hub implements Hub {
  const factory _Hub(
      {required final String hubId,
      required final String name,
      final String? description,
      required final String createdBy,
      @TimestampConverter() required final DateTime createdAt,
      final List<String> memberIds,
      final Map<String, dynamic> settings}) = _$HubImpl;

  factory _Hub.fromJson(Map<String, dynamic> json) = _$HubImpl.fromJson;

  @override
  String get hubId;
  @override
  String get name;
  @override
  String? get description;
  @override
  String get createdBy;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  List<String> get memberIds;
  @override
  Map<String, dynamic> get settings;

  /// Create a copy of Hub
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HubImplCopyWith<_$HubImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
