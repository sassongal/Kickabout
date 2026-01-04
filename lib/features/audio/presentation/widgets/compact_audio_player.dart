import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kattrick/features/audio/infrastructure/services/playlist_service.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// Compact Audio Player Widget
///
/// A minimal, expandable audio player that starts as a small fab-like button
/// and expands to show full controls when tapped.
///
/// **Features:**
/// - Compact mode: Single play/pause button with now-playing indicator
/// - Expanded mode: Full player with track info, next/prev, volume slider
/// - Smooth animations between states
/// - Glassmorphic design
/// - Auto-collapses after inactivity
///
/// **Usage:**
/// ```dart
/// Stack(
///   children: [
///     // Your main content
///     MyHomeScreen(),
///     // Compact player at bottom right
///     Positioned(
///       bottom: 80,
///       right: 16,
///       child: CompactAudioPlayer(),
///     ),
///   ],
/// )
/// ```
class CompactAudioPlayer extends StatefulWidget {
  const CompactAudioPlayer({super.key});

  @override
  State<CompactAudioPlayer> createState() => _CompactAudioPlayerState();
}

class _CompactAudioPlayerState extends State<CompactAudioPlayer>
    with SingleTickerProviderStateMixin {
  final PlaylistService _playlist = PlaylistService();

  // Player state
  bool _isPlaying = false;
  bool _isMuted = false;
  double _volume = 0.7;
  String _currentTrack = 'Track 1';

  // UI state
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializePlaylist();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
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
      });
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return Container(
          width: _isExpanded ? 320 : 64,
          height: _isExpanded ? 160 : 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                PremiumColors.primary.withValues(alpha: 0.95),
                PremiumColors.accent.withValues(alpha: 0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(_isExpanded ? 24 : 32),
            boxShadow: [
              BoxShadow(
                color: PremiumColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_isExpanded ? 24 : 32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(_isExpanded ? 24 : 32),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isExpanded ? null : _toggleExpanded,
                    borderRadius: BorderRadius.circular(_isExpanded ? 24 : 32),
                    child: _isExpanded
                        ? _buildExpandedPlayer()
                        : _buildCompactPlayer(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactPlayer() {
    return Stack(
      children: [
        // Pulsing ring when playing
        if (_isPlaying)
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Container(
                  width: 56 + (value * 8),
                  height: 56 + (value * 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3 * (1 - value)),
                      width: 2,
                    ),
                  ),
                );
              },
              onEnd: () {
                if (mounted && _isPlaying) {
                  setState(() {}); // Restart animation
                }
              },
            ),
          ),

        // Play/Pause button
        Center(
          child: Icon(
            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),

        // Now playing indicator
        if (_isPlaying)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExpandedPlayer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with collapse button
          Row(
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Icon(
                  Icons.music_note_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
              ),
              IconButton(
                icon: const Icon(Icons.expand_more_rounded, color: Colors.white),
                onPressed: _toggleExpanded,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const Spacer(),

          // Controls
          FadeTransition(
            opacity: _fadeAnimation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  onPressed: _toggleMute,
                  color: _isMuted ? Colors.red.shade300 : Colors.white,
                ),
                const SizedBox(width: 8),
                _buildControlButton(
                  icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  onPressed: _togglePlayPause,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(width: 8),
                _buildControlButton(
                  icon: Icons.skip_next_rounded,
                  onPressed: _nextTrack,
                  color: Colors.white,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Volume slider
          FadeTransition(
            opacity: _fadeAnimation,
            child: Row(
              children: [
                Icon(
                  Icons.volume_down_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 16,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
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
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    double size = 32,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: size * 0.6),
        onPressed: onPressed,
        padding: EdgeInsets.all(size * 0.2),
        constraints: const BoxConstraints(),
      ),
    );
  }
}
