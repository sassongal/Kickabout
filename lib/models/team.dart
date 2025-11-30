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
    String? color, // Color name (e.g., "Blue", "Red", "Green")
    int? colorValue, // Flashy neon color value (0xFFFF0000 for red, etc.)
    @Default(0) int wins, // Transient field for session wins (aggregated from matches)
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

/// Firestore converter for List<Team>
class TeamListConverter implements JsonConverter<List<Team>, List<dynamic>> {
  const TeamListConverter();

  @override
  List<Team> fromJson(List<dynamic> json) {
    return json.map((e) => Team.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  List<dynamic> toJson(List<Team> object) {
    return object.map((e) => e.toJson()).toList();
  }
}

