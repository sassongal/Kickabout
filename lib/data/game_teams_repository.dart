import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/services/firestore_paths.dart';

/// Repository for managing game teams (teams within a game)
/// This is different from FavoriteTeamsRepository which handles favorite teams selection
class GameTeamsRepository {
  final FirebaseFirestore _firestore;

  GameTeamsRepository(this._firestore);

  /// Get teams for a game
  Future<List<Team>> getTeams(String gameId) async {
    if (!Env.isFirebaseAvailable) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.games())
          .doc(gameId)
          .collection('teams')
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return Team.fromJson({...data, 'teamId': doc.id});
          })
          .toList();
    } catch (e) {
      debugPrint('Error fetching game teams: $e');
      return [];
    }
  }

  /// Stream teams for a game
  Stream<List<Team>> watchTeams(String gameId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.games())
        .doc(gameId)
        .collection('teams')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              return Team.fromJson({...data, 'teamId': doc.id});
            })
            .toList());
  }

  /// Set teams for a game
  Future<void> setTeams(String gameId, List<Team> teams) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final batch = _firestore.batch();
      final teamsCollection = _firestore
          .collection(FirestorePaths.games())
          .doc(gameId)
          .collection('teams');

      // Delete existing teams
      final existingTeams = await teamsCollection.get();
      for (var doc in existingTeams.docs) {
        batch.delete(doc.reference);
      }

      // Add new teams
      for (var team in teams) {
        final data = team.toJson();
        data.remove('teamId'); // Remove teamId from data (it's the document ID)
        final docRef = team.teamId.isNotEmpty
            ? teamsCollection.doc(team.teamId)
            : teamsCollection.doc();
        batch.set(docRef, data);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error setting game teams: $e');
      rethrow;
    }
  }
}

