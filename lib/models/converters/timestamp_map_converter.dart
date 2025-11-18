import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Timestamp Map converter for Firestore
/// Converts Map<String, Timestamp> to/from Map<String, dynamic>
class TimestampMapConverter implements JsonConverter<Map<String, Timestamp>, Map<String, dynamic>> {
  const TimestampMapConverter();

  @override
  Map<String, Timestamp> fromJson(Map<String, dynamic> json) {
    return json.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value);
      } else if (value is Map) {
        // Firestore Timestamp as map
        final seconds = value['_seconds'] as int?;
        final nanoseconds = value['_nanoseconds'] as int?;
        if (seconds != null) {
          return MapEntry(key, Timestamp(seconds, nanoseconds ?? 0));
        }
      } else if (value is String) {
        // Try to parse as ISO string
        try {
          final dateTime = DateTime.parse(value);
          return MapEntry(key, Timestamp.fromDate(dateTime));
        } catch (e) {
          // Ignore parse errors
        }
      }
      // Return null entry if can't convert (will be filtered out)
      return MapEntry(key, Timestamp.now());
    });
  }

  @override
  Map<String, dynamic> toJson(Map<String, Timestamp> object) {
    return object.map((key, value) => MapEntry(key, value));
  }
}

