// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_audit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GameAudit _$GameAuditFromJson(Map<String, dynamic> json) {
  return _GameAudit.fromJson(json);
}

/// @nodoc
mixin _$GameAudit {
  List<GameAuditEvent> get auditLog => throw _privateConstructorUsedError;

  /// Serializes this GameAudit to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameAudit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameAuditCopyWith<GameAudit> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameAuditCopyWith<$Res> {
  factory $GameAuditCopyWith(GameAudit value, $Res Function(GameAudit) then) =
      _$GameAuditCopyWithImpl<$Res, GameAudit>;
  @useResult
  $Res call({List<GameAuditEvent> auditLog});
}

/// @nodoc
class _$GameAuditCopyWithImpl<$Res, $Val extends GameAudit>
    implements $GameAuditCopyWith<$Res> {
  _$GameAuditCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameAudit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? auditLog = null,
  }) {
    return _then(_value.copyWith(
      auditLog: null == auditLog
          ? _value.auditLog
          : auditLog // ignore: cast_nullable_to_non_nullable
              as List<GameAuditEvent>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GameAuditImplCopyWith<$Res>
    implements $GameAuditCopyWith<$Res> {
  factory _$$GameAuditImplCopyWith(
          _$GameAuditImpl value, $Res Function(_$GameAuditImpl) then) =
      __$$GameAuditImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<GameAuditEvent> auditLog});
}

/// @nodoc
class __$$GameAuditImplCopyWithImpl<$Res>
    extends _$GameAuditCopyWithImpl<$Res, _$GameAuditImpl>
    implements _$$GameAuditImplCopyWith<$Res> {
  __$$GameAuditImplCopyWithImpl(
      _$GameAuditImpl _value, $Res Function(_$GameAuditImpl) _then)
      : super(_value, _then);

  /// Create a copy of GameAudit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? auditLog = null,
  }) {
    return _then(_$GameAuditImpl(
      auditLog: null == auditLog
          ? _value._auditLog
          : auditLog // ignore: cast_nullable_to_non_nullable
              as List<GameAuditEvent>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GameAuditImpl implements _GameAudit {
  const _$GameAuditImpl({final List<GameAuditEvent> auditLog = const []})
      : _auditLog = auditLog;

  factory _$GameAuditImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameAuditImplFromJson(json);

  final List<GameAuditEvent> _auditLog;
  @override
  @JsonKey()
  List<GameAuditEvent> get auditLog {
    if (_auditLog is EqualUnmodifiableListView) return _auditLog;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_auditLog);
  }

  @override
  String toString() {
    return 'GameAudit(auditLog: $auditLog)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameAuditImpl &&
            const DeepCollectionEquality().equals(other._auditLog, _auditLog));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_auditLog));

  /// Create a copy of GameAudit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameAuditImplCopyWith<_$GameAuditImpl> get copyWith =>
      __$$GameAuditImplCopyWithImpl<_$GameAuditImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameAuditImplToJson(
      this,
    );
  }
}

abstract class _GameAudit implements GameAudit {
  const factory _GameAudit({final List<GameAuditEvent> auditLog}) =
      _$GameAuditImpl;

  factory _GameAudit.fromJson(Map<String, dynamic> json) =
      _$GameAuditImpl.fromJson;

  @override
  List<GameAuditEvent> get auditLog;

  /// Create a copy of GameAudit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameAuditImplCopyWith<_$GameAuditImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
