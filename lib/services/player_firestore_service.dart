import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/features/profile/domain/models/player.dart';

class PlayerFirestoreService {
  final _players = FirebaseFirestore.instance.collection('players');

  Future<void> addPlayer(Player player) async {
    await _players.doc(player.id).set(player.toJson());
  }

  Future<void> updatePlayer(Player player) async {
    await _players.doc(player.id).update(player.toJson());
  }

  Future<void> deletePlayer(String playerId) async {
    await _players.doc(playerId).delete();
  }

  Stream<List<Player>> listenPlayers() {
    return _players.snapshots().map((snap) =>
      snap.docs.map((doc) => Player.fromJson(doc.data())).toList()
    );
  }

  Future<Player?> getPlayer(String playerId) async {
    final doc = await _players.doc(playerId).get();
    if (doc.exists) return Player.fromJson(doc.data()!);
    return null;
  }
}
