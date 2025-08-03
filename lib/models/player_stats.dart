class PlayerStats {
  final String playerId;
  final String gameId;
  final double defense;
  final double passing;
  final double shooting;
  final double dribbling;
  final double physical;
  final double leadership;
  final double teamPlay;
  final double consistency;
  final bool isVerified;
  final String? submittedBy;
  final DateTime? gameDate;

  PlayerStats({
    required this.playerId,
    required this.gameId,
    required this.defense,
    required this.passing,
    required this.shooting,
    required this.dribbling,
    required this.physical,
    required this.leadership,
    required this.teamPlay,
    required this.consistency,
    this.isVerified = false,
    this.submittedBy,
    this.gameDate,
  });

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'gameId': gameId,
    'defense': defense,
    'passing': passing,
    'shooting': shooting,
    'dribbling': dribbling,
    'physical': physical,
    'leadership': leadership,
    'teamPlay': teamPlay,
    'consistency': consistency,
    'isVerified': isVerified,
    'submittedBy': submittedBy,
    'gameDate': gameDate?.toIso8601String(),
  };

  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
    playerId: json['playerId'],
    gameId: json['gameId'],
    defense: json['defense'].toDouble(),
    passing: json['passing'].toDouble(),
    shooting: json['shooting'].toDouble(),
    dribbling: json['dribbling']?.toDouble() ?? json['lackOfErrors']?.toDouble() ?? 5.0,
    physical: json['physical']?.toDouble() ?? 5.0,
    leadership: json['leadership'].toDouble(),
    teamPlay: json['teamPlay'].toDouble(),
    consistency: json['consistency']?.toDouble() ?? 5.0,
    isVerified: json['isVerified'] ?? false,
    submittedBy: json['submittedBy'],
    gameDate: json['gameDate'] != null ? DateTime.parse(json['gameDate']) : null,
  );

  double get complexScore => calculatePositionScore('Midfielder');
  
  double calculatePositionScore(String position) {
    final weights = getPositionWeights(position);
    
    return (weights['defense']! * defense) +
           (weights['passing']! * passing) +
           (weights['shooting']! * shooting) +
           (weights['dribbling']! * dribbling) +
           (weights['physical']! * physical) +
           (weights['leadership']! * leadership) +
           (weights['teamPlay']! * teamPlay) +
           (weights['consistency']! * consistency);
  }
  
  static Map<String, double> getPositionWeights(String position) {
    switch (position.toLowerCase()) {
      case 'goalkeeper':
      case 'keeper':
        return {
          'defense': 0.25,
          'passing': 0.15,
          'shooting': 0.05,
          'dribbling': 0.05,
          'physical': 0.20,
          'leadership': 0.15,
          'teamPlay': 0.10,
          'consistency': 0.05,
        };
      case 'defender':
      case 'centre-back':
      case 'fullback':
        return {
          'defense': 0.30,
          'passing': 0.15,
          'shooting': 0.05,
          'dribbling': 0.10,
          'physical': 0.20,
          'leadership': 0.10,
          'teamPlay': 0.15,
          'consistency': 0.15,
        };
      case 'midfielder':
      case 'central midfielder':
      case 'attacking midfielder':
        return {
          'defense': 0.15,
          'passing': 0.25,
          'shooting': 0.15,
          'dribbling': 0.15,
          'physical': 0.10,
          'leadership': 0.10,
          'teamPlay': 0.20,
          'consistency': 0.10,
        };
      case 'winger':
      case 'wing':
        return {
          'defense': 0.10,
          'passing': 0.15,
          'shooting': 0.20,
          'dribbling': 0.25,
          'physical': 0.15,
          'leadership': 0.05,
          'teamPlay': 0.15,
          'consistency': 0.05,
        };
      case 'forward':
      case 'striker':
      case 'centre-forward':
        return {
          'defense': 0.05,
          'passing': 0.10,
          'shooting': 0.35,
          'dribbling': 0.20,
          'physical': 0.15,
          'leadership': 0.05,
          'teamPlay': 0.15,
          'consistency': 0.10,
        };
      default:
        return {
          'defense': 0.125,
          'passing': 0.175,
          'shooting': 0.175,
          'dribbling': 0.15,
          'physical': 0.125,
          'leadership': 0.10,
          'teamPlay': 0.175,
          'consistency': 0.125,
        };
    }
  }
  
  List<double> get attributesList => [defense, passing, shooting, dribbling, physical, leadership, teamPlay, consistency];
  
  static List<String> get attributeNames => ['Defense', 'Passing', 'Shooting', 'Dribbling', 'Physical', 'Leadership', 'Team Play', 'Consistency'];
  
  String get overallGrade {
    final score = complexScore;
    if (score >= 9.0) return 'S';
    if (score >= 8.5) return 'A+';
    if (score >= 8.0) return 'A';
    if (score >= 7.5) return 'A-';
    if (score >= 7.0) return 'B+';
    if (score >= 6.5) return 'B';
    if (score >= 6.0) return 'B-';
    if (score >= 5.5) return 'C+';
    if (score >= 5.0) return 'C';
    if (score >= 4.5) return 'C-';
    if (score >= 4.0) return 'D';
    return 'F';
  }

  PlayerStats copyWith({
    double? defense,
    double? passing,
    double? shooting,
    double? dribbling,
    double? physical,
    double? leadership,
    double? teamPlay,
    double? consistency,
    bool? isVerified,
    String? submittedBy,
    DateTime? gameDate,
  }) => PlayerStats(
    playerId: playerId,
    gameId: gameId,
    defense: defense ?? this.defense,
    passing: passing ?? this.passing,
    shooting: shooting ?? this.shooting,
    dribbling: dribbling ?? this.dribbling,
    physical: physical ?? this.physical,
    leadership: leadership ?? this.leadership,
    teamPlay: teamPlay ?? this.teamPlay,
    consistency: consistency ?? this.consistency,
    isVerified: isVerified ?? this.isVerified,
    submittedBy: submittedBy ?? this.submittedBy,
    gameDate: gameDate ?? this.gameDate,
  );
}