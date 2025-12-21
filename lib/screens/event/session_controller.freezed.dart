// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SessionState {
  /// Current scores for teams in active match
  /// Key: team color, Value: score
  Map<String, int> get currentScores => throw _privateConstructorUsedError;

  /// Whether a match is being submitted
  bool get isSubmitting => throw _privateConstructorUsedError;

  /// Match that ended in a tie, awaiting manager selection
  MatchResult? get pendingTieMatch => throw _privateConstructorUsedError;

  /// Team color selected by manager for tie resolution
  String? get managerSelectedStayingTeam => throw _privateConstructorUsedError;

  /// Whether to show tie selection dialog
  bool get showTieDialog => throw _privateConstructorUsedError;

  /// Error message if any
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of SessionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SessionStateCopyWith<SessionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionStateCopyWith<$Res> {
  factory $SessionStateCopyWith(
          SessionState value, $Res Function(SessionState) then) =
      _$SessionStateCopyWithImpl<$Res, SessionState>;
  @useResult
  $Res call(
      {Map<String, int> currentScores,
      bool isSubmitting,
      MatchResult? pendingTieMatch,
      String? managerSelectedStayingTeam,
      bool showTieDialog,
      String? errorMessage});

  $MatchResultCopyWith<$Res>? get pendingTieMatch;
}

/// @nodoc
class _$SessionStateCopyWithImpl<$Res, $Val extends SessionState>
    implements $SessionStateCopyWith<$Res> {
  _$SessionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SessionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentScores = null,
    Object? isSubmitting = null,
    Object? pendingTieMatch = freezed,
    Object? managerSelectedStayingTeam = freezed,
    Object? showTieDialog = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      currentScores: null == currentScores
          ? _value.currentScores
          : currentScores // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      isSubmitting: null == isSubmitting
          ? _value.isSubmitting
          : isSubmitting // ignore: cast_nullable_to_non_nullable
              as bool,
      pendingTieMatch: freezed == pendingTieMatch
          ? _value.pendingTieMatch
          : pendingTieMatch // ignore: cast_nullable_to_non_nullable
              as MatchResult?,
      managerSelectedStayingTeam: freezed == managerSelectedStayingTeam
          ? _value.managerSelectedStayingTeam
          : managerSelectedStayingTeam // ignore: cast_nullable_to_non_nullable
              as String?,
      showTieDialog: null == showTieDialog
          ? _value.showTieDialog
          : showTieDialog // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of SessionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MatchResultCopyWith<$Res>? get pendingTieMatch {
    if (_value.pendingTieMatch == null) {
      return null;
    }

    return $MatchResultCopyWith<$Res>(_value.pendingTieMatch!, (value) {
      return _then(_value.copyWith(pendingTieMatch: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SessionStateImplCopyWith<$Res>
    implements $SessionStateCopyWith<$Res> {
  factory _$$SessionStateImplCopyWith(
          _$SessionStateImpl value, $Res Function(_$SessionStateImpl) then) =
      __$$SessionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Map<String, int> currentScores,
      bool isSubmitting,
      MatchResult? pendingTieMatch,
      String? managerSelectedStayingTeam,
      bool showTieDialog,
      String? errorMessage});

  @override
  $MatchResultCopyWith<$Res>? get pendingTieMatch;
}

/// @nodoc
class __$$SessionStateImplCopyWithImpl<$Res>
    extends _$SessionStateCopyWithImpl<$Res, _$SessionStateImpl>
    implements _$$SessionStateImplCopyWith<$Res> {
  __$$SessionStateImplCopyWithImpl(
      _$SessionStateImpl _value, $Res Function(_$SessionStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of SessionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentScores = null,
    Object? isSubmitting = null,
    Object? pendingTieMatch = freezed,
    Object? managerSelectedStayingTeam = freezed,
    Object? showTieDialog = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_$SessionStateImpl(
      currentScores: null == currentScores
          ? _value._currentScores
          : currentScores // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      isSubmitting: null == isSubmitting
          ? _value.isSubmitting
          : isSubmitting // ignore: cast_nullable_to_non_nullable
              as bool,
      pendingTieMatch: freezed == pendingTieMatch
          ? _value.pendingTieMatch
          : pendingTieMatch // ignore: cast_nullable_to_non_nullable
              as MatchResult?,
      managerSelectedStayingTeam: freezed == managerSelectedStayingTeam
          ? _value.managerSelectedStayingTeam
          : managerSelectedStayingTeam // ignore: cast_nullable_to_non_nullable
              as String?,
      showTieDialog: null == showTieDialog
          ? _value.showTieDialog
          : showTieDialog // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$SessionStateImpl with DiagnosticableTreeMixin implements _SessionState {
  const _$SessionStateImpl(
      {final Map<String, int> currentScores = const {},
      this.isSubmitting = false,
      this.pendingTieMatch,
      this.managerSelectedStayingTeam,
      this.showTieDialog = false,
      this.errorMessage})
      : _currentScores = currentScores;

  /// Current scores for teams in active match
  /// Key: team color, Value: score
  final Map<String, int> _currentScores;

  /// Current scores for teams in active match
  /// Key: team color, Value: score
  @override
  @JsonKey()
  Map<String, int> get currentScores {
    if (_currentScores is EqualUnmodifiableMapView) return _currentScores;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_currentScores);
  }

  /// Whether a match is being submitted
  @override
  @JsonKey()
  final bool isSubmitting;

  /// Match that ended in a tie, awaiting manager selection
  @override
  final MatchResult? pendingTieMatch;

  /// Team color selected by manager for tie resolution
  @override
  final String? managerSelectedStayingTeam;

  /// Whether to show tie selection dialog
  @override
  @JsonKey()
  final bool showTieDialog;

  /// Error message if any
  @override
  final String? errorMessage;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'SessionState(currentScores: $currentScores, isSubmitting: $isSubmitting, pendingTieMatch: $pendingTieMatch, managerSelectedStayingTeam: $managerSelectedStayingTeam, showTieDialog: $showTieDialog, errorMessage: $errorMessage)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'SessionState'))
      ..add(DiagnosticsProperty('currentScores', currentScores))
      ..add(DiagnosticsProperty('isSubmitting', isSubmitting))
      ..add(DiagnosticsProperty('pendingTieMatch', pendingTieMatch))
      ..add(DiagnosticsProperty(
          'managerSelectedStayingTeam', managerSelectedStayingTeam))
      ..add(DiagnosticsProperty('showTieDialog', showTieDialog))
      ..add(DiagnosticsProperty('errorMessage', errorMessage));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionStateImpl &&
            const DeepCollectionEquality()
                .equals(other._currentScores, _currentScores) &&
            (identical(other.isSubmitting, isSubmitting) ||
                other.isSubmitting == isSubmitting) &&
            (identical(other.pendingTieMatch, pendingTieMatch) ||
                other.pendingTieMatch == pendingTieMatch) &&
            (identical(other.managerSelectedStayingTeam,
                    managerSelectedStayingTeam) ||
                other.managerSelectedStayingTeam ==
                    managerSelectedStayingTeam) &&
            (identical(other.showTieDialog, showTieDialog) ||
                other.showTieDialog == showTieDialog) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_currentScores),
      isSubmitting,
      pendingTieMatch,
      managerSelectedStayingTeam,
      showTieDialog,
      errorMessage);

  /// Create a copy of SessionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionStateImplCopyWith<_$SessionStateImpl> get copyWith =>
      __$$SessionStateImplCopyWithImpl<_$SessionStateImpl>(this, _$identity);
}

abstract class _SessionState implements SessionState {
  const factory _SessionState(
      {final Map<String, int> currentScores,
      final bool isSubmitting,
      final MatchResult? pendingTieMatch,
      final String? managerSelectedStayingTeam,
      final bool showTieDialog,
      final String? errorMessage}) = _$SessionStateImpl;

  /// Current scores for teams in active match
  /// Key: team color, Value: score
  @override
  Map<String, int> get currentScores;

  /// Whether a match is being submitted
  @override
  bool get isSubmitting;

  /// Match that ended in a tie, awaiting manager selection
  @override
  MatchResult? get pendingTieMatch;

  /// Team color selected by manager for tie resolution
  @override
  String? get managerSelectedStayingTeam;

  /// Whether to show tie selection dialog
  @override
  bool get showTieDialog;

  /// Error message if any
  @override
  String? get errorMessage;

  /// Create a copy of SessionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SessionStateImplCopyWith<_$SessionStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
