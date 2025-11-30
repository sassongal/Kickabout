import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/models/converters/timestamp_converter.dart';

part 'venue_edit_request.freezed.dart';
part 'venue_edit_request.g.dart';

@freezed
class VenueEditRequest with _$VenueEditRequest {
  const factory VenueEditRequest({
    required String requestId,
    required String venueId,
    required String userId,
    required Map<String, dynamic> changes,
    @TimestampConverter() required DateTime createdAt,
    @Default('pending') String status, // pending, approved, rejected
  }) = _VenueEditRequest;

  factory VenueEditRequest.fromJson(Map<String, dynamic> json) =>
      _$VenueEditRequestFromJson(json);
}
