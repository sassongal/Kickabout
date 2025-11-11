import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kickabout/models/converters/timestamp_converter.dart';

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
    @Default({}) Map<String, dynamic> settings,
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

