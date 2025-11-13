import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/services/firestore_paths.dart';

/// Repository for Team operations
class TeamsRepository {
  final FirebaseFirestore _firestore;

  TeamsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get team by game ID and team ID
  Future<Team?> getTeam(String gameId, String teamId) async {
    if (!Env.isFirebaseAvailable) return null;

    try {
      final doc = await _firestore
          .doc(FirestorePaths.gameTeam(gameId, teamId))
          .get();
      if (!doc.exists) return null;
      return Team.fromJson({...doc.data()!, 'teamId': teamId});
    } catch (e) {
      throw Exception('Failed to get team: $e');
    }
  }

  /// Stream team by game ID and team ID
  Stream<Team?> watchTeam(String gameId, String teamId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(null);
    }

    return _firestore
        .doc(FirestorePaths.gameTeam(gameId, teamId))
        .snapshots()
        .map((doc) => doc.exists
            ? Team.fromJson({...doc.data()!, 'teamId': teamId})
            : null);
  }

  /// Set teams for a game (replaces all teams)
  Future<void> setTeams(String gameId, List<Team> teams) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final batch = _firestore.batch();
      
      // Delete existing teams
      final existingTeams = await _firestore
          .collection(FirestorePaths.gameTeams(gameId))
          .get();
      
      for (var doc in existingTeams.docs) {
        batch.delete(doc.reference);
      }
      
      // Add new teams
      for (var team in teams) {
        final teamId = team.teamId.isNotEmpty
            ? team.teamId
            : _firestore.collection(FirestorePaths.gameTeams(gameId)).doc().id;
        
        final data = team.toJson();
        data.remove('teamId'); // Remove teamId from data (it's the document ID)
        
        batch.set(
          _firestore.doc(FirestorePaths.gameTeam(gameId, teamId)),
          data,
        );
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to set teams: $e');
    }
  }

  /// Stream all teams for a game
  Stream<List<Team>> watchTeams(String gameId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.gameTeams(gameId))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Team.fromJson({...doc.data(), 'teamId': doc.id}))
            .toList());
  }

  /// Get all teams for a game (non-streaming)
  Future<List<Team>> getTeams(String gameId) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.gameTeams(gameId))
          .get();
      
      return snapshot.docs
          .map((doc) => Team.fromJson({...doc.data(), 'teamId': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to get teams: $e');
    }
  }

  /// Update team
  Future<void> updateTeam(
    String gameId,
    String teamId,
    Map<String, dynamic> data,
  ) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore
          .doc(FirestorePaths.gameTeam(gameId, teamId))
          .update(data);
    } catch (e) {
      throw Exception('Failed to update team: $e');
    }
  }

  /// Delete team
  Future<void> deleteTeam(String gameId, String teamId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore.doc(FirestorePaths.gameTeam(gameId, teamId)).delete();
    } catch (e) {
      throw Exception('Failed to delete team: $e');
    }
  }
}

