class Player {
  final String id;
  final String name;
  final String? photoUrl;
  final double currentRankScore;
  final List<RankingEntry> rankingHistory;
  final PlayerAttributes attributes;
  final DateTime createdAt;
  final int gamesPlayed;
  final double formFactor;
  final double consistencyMultiplier;

  Player({
    required this.id,
    required this.name,
    this.photoUrl,
    this.currentRankScore = 5.0,
    this.rankingHistory = const [],
    required this.attributes,
    required this.createdAt,
    this.gamesPlayed = 0,
    this.formFactor = 1.0,
    this.consistencyMultiplier = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'photoUrl': photoUrl,
    'currentRankScore': currentRankScore,
    'rankingHistory': rankingHistory.map((e) => e.toJson()).toList(),
    'attributes': attributes.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'gamesPlayed': gamesPlayed,
    'formFactor': formFactor,
    'consistencyMultiplier': consistencyMultiplier,
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'],
    name: json['name'],
    photoUrl: json['photoUrl'],
    currentRankScore: json['currentRankScore']?.toDouble() ?? 5.0,
    rankingHistory: (json['rankingHistory'] as List?)
        ?.map((e) => RankingEntry.fromJson(e))
        .toList() ?? [],
    attributes: PlayerAttributes.fromJson(json['attributes'] ?? {}),
    createdAt: DateTime.parse(json['createdAt']),
    gamesPlayed: json['gamesPlayed'] ?? 0,
    formFactor: json['formFactor']?.toDouble() ?? 1.0,
    consistencyMultiplier: json['consistencyMultiplier']?.toDouble() ?? 1.0,
  );

  Player copyWith({
    String? name,
    String? photoUrl,
    double? currentRankScore,
    List<RankingEntry>? rankingHistory,
    PlayerAttributes? attributes,
    int? gamesPlayed,
    double? formFactor,
    double? consistencyMultiplier,
  }) => Player(
    id: id,
    name: name ?? this.name,
    photoUrl: photoUrl ?? this.photoUrl,
    currentRankScore: currentRankScore ?? this.currentRankScore,
    rankingHistory: rankingHistory ?? this.rankingHistory,
    attributes: attributes ?? this.attributes,
    createdAt: createdAt,
    gamesPlayed: gamesPlayed ?? this.gamesPlayed,
    formFactor: formFactor ?? this.formFactor,
    consistencyMultiplier: consistencyMultiplier ?? this.consistencyMultiplier,
  );
  
  String get overallGrade {
    final score = currentRankScore;
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
  
  bool get isImproving {
    if (rankingHistory.length < 3) return false;
    final recent = rankingHistory.take(3).toList();
    return recent[0].rankScore > recent[2].rankScore;
  }
  
  bool get isInForm {
    return formFactor > 1.05;
  }
}

class RankingEntry {
  final DateTime date;
  final double rankScore;

  RankingEntry({required this.date, required this.rankScore});

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'rankScore': rankScore,
  };

  factory RankingEntry.fromJson(Map<String, dynamic> json) => RankingEntry(
    date: DateTime.parse(json['date']),
    rankScore: json['rankScore'].toDouble(),
  );
}

class PlayerAttributes {
  final String preferredPosition;
  final int speed;
  final int strength;

  PlayerAttributes({
    this.preferredPosition = 'Midfielder',
    this.speed = 5,
    this.strength = 5,
  });

  Map<String, dynamic> toJson() => {
    'preferredPosition': preferredPosition,
    'speed': speed,
    'strength': strength,
  };

  factory PlayerAttributes.fromJson(Map<String, dynamic> json) => PlayerAttributes(
    preferredPosition: json['preferredPosition'] ?? 'Midfielder',
    speed: json['speed'] ?? 5,
    strength: json['strength'] ?? 5,
  );
}