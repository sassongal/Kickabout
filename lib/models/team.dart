import 'package:freezed_annotation/freezed_annotation.dart';

part 'team.freezed.dart';
part 'team.g.dart';

/// Team model matching Firestore schema: /games/{id}/teams/{teamId}
@freezed
class Team with _$Team {
  const factory Team({
    required String teamId,
    required String name,
    @Default([]) List<String> playerIds,
    @Default(0.0) double totalScore,
    String? color,
  }) = _Team;

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);
}

/// Firestore converter for Team
class TeamConverter implements JsonConverter<Team, Map<String, dynamic>> {
  const TeamConverter();

  @override
  Team fromJson(Map<String, dynamic> json) => Team.fromJson(json);

  @override
  Map<String, dynamic> toJson(Team object) => object.toJson();
}

