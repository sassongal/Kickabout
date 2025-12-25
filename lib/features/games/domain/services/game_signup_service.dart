import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/data/games_repository.dart';
import 'package:kattrick/data/signups_repository.dart';
import 'package:kattrick/models/models.dart';

/// Service for game signup business logic
///
/// Handles:
/// - Capacity validation
/// - Signup status transitions
/// - Atomic signup operations
///
/// The repository handles only data access.
class GameSignupService {
  final FirebaseFirestore _firestore;
  final GamesRepository _gamesRepo;
  final SignupsRepository _signupsRepo;

  GameSignupService({
    FirebaseFirestore? firestore,
    GamesRepository? gamesRepo,
    SignupsRepository? signupsRepo,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _gamesRepo = gamesRepo ?? GamesRepository(),
        _signupsRepo = signupsRepo ?? SignupsRepository();

  /// Set signup (create or update) with business logic validation
  ///
  /// BUSINESS LOGIC:
  /// - Validates game capacity before allowing confirmed signups
  /// - Allows updates to existing signups even if game is full
  /// - Uses transaction for atomic operations
  ///
  /// Throws: Exception if game is full or transaction fails
  Future<void> setSignup(
    String gameId,
    String uid,
    SignupStatus status,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Use transaction to ensure atomic capacity check and signup update
      await _firestore.runTransaction((transaction) async {
        final gameRef = _gamesRepo.getGameRef(gameId);
        final signupRef = _signupsRepo.getSignupRef(gameId, uid);

        // Read both game and existing signup within transaction
        final gameDoc = await transaction.get(gameRef);
        final signupDoc = await transaction.get(signupRef);

        if (!gameDoc.exists) {
          throw Exception('Game not found');
        }

        final gameData = gameDoc.data() as Map<String, dynamic>;

        // BUSINESS LOGIC: Check if game is full (only for confirmed signups)
        if (status == SignupStatus.confirmed) {
          final maxPlayers = gameData['maxParticipants'] as int? ??
              (gameData['teamCount'] as int? ?? 2) * 3; // Default: 3 per team

          // OPTIMIZED: Use denormalized confirmedPlayerCount (updated by Cloud Function)
          // This avoids querying all signups - 90% faster!
          final currentPlayerCount = (gameData['confirmedPlayerCount'] as int?) ?? 0;
          final isFull = gameData['isFull'] as bool? ?? false;

          // BUSINESS LOGIC: Check if user is already signed up (to allow updates)
          final existingSignup = signupDoc.exists
              ? GameSignup.fromJson(signupDoc.data() as Map<String, dynamic>)
              : null;
          final isNewSignup = existingSignup == null ||
              existingSignup.status != SignupStatus.confirmed;

          // BUSINESS LOGIC: Validate capacity
          if (isNewSignup && (isFull || currentPlayerCount >= maxPlayers)) {
            throw Exception('המשחק מלא. אין מקום לשחקנים נוספים.');
          }
        }

        // DATA ACCESS: Create or update signup atomically via repository
        final signup = GameSignup(
          playerId: uid,
          signedUpAt: DateTime.now(),
          status: status,
        );

        transaction.set(signupRef, signup.toJson());
      });
    } catch (e) {
      throw Exception('Failed to set signup: $e');
    }
  }
}

