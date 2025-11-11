/// Signup status enum matching Firestore schema
enum SignupStatus {
  confirmed,
  pending;

  /// Convert to Firestore string
  String toFirestore() => name;

  /// Create from Firestore string
  static SignupStatus fromFirestore(String value) {
    return SignupStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SignupStatus.pending,
    );
  }
}

