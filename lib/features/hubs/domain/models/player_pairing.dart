import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/shared/infrastructure/firestore/converters/timestamp_firestore_converter.dart';

part 'player_pairing.freezed.dart';
part 'player_pairing.g.dart';

/// Player pairing model for tracking chemistry between players
///
/// Firestore path: /hubs/{hubId}/pairings/{pairingId}
/// Document ID format: "{player1Id}_{player2Id}" (alphabetically sorted)
///
/// Tracks how often two players play together and their win rate as teammates.
/// Used by team maker algorithm to avoid creating "super pairs" with high win rates.
@freezed
class PlayerPairing with _$PlayerPairing {
  const factory PlayerPairing({
    /// ID of first player (alphabetically first)
    required String player1Id,

    /// ID of second player (alphabetically second)
    required String player2Id,

    /// Total number of games played together on the same team
    @Default(0) int gamesPlayedTogether,

    /// Number of games won together on the same team
    @Default(0) int gamesWonTogether,

    /// Win rate (0.0-1.0) calculated as gamesWonTogether / gamesPlayedTogether
    /// Null if gamesPlayedTogether == 0
    double? winRate,

    /// Timestamp of last game played together
    @TimestampConverter() DateTime? lastPlayedTogether,

    /// Auto-calculated pairing ID (player1Id_player2Id)
    String? pairingId,
  }) = _PlayerPairing;

  factory PlayerPairing.fromJson(Map<String, dynamic> json) =>
      _$PlayerPairingFromJson(json);
}

/// Extension for PlayerPairing calculations
extension PlayerPairingExtensions on PlayerPairing {
  /// Calculate current win rate
  double get effectiveWinRate {
    if (gamesPlayedTogether == 0) return 0.0;
    return gamesWonTogether / gamesPlayedTogether;
  }

  /// Check if this pairing has high chemistry (win rate > 65%)
  bool get hasHighChemistry {
    return effectiveWinRate > 0.65 && gamesPlayedTogether >= 3;
  }

  /// Check if this pairing has low chemistry (win rate < 35%)
  bool get hasLowChemistry {
    return effectiveWinRate < 0.35 && gamesPlayedTogether >= 3;
  }

  /// Get chemistry score (0.0-1.0) for team maker algorithm
  /// Higher score = better chemistry, should be split
  double get chemistryScore {
    if (gamesPlayedTogether < 3) return 0.0; // Not enough data
    return effectiveWinRate;
  }

  /// Create pairing ID from two player IDs (alphabetically sorted)
  static String createPairingId(String playerId1, String playerId2) {
    final sorted = [playerId1, playerId2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Check if this pairing includes a specific player
  bool includesPlayer(String playerId) {
    return player1Id == playerId || player2Id == playerId;
  }

  /// Get the other player ID in the pairing
  String? getOtherPlayer(String playerId) {
    if (player1Id == playerId) return player2Id;
    if (player2Id == playerId) return player1Id;
    return null;
  }
}

/// Factory methods for creating PlayerPairing instances
extension PlayerPairingFactory on PlayerPairing {
  /// Create a new pairing from two player IDs
  static PlayerPairing create({
    required String player1Id,
    required String player2Id,
  }) {
    final sorted = [player1Id, player2Id]..sort();
    final pairingId = PlayerPairingExtensions.createPairingId(player1Id, player2Id);

    return PlayerPairing(
      player1Id: sorted[0],
      player2Id: sorted[1],
      pairingId: pairingId,
    );
  }

  /// Update pairing after a game
  PlayerPairing recordGame({required bool won}) {
    final newGamesPlayed = gamesPlayedTogether + 1;
    final newGamesWon = won ? gamesWonTogether + 1 : gamesWonTogether;
    final newWinRate = newGamesWon / newGamesPlayed;

    return copyWith(
      gamesPlayedTogether: newGamesPlayed,
      gamesWonTogether: newGamesWon,
      winRate: newWinRate,
      lastPlayedTogether: DateTime.now(),
    );
  }
}
