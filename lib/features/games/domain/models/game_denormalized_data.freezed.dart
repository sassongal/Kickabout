// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_denormalized_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GameDenormalizedData _$GameDenormalizedDataFromJson(Map<String, dynamic> json) {
  return _GameDenormalizedData.fromJson(json);
}

/// @nodoc
mixin _$GameDenormalizedData {
  String? get createdByName => throw _privateConstructorUsedError;
  String? get createdByPhotoUrl => throw _privateConstructorUsedError;
  String? get hubName => throw _privateConstructorUsedError;
  String? get venueName => throw _privateConstructorUsedError;
  List<String> get goalScorerIds => throw _privateConstructorUsedError;
  List<String> get goalScorerNames => throw _privateConstructorUsedError;
  String? get mvpPlayerId => throw _privateConstructorUsedError;
  String? get mvpPlayerName => throw _privateConstructorUsedError;
  List<String> get confirmedPlayerIds => throw _privateConstructorUsedError;
  int get confirmedPlayerCount => throw _privateConstructorUsedError;
  bool get isFull => throw _privateConstructorUsedError;
  int? get maxParticipants => throw _privateConstructorUsedError;

  /// Serializes this GameDenormalizedData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameDenormalizedData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameDenormalizedDataCopyWith<GameDenormalizedData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameDenormalizedDataCopyWith<$Res> {
  factory $GameDenormalizedDataCopyWith(GameDenormalizedData value,
          $Res Function(GameDenormalizedData) then) =
      _$GameDenormalizedDataCopyWithImpl<$Res, GameDenormalizedData>;
  @useResult
  $Res call(
      {String? createdByName,
      String? createdByPhotoUrl,
      String? hubName,
      String? venueName,
      List<String> goalScorerIds,
      List<String> goalScorerNames,
      String? mvpPlayerId,
      String? mvpPlayerName,
      List<String> confirmedPlayerIds,
      int confirmedPlayerCount,
      bool isFull,
      int? maxParticipants});
}

/// @nodoc
class _$GameDenormalizedDataCopyWithImpl<$Res,
        $Val extends GameDenormalizedData>
    implements $GameDenormalizedDataCopyWith<$Res> {
  _$GameDenormalizedDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameDenormalizedData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? createdByName = freezed,
    Object? createdByPhotoUrl = freezed,
    Object? hubName = freezed,
    Object? venueName = freezed,
    Object? goalScorerIds = null,
    Object? goalScorerNames = null,
    Object? mvpPlayerId = freezed,
    Object? mvpPlayerName = freezed,
    Object? confirmedPlayerIds = null,
    Object? confirmedPlayerCount = null,
    Object? isFull = null,
    Object? maxParticipants = freezed,
  }) {
    return _then(_value.copyWith(
      createdByName: freezed == createdByName
          ? _value.createdByName
          : createdByName // ignore: cast_nullable_to_non_nullable
              as String?,
      createdByPhotoUrl: freezed == createdByPhotoUrl
          ? _value.createdByPhotoUrl
          : createdByPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      hubName: freezed == hubName
          ? _value.hubName
          : hubName // ignore: cast_nullable_to_non_nullable
              as String?,
      venueName: freezed == venueName
          ? _value.venueName
          : venueName // ignore: cast_nullable_to_non_nullable
              as String?,
      goalScorerIds: null == goalScorerIds
          ? _value.goalScorerIds
          : goalScorerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      goalScorerNames: null == goalScorerNames
          ? _value.goalScorerNames
          : goalScorerNames // ignore: cast_nullable_to_non_nullable
              as List<String>,
      mvpPlayerId: freezed == mvpPlayerId
          ? _value.mvpPlayerId
          : mvpPlayerId // ignore: cast_nullable_to_non_nullable
              as String?,
      mvpPlayerName: freezed == mvpPlayerName
          ? _value.mvpPlayerName
          : mvpPlayerName // ignore: cast_nullable_to_non_nullable
              as String?,
      confirmedPlayerIds: null == confirmedPlayerIds
          ? _value.confirmedPlayerIds
          : confirmedPlayerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      confirmedPlayerCount: null == confirmedPlayerCount
          ? _value.confirmedPlayerCount
          : confirmedPlayerCount // ignore: cast_nullable_to_non_nullable
              as int,
      isFull: null == isFull
          ? _value.isFull
          : isFull // ignore: cast_nullable_to_non_nullable
              as bool,
      maxParticipants: freezed == maxParticipants
          ? _value.maxParticipants
          : maxParticipants // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GameDenormalizedDataImplCopyWith<$Res>
    implements $GameDenormalizedDataCopyWith<$Res> {
  factory _$$GameDenormalizedDataImplCopyWith(_$GameDenormalizedDataImpl value,
          $Res Function(_$GameDenormalizedDataImpl) then) =
      __$$GameDenormalizedDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? createdByName,
      String? createdByPhotoUrl,
      String? hubName,
      String? venueName,
      List<String> goalScorerIds,
      List<String> goalScorerNames,
      String? mvpPlayerId,
      String? mvpPlayerName,
      List<String> confirmedPlayerIds,
      int confirmedPlayerCount,
      bool isFull,
      int? maxParticipants});
}

/// @nodoc
class __$$GameDenormalizedDataImplCopyWithImpl<$Res>
    extends _$GameDenormalizedDataCopyWithImpl<$Res, _$GameDenormalizedDataImpl>
    implements _$$GameDenormalizedDataImplCopyWith<$Res> {
  __$$GameDenormalizedDataImplCopyWithImpl(_$GameDenormalizedDataImpl _value,
      $Res Function(_$GameDenormalizedDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of GameDenormalizedData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? createdByName = freezed,
    Object? createdByPhotoUrl = freezed,
    Object? hubName = freezed,
    Object? venueName = freezed,
    Object? goalScorerIds = null,
    Object? goalScorerNames = null,
    Object? mvpPlayerId = freezed,
    Object? mvpPlayerName = freezed,
    Object? confirmedPlayerIds = null,
    Object? confirmedPlayerCount = null,
    Object? isFull = null,
    Object? maxParticipants = freezed,
  }) {
    return _then(_$GameDenormalizedDataImpl(
      createdByName: freezed == createdByName
          ? _value.createdByName
          : createdByName // ignore: cast_nullable_to_non_nullable
              as String?,
      createdByPhotoUrl: freezed == createdByPhotoUrl
          ? _value.createdByPhotoUrl
          : createdByPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      hubName: freezed == hubName
          ? _value.hubName
          : hubName // ignore: cast_nullable_to_non_nullable
              as String?,
      venueName: freezed == venueName
          ? _value.venueName
          : venueName // ignore: cast_nullable_to_non_nullable
              as String?,
      goalScorerIds: null == goalScorerIds
          ? _value._goalScorerIds
          : goalScorerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      goalScorerNames: null == goalScorerNames
          ? _value._goalScorerNames
          : goalScorerNames // ignore: cast_nullable_to_non_nullable
              as List<String>,
      mvpPlayerId: freezed == mvpPlayerId
          ? _value.mvpPlayerId
          : mvpPlayerId // ignore: cast_nullable_to_non_nullable
              as String?,
      mvpPlayerName: freezed == mvpPlayerName
          ? _value.mvpPlayerName
          : mvpPlayerName // ignore: cast_nullable_to_non_nullable
              as String?,
      confirmedPlayerIds: null == confirmedPlayerIds
          ? _value._confirmedPlayerIds
          : confirmedPlayerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      confirmedPlayerCount: null == confirmedPlayerCount
          ? _value.confirmedPlayerCount
          : confirmedPlayerCount // ignore: cast_nullable_to_non_nullable
              as int,
      isFull: null == isFull
          ? _value.isFull
          : isFull // ignore: cast_nullable_to_non_nullable
              as bool,
      maxParticipants: freezed == maxParticipants
          ? _value.maxParticipants
          : maxParticipants // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GameDenormalizedDataImpl implements _GameDenormalizedData {
  const _$GameDenormalizedDataImpl(
      {this.createdByName,
      this.createdByPhotoUrl,
      this.hubName,
      this.venueName,
      final List<String> goalScorerIds = const [],
      final List<String> goalScorerNames = const [],
      this.mvpPlayerId,
      this.mvpPlayerName,
      final List<String> confirmedPlayerIds = const [],
      this.confirmedPlayerCount = 0,
      this.isFull = false,
      this.maxParticipants})
      : _goalScorerIds = goalScorerIds,
        _goalScorerNames = goalScorerNames,
        _confirmedPlayerIds = confirmedPlayerIds;

  factory _$GameDenormalizedDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameDenormalizedDataImplFromJson(json);

  @override
  final String? createdByName;
  @override
  final String? createdByPhotoUrl;
  @override
  final String? hubName;
  @override
  final String? venueName;
  final List<String> _goalScorerIds;
  @override
  @JsonKey()
  List<String> get goalScorerIds {
    if (_goalScorerIds is EqualUnmodifiableListView) return _goalScorerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_goalScorerIds);
  }

  final List<String> _goalScorerNames;
  @override
  @JsonKey()
  List<String> get goalScorerNames {
    if (_goalScorerNames is EqualUnmodifiableListView) return _goalScorerNames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_goalScorerNames);
  }

  @override
  final String? mvpPlayerId;
  @override
  final String? mvpPlayerName;
  final List<String> _confirmedPlayerIds;
  @override
  @JsonKey()
  List<String> get confirmedPlayerIds {
    if (_confirmedPlayerIds is EqualUnmodifiableListView)
      return _confirmedPlayerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_confirmedPlayerIds);
  }

  @override
  @JsonKey()
  final int confirmedPlayerCount;
  @override
  @JsonKey()
  final bool isFull;
  @override
  final int? maxParticipants;

  @override
  String toString() {
    return 'GameDenormalizedData(createdByName: $createdByName, createdByPhotoUrl: $createdByPhotoUrl, hubName: $hubName, venueName: $venueName, goalScorerIds: $goalScorerIds, goalScorerNames: $goalScorerNames, mvpPlayerId: $mvpPlayerId, mvpPlayerName: $mvpPlayerName, confirmedPlayerIds: $confirmedPlayerIds, confirmedPlayerCount: $confirmedPlayerCount, isFull: $isFull, maxParticipants: $maxParticipants)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameDenormalizedDataImpl &&
            (identical(other.createdByName, createdByName) ||
                other.createdByName == createdByName) &&
            (identical(other.createdByPhotoUrl, createdByPhotoUrl) ||
                other.createdByPhotoUrl == createdByPhotoUrl) &&
            (identical(other.hubName, hubName) || other.hubName == hubName) &&
            (identical(other.venueName, venueName) ||
                other.venueName == venueName) &&
            const DeepCollectionEquality()
                .equals(other._goalScorerIds, _goalScorerIds) &&
            const DeepCollectionEquality()
                .equals(other._goalScorerNames, _goalScorerNames) &&
            (identical(other.mvpPlayerId, mvpPlayerId) ||
                other.mvpPlayerId == mvpPlayerId) &&
            (identical(other.mvpPlayerName, mvpPlayerName) ||
                other.mvpPlayerName == mvpPlayerName) &&
            const DeepCollectionEquality()
                .equals(other._confirmedPlayerIds, _confirmedPlayerIds) &&
            (identical(other.confirmedPlayerCount, confirmedPlayerCount) ||
                other.confirmedPlayerCount == confirmedPlayerCount) &&
            (identical(other.isFull, isFull) || other.isFull == isFull) &&
            (identical(other.maxParticipants, maxParticipants) ||
                other.maxParticipants == maxParticipants));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      createdByName,
      createdByPhotoUrl,
      hubName,
      venueName,
      const DeepCollectionEquality().hash(_goalScorerIds),
      const DeepCollectionEquality().hash(_goalScorerNames),
      mvpPlayerId,
      mvpPlayerName,
      const DeepCollectionEquality().hash(_confirmedPlayerIds),
      confirmedPlayerCount,
      isFull,
      maxParticipants);

  /// Create a copy of GameDenormalizedData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameDenormalizedDataImplCopyWith<_$GameDenormalizedDataImpl>
      get copyWith =>
          __$$GameDenormalizedDataImplCopyWithImpl<_$GameDenormalizedDataImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameDenormalizedDataImplToJson(
      this,
    );
  }
}

abstract class _GameDenormalizedData implements GameDenormalizedData {
  const factory _GameDenormalizedData(
      {final String? createdByName,
      final String? createdByPhotoUrl,
      final String? hubName,
      final String? venueName,
      final List<String> goalScorerIds,
      final List<String> goalScorerNames,
      final String? mvpPlayerId,
      final String? mvpPlayerName,
      final List<String> confirmedPlayerIds,
      final int confirmedPlayerCount,
      final bool isFull,
      final int? maxParticipants}) = _$GameDenormalizedDataImpl;

  factory _GameDenormalizedData.fromJson(Map<String, dynamic> json) =
      _$GameDenormalizedDataImpl.fromJson;

  @override
  String? get createdByName;
  @override
  String? get createdByPhotoUrl;
  @override
  String? get hubName;
  @override
  String? get venueName;
  @override
  List<String> get goalScorerIds;
  @override
  List<String> get goalScorerNames;
  @override
  String? get mvpPlayerId;
  @override
  String? get mvpPlayerName;
  @override
  List<String> get confirmedPlayerIds;
  @override
  int get confirmedPlayerCount;
  @override
  bool get isFull;
  @override
  int? get maxParticipants;

  /// Create a copy of GameDenormalizedData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameDenormalizedDataImplCopyWith<_$GameDenormalizedDataImpl>
      get copyWith => throw _privateConstructorUsedError;
}
