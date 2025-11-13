import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/models/converters/timestamp_converter.dart';
import 'package:kickadoor/models/converters/geopoint_converter.dart';

part 'hub.freezed.dart';
part 'hub.g.dart';

/// Hub model matching Firestore schema: /hubs/{hubId}
@freezed
class Hub with _$Hub {
  const factory Hub({
    required String hubId,
    required String name,
    String? description,
    required String createdBy,
    @TimestampConverter() required DateTime createdAt,
    @Default([]) List<String> memberIds,
    @Default({'ratingMode': 'basic'}) Map<String, dynamic> settings,
    @Default({}) Map<String, String> roles, // userId -> role (manager, moderator, member)
    @GeoPointConverter() GeoPoint? location, // Primary location (deprecated, use venues)
    String? geohash,
    double? radius, // radius in km
    @Default([]) List<String> venueIds, // IDs of venues where this hub plays
  }) = _Hub;

  factory Hub.fromJson(Map<String, dynamic> json) => _$HubFromJson(json);
}

/// Firestore converter for Hub
class HubConverter implements JsonConverter<Hub, Map<String, dynamic>> {
  const HubConverter();

  @override
  Hub fromJson(Map<String, dynamic> json) => Hub.fromJson(json);

  @override
  Map<String, dynamic> toJson(Hub object) => object.toJson();
}

