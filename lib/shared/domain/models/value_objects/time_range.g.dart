// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_range.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TimeRangeImpl _$$TimeRangeImplFromJson(Map<String, dynamic> json) =>
    _$TimeRangeImpl(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
    );

Map<String, dynamic> _$$TimeRangeImplToJson(_$TimeRangeImpl instance) =>
    <String, dynamic>{
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
    };
