/// Game status enum matching Firestore schema
enum GameStatus {
  draft, // Incomplete creation
  scheduled, // Future event
  recruiting, // Actively seeking players
  teamSelection, // Existing: Organizing teams
  teamsFormed, // Existing: Teams created
  fullyBooked, // At maximum capacity
  inProgress, // Existing: Game in progress
  completed, // Existing: Game finished
  statsInput, // Existing: Entering stats
  cancelled, // Event cancelled
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
