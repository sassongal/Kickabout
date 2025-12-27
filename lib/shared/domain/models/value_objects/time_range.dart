import 'package:freezed_annotation/freezed_annotation.dart';

part 'time_range.freezed.dart';
part 'time_range.g.dart';

/// Time range value object - represents a period between two timestamps
///
/// Replaces primitive DateTime pairs with a proper domain type that enforces
/// invariants and provides business logic.
@freezed
class TimeRange with _$TimeRange {
  const factory TimeRange({
    required DateTime start,
    required DateTime end,
  }) = _TimeRange;

  const TimeRange._();

  factory TimeRange.fromJson(Map<String, dynamic> json) =>
      _$TimeRangeFromJson(json);

  /// Create from validated start and end times
  factory TimeRange.fromStartEnd({
    required DateTime start,
    required DateTime end,
  }) {
    if (end.isBefore(start)) {
      throw ArgumentError('End time must be after start time');
    }
    return TimeRange(start: start, end: end);
  }

  /// Create a time range from a start time and duration
  factory TimeRange.fromStartDuration({
    required DateTime start,
    required Duration duration,
  }) {
    if (duration.isNegative) {
      throw ArgumentError('Duration cannot be negative');
    }
    return TimeRange(
      start: start,
      end: start.add(duration),
    );
  }

  // ============================================================================
  // BUSINESS LOGIC
  // ============================================================================

  /// Duration of this time range
  Duration get duration => end.difference(start);

  /// Duration in minutes
  int get durationMinutes => duration.inMinutes;

  /// Duration in hours (fractional)
  double get durationHours => duration.inMinutes / 60.0;

  /// Check if this range is currently active (now is between start and end)
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  /// Check if this range is in the past
  bool get isPast => end.isBefore(DateTime.now());

  /// Check if this range is in the future
  bool get isFuture => start.isAfter(DateTime.now());

  /// Check if this range is upcoming (starts within the next duration)
  bool isUpcoming(Duration within) {
    final now = DateTime.now();
    final threshold = now.add(within);
    return start.isAfter(now) && start.isBefore(threshold);
  }

  /// Check if this range overlaps with another
  bool overlaps(TimeRange other) {
    return start.isBefore(other.end) && end.isAfter(other.start);
  }

  /// Check if this range contains a specific time
  bool contains(DateTime time) {
    return time.isAfter(start) && time.isBefore(end);
  }

  /// Check if this range fully contains another range
  bool fullyContains(TimeRange other) {
    return start.isBefore(other.start) && end.isAfter(other.end);
  }

  /// Calculate overlap duration with another range
  Duration? overlapDuration(TimeRange other) {
    if (!overlaps(other)) return null;

    final overlapStart = start.isAfter(other.start) ? start : other.start;
    final overlapEnd = end.isBefore(other.end) ? end : other.end;

    return overlapEnd.difference(overlapStart);
  }

  /// Create a new range shifted by a duration
  TimeRange shift(Duration duration) {
    return TimeRange(
      start: start.add(duration),
      end: end.add(duration),
    );
  }

  /// Create a new range extended by a duration
  TimeRange extend(Duration duration) {
    return TimeRange(
      start: start,
      end: end.add(duration),
    );
  }

  /// Create a new range with a different duration but same start
  TimeRange withDuration(Duration duration) {
    return TimeRange(
      start: start,
      end: start.add(duration),
    );
  }

  // ============================================================================
  // VALIDATION
  // ============================================================================

  /// Check if this is a valid time range
  bool get isValid => !end.isBefore(start);

  /// Time until the range starts (null if already started)
  Duration? get timeUntilStart {
    final now = DateTime.now();
    if (start.isBefore(now)) return null;
    return start.difference(now);
  }

  /// Time until the range ends (null if already ended)
  Duration? get timeUntilEnd {
    final now = DateTime.now();
    if (end.isBefore(now)) return null;
    return end.difference(now);
  }
}
