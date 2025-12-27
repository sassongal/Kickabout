/// Player position enum for preferred playing position
enum PlayerPosition {
  goalkeeper('Goalkeeper', 'שוער'),
  defender('Defender', 'הגנה'),
  midfielder('Midfielder', 'קשר'),
  attacker('Attacker', 'התקפה');

  final String value;
  final String hebrewLabel;

  const PlayerPosition(this.value, this.hebrewLabel);

  /// Convert to Firestore string (for backward compatibility with User model)
  String toFirestore() => value;

  /// Create from Firestore string
  static PlayerPosition fromString(String? value) {
    if (value == null) return PlayerPosition.midfielder;
    return PlayerPosition.values.firstWhere(
      (pos) => pos.value == value,
      orElse: () => PlayerPosition.midfielder, // Default
    );
  }

  /// Get all positions except midfielder (for Profile Wizard)
  static List<PlayerPosition> get wizardPositions => [
        PlayerPosition.goalkeeper,
        PlayerPosition.defender,
        PlayerPosition.attacker,
      ];
}

