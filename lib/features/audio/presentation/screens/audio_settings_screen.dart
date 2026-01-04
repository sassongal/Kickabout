import 'package:flutter/material.dart';
import 'package:kattrick/features/audio/infrastructure/services/playlist_service.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/common/premium_scaffold.dart';

/// Audio Settings Screen
///
/// Allows users to control music volume and playlist preferences.
///
/// **Features:**
/// - Volume slider (0% - 100%)
/// - Mute toggle
/// - Current track display
/// - Play/Pause/Next controls
///
/// **Route:** `/settings/audio`
class AudioSettingsScreen extends StatefulWidget {
  const AudioSettingsScreen({super.key});

  @override
  State<AudioSettingsScreen> createState() => _AudioSettingsScreenState();
}

class _AudioSettingsScreenState extends State<AudioSettingsScreen> {
  final PlaylistService _playlist = PlaylistService();
  double _volume = 0.7;
  bool _isMuted = false;
  bool _isPlaying = false;
  String _currentTrack = 'Track 1';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  void _loadState() {
    setState(() {
      _volume = _playlist.volume;
      _isMuted = _playlist.isMuted;
      _isPlaying = _playlist.isPlaying;
      _currentTrack = _playlist.currentTrackName;
    });
  }

  Future<void> _setVolume(double value) async {
    await _playlist.setVolume(value);
    _loadState();
  }

  Future<void> _toggleMute() async {
    await _playlist.toggleMute();
    _loadState();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _playlist.pause();
    } else {
      await _playlist.play();
    }
    _loadState();
  }

  Future<void> _nextTrack() async {
    await _playlist.nextTrack();
    _loadState();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: 'הגדרות שמע',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Track Card
            _buildCurrentTrackCard(),
            const SizedBox(height: 24),

            // Playback Controls
            _buildPlaybackControls(),
            const SizedBox(height: 32),

            // Volume Control
            _buildVolumeControl(),
            const SizedBox(height: 24),

            // Mute Toggle
            _buildMuteToggle(),
            const SizedBox(height: 32),

            // Info Section
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTrackCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              PremiumColors.primary.withValues(alpha: 0.1),
              PremiumColors.accent.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PremiumColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.music_note : Icons.music_off,
                color: PremiumColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kattrick Theme Playlist',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'מנגן כעת: $_currentTrack',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'בקרת נגינה',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Play/Pause
                _buildControlButton(
                  icon: _isPlaying ? Icons.pause_circle : Icons.play_circle,
                  label: _isPlaying ? 'השהה' : 'נגן',
                  onPressed: _togglePlayPause,
                  color: PremiumColors.primary,
                ),
                // Next Track
                _buildControlButton(
                  icon: Icons.skip_next,
                  label: 'הבא',
                  onPressed: _nextTrack,
                  color: PremiumColors.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, size: 48, color: color),
            onPressed: onPressed,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeControl() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'עוצמת קול',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(_volume * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: PremiumColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.volume_down,
                  color: Colors.grey.shade600,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: PremiumColors.primary,
                      inactiveTrackColor:
                          PremiumColors.primary.withValues(alpha: 0.2),
                      thumbColor: PremiumColors.primary,
                      overlayColor:
                          PremiumColors.primary.withValues(alpha: 0.2),
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 10),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 20),
                    ),
                    child: Slider(
                      value: _volume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      onChanged: _isMuted ? null : _setVolume,
                    ),
                  ),
                ),
                Icon(
                  Icons.volume_up,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuteToggle() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: const Text(
          'השתק מוזיקה',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _isMuted ? 'המוזיקה מושתקת' : 'המוזיקה פעילה',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        value: _isMuted,
        onChanged: (value) => _toggleMute(),
        activeThumbColor: PremiumColors.primary,
        secondary: Icon(
          _isMuted ? Icons.volume_off : Icons.volume_up,
          color: _isMuted ? Colors.red : PremiumColors.primary,
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: PremiumColors.accent, size: 20),
                SizedBox(width: 8),
                Text(
                  'אודות',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• הפלייליסט כולל 5 רצועות מוזיקה\n'
              '• הרצועות מנוגנות באקראי (Shuffle)\n'
              '• ההגדרות נשמרות באופן אוטומטי\n'
              '• ניתן לדלג לרצועה הבאה בכל עת',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
