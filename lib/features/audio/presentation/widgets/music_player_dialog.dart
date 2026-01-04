import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kattrick/features/audio/infrastructure/services/playlist_service.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// Music Player Dialog
///
/// Full-screen dialog with audio player controls that appears when
/// tapping the music button in the header.
///
/// **Features:**
/// - Current track display with animated waveform
/// - Play/Pause button
/// - Skip Next button
/// - Mute/Unmute button
/// - Volume slider
/// - Glassmorphic design
/// - Track list (upcoming)
///
/// **Usage:**
/// ```dart
/// IconButton(
///   icon: Icon(Icons.music_note),
///   onPressed: () => showMusicPlayerDialog(context),
/// )
/// ```
void showMusicPlayerDialog(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const MusicPlayerDialog();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      );
    },
  );
}

class MusicPlayerDialog extends StatefulWidget {
  const MusicPlayerDialog({super.key});

  @override
  State<MusicPlayerDialog> createState() => _MusicPlayerDialogState();
}

class _MusicPlayerDialogState extends State<MusicPlayerDialog>
    with TickerProviderStateMixin {
  final PlaylistService _playlist = PlaylistService();

  // Player state
  bool _isPlaying = false;
  bool _isMuted = false;
  double _volume = 0.7;
  String _currentTrack = 'Track 1';
  int _currentTrackNumber = 1;
  int _totalTracks = 5;

  // Animation controllers
  late AnimationController _waveController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _initializePlaylist();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Waveform animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Rotation animation for vinyl record effect
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
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
        _volume = _playlist.volume;
        _currentTrack = _playlist.currentTrackName;
        _currentTrackNumber = _playlist.currentTrackNumber;
        _totalTracks = _playlist.totalTracks;

        if (_isPlaying) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }
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
    await _playlist.nextTrack();
    _updateState();
  }

  Future<void> _toggleMute() async {
    await _playlist.toggleMute();
    _updateState();
  }

  Future<void> _setVolume(double value) async {
    await _playlist.setVolume(value);
    _updateState();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              PremiumColors.primary.withValues(alpha: 0.95),
              PremiumColors.accent.withValues(alpha: 0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: PremiumColors.primary.withValues(alpha: 0.5),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildAlbumArt(),
                  const SizedBox(height: 32),
                  _buildTrackInfo(),
                  const SizedBox(height: 24),
                  _buildControls(),
                  const SizedBox(height: 24),
                  _buildVolumeControl(),
                  const SizedBox(height: 16),
                  _buildTrackProgress(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'KATTRICK THEME',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildAlbumArt() {
    return RotationTransition(
      turns: _rotationController,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.3),
              PremiumColors.secondary.withValues(alpha: 0.6),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Vinyl grooves
            ...List.generate(5, (index) {
              final size = 180.0 - (index * 30.0);
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              );
            }),
            // Center hole
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PremiumColors.primary,
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackInfo() {
    return Column(
      children: [
        Text(
          _currentTrack,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Kattrick Original',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mute button
        _buildControlButton(
          icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          onPressed: _toggleMute,
          size: 48,
          color: _isMuted ? Colors.red.shade300 : Colors.white,
        ),
        const SizedBox(width: 24),

        // Play/Pause button (larger)
        _buildControlButton(
          icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          onPressed: _togglePlayPause,
          size: 72,
          color: Colors.white,
          isPrimary: true,
        ),
        const SizedBox(width: 24),

        // Next button
        _buildControlButton(
          icon: Icons.skip_next_rounded,
          onPressed: _nextTrack,
          size: 48,
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
    required Color color,
    bool isPrimary = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPrimary
            ? Colors.white.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.15),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: size * 0.5),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildVolumeControl() {
    return Row(
      children: [
        Icon(
          Icons.volume_down_rounded,
          color: Colors.white.withValues(alpha: 0.7),
          size: 20,
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 16,
              ),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _isMuted ? 0.0 : _volume,
              onChanged: _isMuted ? null : _setVolume,
              min: 0.0,
              max: 1.0,
            ),
          ),
        ),
        Icon(
          Icons.volume_up_rounded,
          color: Colors.white.withValues(alpha: 0.7),
          size: 20,
        ),
      ],
    );
  }

  Widget _buildTrackProgress() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Track $_currentTrackNumber / $_totalTracks',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        AnimatedBuilder(
          animation: _waveController,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (index) {
                final height = _isPlaying
                    ? 4.0 +
                        (10 * (_waveController.value + (index * 0.2)) % 1.0)
                    : 4.0;
                return Container(
                  width: 3,
                  height: height,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}
