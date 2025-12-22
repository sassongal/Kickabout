/// PlayerStats represents objective game performance data ONLY.
///
/// This is a LOG of what happened in a specific game - not a skill assessment.
/// All subjective attributes (defense, passing, shooting, etc.) have been removed.
///
/// For team balancing, use HubMember.managerRating instead.
class PlayerStats {
  final String playerId;
  final String gameId;

  // Objective stats only
  final int goals;
  final int assists;
  final bool isMvp; // Was this player voted MVP?

  // Metadata
  final bool isVerified;
  final String? submittedBy;
  final DateTime? gameDate;

  PlayerStats({
    required this.playerId,
    required this.gameId,
    this.goals = 0,
    this.assists = 0,
    this.isMvp = false,
    this.isVerified = false,
    this.submittedBy,
    this.gameDate,
  });

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'gameId': gameId,
    'goals': goals,
    'assists': assists,
    'isMvp': isMvp,
    'isVerified': isVerified,
    'submittedBy': submittedBy,
    'gameDate': gameDate?.toIso8601String(),
  };

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
    playerId: json['playerId'] as String,
    gameId: json['gameId'] as String,
    goals: json['goals'] as int? ?? 0,
    assists: json['assists'] as int? ?? 0,
    isMvp: json['isMvp'] as bool? ?? false,
    isVerified: json['isVerified'] as bool? ?? false,
    submittedBy: json['submittedBy'] as String?,
    gameDate: json['gameDate'] != null
        ? DateTime.parse(json['gameDate'] as String)
        : null,
  );

  PlayerStats copyWith({
    int? goals,
    int? assists,
    bool? isMvp,
    bool? isVerified,
    String? submittedBy,
    DateTime? gameDate,
  }) => PlayerStats(
    playerId: playerId,
    gameId: gameId,
    goals: goals ?? this.goals,
    assists: assists ?? this.assists,
    isMvp: isMvp ?? this.isMvp,
    isVerified: isVerified ?? this.isVerified,
    submittedBy: submittedBy ?? this.submittedBy,
    gameDate: gameDate ?? this.gameDate,
  );

  /// Total contribution to the game (goals + assists)
  int get totalContribution => goals + assists;
}
