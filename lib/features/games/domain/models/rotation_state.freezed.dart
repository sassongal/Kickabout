// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rotation_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RotationState _$RotationStateFromJson(Map<String, dynamic> json) {
  return _RotationState.fromJson(json);
}

/// @nodoc
mixin _$RotationState {
  /// Team A currently playing (color identifier)
  String get teamAColor => throw _privateConstructorUsedError;

  /// Team B currently playing (color identifier)
  String get teamBColor => throw _privateConstructorUsedError;

  /// Queue of teams waiting to play (ordered by when they rotated out)
  /// Empty for 2-team sessions (no rotation needed)
  List<String> get waitingTeamColors => throw _privateConstructorUsedError;

  /// Current match number in the session (starts at 1)
  int get currentMatchNumber => throw _privateConstructorUsedError;

  /// Map of team colors to their current win streaks
  /// Used for "Streak Breaker" rule: force rotation after 3 consecutive wins
  Map<String, int> get teamWinStreaks => throw _privateConstructorUsedError;

  /// Serializes this RotationState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RotationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RotationStateCopyWith<RotationState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RotationStateCopyWith<$Res> {
  factory $RotationStateCopyWith(
          RotationState value, $Res Function(RotationState) then) =
      _$RotationStateCopyWithImpl<$Res, RotationState>;
  @useResult
  $Res call(
      {String teamAColor,
      String teamBColor,
      List<String> waitingTeamColors,
      int currentMatchNumber,
      Map<String, int> teamWinStreaks});
}

/// @nodoc
class _$RotationStateCopyWithImpl<$Res, $Val extends RotationState>
    implements $RotationStateCopyWith<$Res> {
  _$RotationStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RotationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? teamAColor = null,
    Object? teamBColor = null,
    Object? waitingTeamColors = null,
    Object? currentMatchNumber = null,
    Object? teamWinStreaks = null,
  }) {
    return _then(_value.copyWith(
      teamAColor: null == teamAColor
          ? _value.teamAColor
          : teamAColor // ignore: cast_nullable_to_non_nullable
              as String,
      teamBColor: null == teamBColor
          ? _value.teamBColor
          : teamBColor // ignore: cast_nullable_to_non_nullable
              as String,
      waitingTeamColors: null == waitingTeamColors
          ? _value.waitingTeamColors
          : waitingTeamColors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentMatchNumber: null == currentMatchNumber
          ? _value.currentMatchNumber
          : currentMatchNumber // ignore: cast_nullable_to_non_nullable
              as int,
      teamWinStreaks: null == teamWinStreaks
          ? _value.teamWinStreaks
          : teamWinStreaks // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RotationStateImplCopyWith<$Res>
    implements $RotationStateCopyWith<$Res> {
  factory _$$RotationStateImplCopyWith(
          _$RotationStateImpl value, $Res Function(_$RotationStateImpl) then) =
      __$$RotationStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String teamAColor,
      String teamBColor,
      List<String> waitingTeamColors,
      int currentMatchNumber,
      Map<String, int> teamWinStreaks});
}

/// @nodoc
class __$$RotationStateImplCopyWithImpl<$Res>
    extends _$RotationStateCopyWithImpl<$Res, _$RotationStateImpl>
    implements _$$RotationStateImplCopyWith<$Res> {
  __$$RotationStateImplCopyWithImpl(
      _$RotationStateImpl _value, $Res Function(_$RotationStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of RotationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? teamAColor = null,
    Object? teamBColor = null,
    Object? waitingTeamColors = null,
    Object? currentMatchNumber = null,
    Object? teamWinStreaks = null,
  }) {
    return _then(_$RotationStateImpl(
      teamAColor: null == teamAColor
          ? _value.teamAColor
          : teamAColor // ignore: cast_nullable_to_non_nullable
              as String,
      teamBColor: null == teamBColor
          ? _value.teamBColor
          : teamBColor // ignore: cast_nullable_to_non_nullable
              as String,
      waitingTeamColors: null == waitingTeamColors
          ? _value._waitingTeamColors
          : waitingTeamColors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      currentMatchNumber: null == currentMatchNumber
          ? _value.currentMatchNumber
          : currentMatchNumber // ignore: cast_nullable_to_non_nullable
              as int,
      teamWinStreaks: null == teamWinStreaks
          ? _value._teamWinStreaks
          : teamWinStreaks // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RotationStateImpl implements _RotationState {
  const _$RotationStateImpl(
      {required this.teamAColor,
      required this.teamBColor,
      final List<String> waitingTeamColors = const [],
      this.currentMatchNumber = 1,
      final Map<String, int> teamWinStreaks = const {}})
      : _waitingTeamColors = waitingTeamColors,
        _teamWinStreaks = teamWinStreaks;

  factory _$RotationStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$RotationStateImplFromJson(json);

  /// Team A currently playing (color identifier)
  @override
  final String teamAColor;

  /// Team B currently playing (color identifier)
  @override
  final String teamBColor;

  /// Queue of teams waiting to play (ordered by when they rotated out)
  /// Empty for 2-team sessions (no rotation needed)
  final List<String> _waitingTeamColors;

  /// Queue of teams waiting to play (ordered by when they rotated out)
  /// Empty for 2-team sessions (no rotation needed)
  @override
  @JsonKey()
  List<String> get waitingTeamColors {
    if (_waitingTeamColors is EqualUnmodifiableListView)
      return _waitingTeamColors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_waitingTeamColors);
  }

  /// Current match number in the session (starts at 1)
  @override
  @JsonKey()
  final int currentMatchNumber;

  /// Map of team colors to their current win streaks
  /// Used for "Streak Breaker" rule: force rotation after 3 consecutive wins
  final Map<String, int> _teamWinStreaks;

  /// Map of team colors to their current win streaks
  /// Used for "Streak Breaker" rule: force rotation after 3 consecutive wins
  @override
  @JsonKey()
  Map<String, int> get teamWinStreaks {
    if (_teamWinStreaks is EqualUnmodifiableMapView) return _teamWinStreaks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_teamWinStreaks);
  }

  @override
  String toString() {
    return 'RotationState(teamAColor: $teamAColor, teamBColor: $teamBColor, waitingTeamColors: $waitingTeamColors, currentMatchNumber: $currentMatchNumber, teamWinStreaks: $teamWinStreaks)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RotationStateImpl &&
            (identical(other.teamAColor, teamAColor) ||
                other.teamAColor == teamAColor) &&
            (identical(other.teamBColor, teamBColor) ||
                other.teamBColor == teamBColor) &&
            const DeepCollectionEquality()
                .equals(other._waitingTeamColors, _waitingTeamColors) &&
            (identical(other.currentMatchNumber, currentMatchNumber) ||
                other.currentMatchNumber == currentMatchNumber) &&
            const DeepCollectionEquality()
                .equals(other._teamWinStreaks, _teamWinStreaks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      teamAColor,
      teamBColor,
      const DeepCollectionEquality().hash(_waitingTeamColors),
      currentMatchNumber,
      const DeepCollectionEquality().hash(_teamWinStreaks));

  /// Create a copy of RotationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RotationStateImplCopyWith<_$RotationStateImpl> get copyWith =>
      __$$RotationStateImplCopyWithImpl<_$RotationStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RotationStateImplToJson(
      this,
    );
  }
}

abstract class _RotationState implements RotationState {
  const factory _RotationState(
      {required final String teamAColor,
      required final String teamBColor,
      final List<String> waitingTeamColors,
      final int currentMatchNumber,
      final Map<String, int> teamWinStreaks}) = _$RotationStateImpl;

  factory _RotationState.fromJson(Map<String, dynamic> json) =
      _$RotationStateImpl.fromJson;

  /// Team A currently playing (color identifier)
  @override
  String get teamAColor;

  /// Team B currently playing (color identifier)
  @override
  String get teamBColor;

  /// Queue of teams waiting to play (ordered by when they rotated out)
  /// Empty for 2-team sessions (no rotation needed)
  @override
  List<String> get waitingTeamColors;

  /// Current match number in the session (starts at 1)
  @override
  int get currentMatchNumber;

  /// Map of team colors to their current win streaks
  /// Used for "Streak Breaker" rule: force rotation after 3 consecutive wins
  @override
  Map<String, int> get teamWinStreaks;

  /// Create a copy of RotationState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RotationStateImplCopyWith<_$RotationStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
