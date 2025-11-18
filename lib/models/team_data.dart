import 'package:freezed_annotation/freezed_annotation.dart';

part 'team_data.freezed.dart';
part 'team_data.g.dart';

/// Team data model for favorite teams selection
@freezed
class TeamData with _$TeamData {
  const factory TeamData({
    @Default('') String id,
    required String name,
    required String league, // "Premier" or "National"
    required String logoUrl,
  }) = _TeamData;

  factory TeamData.fromJson(Map<String, dynamic> json) => _$TeamDataFromJson(json);
}

