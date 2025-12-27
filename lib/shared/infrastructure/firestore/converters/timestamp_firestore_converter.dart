import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Timestamp converter for Firestore
///
/// Converts between DateTime and Firestore Timestamp.
/// Located in infrastructure layer to isolate Firestore dependency.
class TimestampConverter implements JsonConverter<DateTime, Object> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object json) {
    if (json is Timestamp) {
      return json.toDate();
    } else if (json is String) {
      return DateTime.parse(json);
    } else if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    throw ArgumentError('Cannot convert $json to DateTime');
  }

  @override
  Object toJson(DateTime object) => Timestamp.fromDate(object);
}

/// Nullable Timestamp converter for Firestore
class NullableTimestampConverter implements JsonConverter<DateTime?, Object?> {
  const NullableTimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;
    if (json is Timestamp) {
      return json.toDate();
    } else if (json is String) {
      return DateTime.parse(json);
    } else if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    return null;
  }

  @override
  Object? toJson(DateTime? object) =>
      object != null ? Timestamp.fromDate(object) : null;
}
