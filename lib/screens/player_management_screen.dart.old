import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/player_firestore_service.dart';
import 'player_profile_screen.dart';

class PlayerManagementScreen extends StatelessWidget {
  final PlayerFirestoreService _service = PlayerFirestoreService();

  PlayerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ניהול שחקנים')),
      body: StreamBuilder<List<Player>>(
        stream: _service.listenPlayers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final players = snapshot.data!;
          return ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, i) {
              final player = players[i];
              return ListTile(
                title: Text(player.name),
                subtitle: Text('דרוג: \${player.overallGrade}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerProfileScreen(player: player),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await _service.deletePlayer(player.id);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // כאן תוכל לפתוח מסך יצירת שחקן חדש
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
