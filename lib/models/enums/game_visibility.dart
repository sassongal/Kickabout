import 'package:json_annotation/json_annotation.dart';

/// Game visibility enum
enum GameVisibility {
  private, // Visible only to Hub members
  public, // Visible to everyone
  recruiting; // Private game that needs players (visible in regional feed)

  /// Convert to Firestore string
  String toFirestore() {
    switch (this) {
      case GameVisibility.private:
        return 'private';
      case GameVisibility.public:
        return 'public';
      case GameVisibility.recruiting:
        return 'recruiting';
    }
  }

  /// Create from Firestore string
  static GameVisibility fromFirestore(String value) {
    switch (value) {
      case 'private':
        return GameVisibility.private;
      case 'public':
        return GameVisibility.public;
      case 'recruiting':
        return GameVisibility.recruiting;
      default:
        return GameVisibility.private; // Default to private
    }
  }
}

/// Converter for GameVisibility
class GameVisibilityConverter implements JsonConverter<GameVisibility, String> {
  const GameVisibilityConverter();

  @override
  GameVisibility fromJson(String json) => GameVisibility.fromFirestore(json);

  @override
  String toJson(GameVisibility object) => object.toFirestore();
}

