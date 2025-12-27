import 'package:freezed_annotation/freezed_annotation.dart';

part 'pro_team.freezed.dart';
part 'pro_team.g.dart';

/// Professional Team model - represents Israeli football teams
/// Used for user's favorite team selection
@freezed
class ProTeam with _$ProTeam {
  const factory ProTeam({
    required String teamId,
    required String name,
    required String nameEn, // English name for sorting/search
    required String league, // 'premier' or 'national'
    required String logoUrl,
    @Default(true) bool isActive, // For future deactivation if team moves leagues
  }) = _ProTeam;

  factory ProTeam.fromJson(Map<String, dynamic> json) =>
      _$ProTeamFromJson(json);
}

/// Firestore converter for ProTeam
class ProTeamConverter implements JsonConverter<ProTeam, Map<String, dynamic>> {
  const ProTeamConverter();

  @override
  ProTeam fromJson(Map<String, dynamic> json) => ProTeam.fromJson(json);

  @override
  Map<String, dynamic> toJson(ProTeam object) => object.toJson();
}
