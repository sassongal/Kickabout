/// Game status enum matching Firestore schema
enum GameStatus {
  teamSelection,
  teamsFormed,
  inProgress,
  completed,
  statsInput,
  archivedNotPlayed; // Game was scheduled but never started (auto-closed after 3h)

  /// Convert to Firestore string
  String toFirestore() => name;

  /// Create from Firestore string
  static GameStatus fromFirestore(String value) {
    return GameStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GameStatus.teamSelection,
    );
  }
}

