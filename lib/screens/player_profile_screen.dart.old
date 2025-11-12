import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/player_firestore_service.dart';

class PlayerProfileScreen extends StatefulWidget {
  final Player player;
  const PlayerProfileScreen({super.key, required this.player});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  late Player _player;
  final _service = PlayerFirestoreService();

  @override
  void initState() {
    super.initState();
    _player = widget.player;
  }

  void _editPlayer() async {
    final edited = await showDialog<Player>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('עריכת שם'),
        content: TextField(
          controller: TextEditingController(text: _player.name),
          onChanged: (val) => _player = _player.copyWith(name: val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _player),
            child: const Text('שמור'),
          ),
        ],
      ),
    );
    if (edited != null) {
      await _service.updatePlayer(edited);
      setState(() => _player = edited);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_player.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editPlayer,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('דרוג: \${_player.overallGrade}', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}
