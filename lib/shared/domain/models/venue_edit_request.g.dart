// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_edit_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VenueEditRequestImpl _$$VenueEditRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$VenueEditRequestImpl(
      requestId: json['requestId'] as String,
      venueId: json['venueId'] as String,
      userId: json['userId'] as String,
      changes: json['changes'] as Map<String, dynamic>,
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Object),
      status: json['status'] as String? ?? 'pending',
    );

Map<String, dynamic> _$$VenueEditRequestImplToJson(
        _$VenueEditRequestImpl instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'venueId': instance.venueId,
      'userId': instance.userId,
      'changes': instance.changes,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'status': instance.status,
    };
