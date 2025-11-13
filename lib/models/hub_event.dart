import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kickadoor/models/converters/timestamp_converter.dart';
import 'package:kickadoor/models/converters/geopoint_converter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'hub_event.freezed.dart';
part 'hub_event.g.dart';

/// Hub Event model - events created by hub managers (tournaments, training, etc.)
@freezed
class HubEvent with _$HubEvent {
  const factory HubEvent({
    required String eventId,
    required String hubId,
    required String createdBy,
    required String title,
    String? description,
    @TimestampConverter() required DateTime eventDate,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    @Default([]) List<String> registeredPlayerIds, // Players who registered
    @Default('upcoming') String status, // upcoming, ongoing, completed, cancelled
    String? location,
    @GeoPointConverter() GeoPoint? locationPoint,
    String? geohash,
  }) = _HubEvent;

  factory HubEvent.fromJson(Map<String, dynamic> json) => _$HubEventFromJson(json);
}

