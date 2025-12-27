// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'time_range.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TimeRange _$TimeRangeFromJson(Map<String, dynamic> json) {
  return _TimeRange.fromJson(json);
}

/// @nodoc
mixin _$TimeRange {
  DateTime get start => throw _privateConstructorUsedError;
  DateTime get end => throw _privateConstructorUsedError;

  /// Serializes this TimeRange to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TimeRange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TimeRangeCopyWith<TimeRange> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimeRangeCopyWith<$Res> {
  factory $TimeRangeCopyWith(TimeRange value, $Res Function(TimeRange) then) =
      _$TimeRangeCopyWithImpl<$Res, TimeRange>;
  @useResult
  $Res call({DateTime start, DateTime end});
}

/// @nodoc
class _$TimeRangeCopyWithImpl<$Res, $Val extends TimeRange>
    implements $TimeRangeCopyWith<$Res> {
  _$TimeRangeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TimeRange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? start = null,
    Object? end = null,
  }) {
    return _then(_value.copyWith(
      start: null == start
          ? _value.start
          : start // ignore: cast_nullable_to_non_nullable
              as DateTime,
      end: null == end
          ? _value.end
          : end // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TimeRangeImplCopyWith<$Res>
    implements $TimeRangeCopyWith<$Res> {
  factory _$$TimeRangeImplCopyWith(
          _$TimeRangeImpl value, $Res Function(_$TimeRangeImpl) then) =
      __$$TimeRangeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime start, DateTime end});
}

/// @nodoc
class __$$TimeRangeImplCopyWithImpl<$Res>
    extends _$TimeRangeCopyWithImpl<$Res, _$TimeRangeImpl>
    implements _$$TimeRangeImplCopyWith<$Res> {
  __$$TimeRangeImplCopyWithImpl(
      _$TimeRangeImpl _value, $Res Function(_$TimeRangeImpl) _then)
      : super(_value, _then);

  /// Create a copy of TimeRange
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? start = null,
    Object? end = null,
  }) {
    return _then(_$TimeRangeImpl(
      start: null == start
          ? _value.start
          : start // ignore: cast_nullable_to_non_nullable
              as DateTime,
      end: null == end
          ? _value.end
          : end // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TimeRangeImpl extends _TimeRange {
  const _$TimeRangeImpl({required this.start, required this.end}) : super._();

  factory _$TimeRangeImpl.fromJson(Map<String, dynamic> json) =>
      _$$TimeRangeImplFromJson(json);

  @override
  final DateTime start;
  @override
  final DateTime end;

  @override
  String toString() {
    return 'TimeRange(start: $start, end: $end)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimeRangeImpl &&
            (identical(other.start, start) || other.start == start) &&
            (identical(other.end, end) || other.end == end));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, start, end);

  /// Create a copy of TimeRange
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TimeRangeImplCopyWith<_$TimeRangeImpl> get copyWith =>
      __$$TimeRangeImplCopyWithImpl<_$TimeRangeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TimeRangeImplToJson(
      this,
    );
  }
}

abstract class _TimeRange extends TimeRange {
  const factory _TimeRange(
      {required final DateTime start,
      required final DateTime end}) = _$TimeRangeImpl;
  const _TimeRange._() : super._();

  factory _TimeRange.fromJson(Map<String, dynamic> json) =
      _$TimeRangeImpl.fromJson;

  @override
  DateTime get start;
  @override
  DateTime get end;

  /// Create a copy of TimeRange
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TimeRangeImplCopyWith<_$TimeRangeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
