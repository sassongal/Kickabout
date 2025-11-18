import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/models/team_data.dart';

/// Repository for managing favorite teams data
/// This repository reads from a closed collection 'teams' in Firestore
class FavoriteTeamsRepository {
  final FirebaseFirestore _firestore;

  FavoriteTeamsRepository(this._firestore);

  /// Get all teams from the closed repository
  /// Teams are stored in Firestore collection 'teams'
  Future<List<TeamData>> getAllTeams() async {
    if (!Env.isFirebaseAvailable) {
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('teams')
          .orderBy('league') // Sort by league first
          .orderBy('name') // Then by name
          .get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return TeamData.fromJson(data).copyWith(id: doc.id);
          })
          .toList();
    } catch (e) {
      debugPrint('Error fetching teams: $e');
      return [];
    }
  }

  /// Get a single team by ID
  Future<TeamData?> getTeamById(String teamId) async {
    if (!Env.isFirebaseAvailable) {
      return null;
    }

    try {
      final doc = await _firestore.collection('teams').doc(teamId).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return TeamData.fromJson(data).copyWith(id: doc.id);
    } catch (e) {
      debugPrint('Error fetching team by ID: $e');
      return null;
    }
  }
}
