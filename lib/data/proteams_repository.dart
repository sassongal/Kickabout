import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'proteams_repository.g.dart';

/// Repository for managing Professional Teams (Israeli Football)
class ProTeamsRepository {
  final FirebaseFirestore _firestore;

  ProTeamsRepository(this._firestore);

  /// Get all professional teams
  Future<List<ProTeam>> getAllTeams() async {
    try {
      final snapshot = await _firestore
          .collection('proteams')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => ProTeam.fromJson({...doc.data(), 'teamId': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to load teams: $e');
    }
  }

  /// Get teams by league
  Future<List<ProTeam>> getTeamsByLeague(String league) async {
    try {
      final snapshot = await _firestore
          .collection('proteams')
          .where('league', isEqualTo: league)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => ProTeam.fromJson({...doc.data(), 'teamId': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to load teams for league $league: $e');
    }
  }

  /// Get a single team by ID
  Future<ProTeam?> getTeam(String teamId) async {
    try {
      final doc = await _firestore.collection('proteams').doc(teamId).get();

      if (!doc.exists) return null;

      return ProTeam.fromJson({...doc.data()!, 'teamId': doc.id});
    } catch (e) {
      throw Exception('Failed to load team $teamId: $e');
    }
  }

  /// Stream all teams (for real-time updates)
  Stream<List<ProTeam>> watchAllTeams() {
    return _firestore
        .collection('proteams')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProTeam.fromJson({...doc.data(), 'teamId': doc.id}))
            .toList());
  }
}

/// Provider for ProTeamsRepository
@riverpod
ProTeamsRepository proTeamsRepository(ProTeamsRepositoryRef ref) {
  return ProTeamsRepository(FirebaseFirestore.instance);
}

/// Provider to get all teams
@riverpod
Future<List<ProTeam>> allProTeams(AllProTeamsRef ref) async {
  final repository = ref.watch(proTeamsRepositoryProvider);
  return repository.getAllTeams();
}

/// Provider to get a specific team
@riverpod
Future<ProTeam?> proTeam(ProTeamRef ref, String teamId) async {
  final repository = ref.watch(proTeamsRepositoryProvider);
  return repository.getTeam(teamId);
}
