/// Signup status enum matching Firestore schema
enum SignupStatus {
  pending, // Initial state
  pendingApproval, // Awaiting admin approval (for public games)
  confirmed, // Approved and confirmed
  rejected, // Denied by admin (with reason)
  waitlist, // On waiting list
  cancelled; // Player cancelled their signup

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
