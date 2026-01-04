import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kattrick/features/audio/infrastructure/services/playlist_service.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// Floating Music Player Widget
///
/// A beautiful, compact music player that floats at the bottom of the screen.
///
/// **Features:**
/// - Play/Pause button
/// - Next track button with 2 upcoming tracks preview
/// - Mute/Unmute button
/// - Current track display
/// - Glassmorphic design
///
/// **Usage:**
/// ```dart
/// Stack(
///   children: [
///     // Your main content
///     MyHomeScreen(),
///     // Music player at bottom
///     Positioned(
///       bottom: 80,
///       left: 16,
///       right: 16,
///       child: FloatingMusicPlayer(),
///     ),
///   ],
/// )
/// ```
class FloatingMusicPlayer extends StatefulWidget {
  const FloatingMusicPlayer({super.key});

  @override
  State<FloatingMusicPlayer> createState() => _FloatingMusicPlayerState();
}

class _FloatingMusicPlayerState extends State<FloatingMusicPlayer> {
  final PlaylistService _playlist = PlaylistService();
  bool _isPlaying = false;
  bool _isMuted = false;
  String _currentTrack = 'Track 1';

  @override
  void initState() {
    super.initState();
    _initializePlaylist();
  }

  Future<void> _initializePlaylist() async {
    await _playlist.initialize();
    _updateState();
  }

  void _updateState() {
    if (mounted) {
      setState(() {
        _isPlaying = _playlist.isPlaying;
        _isMuted = _playlist.isMuted;
        _currentTrack = _playlist.currentTrackName;
      });
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _playlist.pause();
    } else {
      await _playlist.play();
    }
    _updateState();
  }

  Future<void> _nextTrack() async {
    // Show dialog with 2 next track options
    final nextOptions = _playlist.getNextTrackOptions();

    if (!mounted) return;

    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('השיר הבא'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.music_note, color: PremiumColors.primary),
              title: Text(nextOptions[0]),
              subtitle: const Text('אופציה 1'),
              onTap: () => Navigator.pop(context, 0),
            ),
            ListTile(
              leading: const Icon(Icons.music_note, color: PremiumColors.secondary),
              title: Text(nextOptions[1]),
              subtitle: const Text('אופציה 2'),
              onTap: () => Navigator.pop(context, 1),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );

    if (selected != null) {
      // Skip to selected track
      for (int i = 0; i <= selected; i++) {
        await _playlist.nextTrack();
      }
      _updateState();
    }
  }

  Future<void> _toggleMute() async {
    await _playlist.toggleMute();
    _updateState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PremiumColors.primary.withValues(alpha: 0.9),
            PremiumColors.accent.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: PremiumColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // Play/Pause Button
                _buildControlButton(
                  icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                  onPressed: _togglePlayPause,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),

                // Current Track Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Kattrick Theme',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _currentTrack,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Next Track Button (with options)
                _buildControlButton(
                  icon: Icons.skip_next,
                  onPressed: _nextTrack,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),

                // Mute/Unmute Button
                _buildControlButton(
                  icon: _isMuted ? Icons.volume_off : Icons.volume_up,
                  onPressed: _toggleMute,
                  color: _isMuted ? Colors.red.shade300 : Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 24),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }
}
