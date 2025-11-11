/// Game event type enum matching Firestore schema
enum EventType {
  goal,
  assist,
  save,
  card,
  mvpVote;

  /// Convert to Firestore string
  String toFirestore() => name;

  /// Create from Firestore string
  static EventType fromFirestore(String value) {
    return EventType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EventType.goal,
    );
  }
}

