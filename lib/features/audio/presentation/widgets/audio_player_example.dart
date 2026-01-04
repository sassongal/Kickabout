import 'package:flutter/material.dart';
import 'package:kattrick/features/audio/presentation/widgets/compact_audio_player.dart';

/// Example screen showing how to integrate the CompactAudioPlayer
///
/// This demonstrates the recommended usage pattern for the audio player.
class AudioPlayerExampleScreen extends StatelessWidget {
  const AudioPlayerExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Player Example'),
      ),
      body: Stack(
        children: [
          // Your main content
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Compact Audio Player Demo',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'The compact audio player appears in the bottom right corner. '
                'Tap it to expand and see full controls.',
              ),
              const SizedBox(height: 24),
              _buildFeatureCard(
                icon: Icons.touch_app,
                title: 'Tap to Expand',
                description: 'Click the compact button to reveal full controls',
              ),
              _buildFeatureCard(
                icon: Icons.music_note,
                title: 'Now Playing',
                description: 'Shows current track with visual indicator',
              ),
              _buildFeatureCard(
                icon: Icons.volume_up,
                title: 'Volume Control',
                description: 'Adjust volume with slider in expanded mode',
              ),
              _buildFeatureCard(
                icon: Icons.skip_next,
                title: 'Track Navigation',
                description: 'Skip to next track in the playlist',
              ),
            ],
          ),

          // Compact Audio Player - positioned at bottom right
          const Positioned(
            bottom: 80,
            right: 16,
            child: CompactAudioPlayer(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade100,
          child: Icon(icon, color: Colors.purple),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
      ),
    );
  }
}
