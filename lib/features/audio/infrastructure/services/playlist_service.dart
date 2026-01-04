import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kattrick Theme Playlist Service
///
/// Manages background music playback with shuffle, volume control, and user preferences.
///
/// **Features:**
/// - 5 music tracks (k1.mp3 - k5.mp3)
/// - Shuffle/randomized playback
/// - Per-user volume control (saved to local storage)
/// - Next track control
/// - Mute/unmute
/// - Auto-play next track when current ends
///
/// **Usage:**
/// ```dart
/// final playlist = PlaylistService();
/// await playlist.initialize();
/// await playlist.play(); // Start playing shuffled playlist
/// await playlist.nextTrack(); // Skip to next random track
/// await playlist.setVolume(0.5); // 50% volume
/// ```
class PlaylistService {
  PlaylistService._internal();

  factory PlaylistService() => _instance;
  static final PlaylistService _instance = PlaylistService._internal();

  // Audio player instance
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Playlist tracks (asset paths)
  static const List<String> _tracks = [
    'asset:///assets/sound/k1.mp3',
    'asset:///assets/sound/k2.mp3',
    'asset:///assets/sound/k3.mp3',
    'asset:///assets/sound/k4.mp3',
    'asset:///assets/sound/k5.mp3',
  ];

  // State
  List<String> _shuffledPlaylist = [];
  int _currentTrackIndex = 0;
  double _volume = 0.7; // Default 70% volume
  bool _isMuted = false;
  bool _isPlaying = false;
  bool _isInitialized = false;

  // SharedPreferences keys
  static const String _volumeKey = 'kattrick_music_volume';
  static const String _mutedKey = 'kattrick_music_muted';

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isMuted => _isMuted;
  double get volume => _volume;
  String get currentTrackName => _getCurrentTrackName();
  int get currentTrackNumber => _currentTrackIndex + 1;
  int get totalTracks => _tracks.length;

  /// Initialize the playlist service
  ///
  /// - Loads user preferences from SharedPreferences
  /// - Shuffles the playlist
  /// - Sets up playback completion listener for auto-next
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🎵 [PlaylistService] Initializing...');

    // Load user preferences
    await _loadPreferences();

    // Shuffle playlist
    _shufflePlaylist();

    // Listen for player completion (auto-play next track)
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;

      // Auto-play next track when current ends
      if (state.processingState == ProcessingState.completed) {
        debugPrint('🎵 [PlaylistService] Track completed, playing next...');
        nextTrack();
      }

      debugPrint(
          '🎵 [PlaylistService] State: playing=${state.playing}, processingState=${state.processingState}');
    });

    _isInitialized = true;
    debugPrint('✅ [PlaylistService] Initialized successfully');
  }

  /// Load user preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _volume = prefs.getDouble(_volumeKey) ?? 0.7;
      _isMuted = prefs.getBool(_mutedKey) ?? false;

      // Apply loaded volume
      await _audioPlayer.setVolume(_isMuted ? 0.0 : _volume);

      debugPrint(
          '📥 [PlaylistService] Loaded preferences: volume=$_volume, muted=$_isMuted');
    } catch (e) {
      debugPrint('⚠️ [PlaylistService] Failed to load preferences: $e');
    }
  }

  /// Shuffle the playlist randomly
  void _shufflePlaylist() {
    _shuffledPlaylist = List.from(_tracks);
    _shuffledPlaylist.shuffle(Random());
    _currentTrackIndex = 0;
    debugPrint('🔀 [PlaylistService] Playlist shuffled');
  }

  /// Start playing the playlist
  Future<void> play() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final trackPath = _shuffledPlaylist[_currentTrackIndex];
      debugPrint('▶️ [PlaylistService] Playing: ${_getCurrentTrackName()}');

      await _audioPlayer.setAsset(trackPath);
      await _audioPlayer.setVolume(_isMuted ? 0.0 : _volume);
      await _audioPlayer.play();
      _isPlaying = true;
    } catch (e) {
      debugPrint('❌ [PlaylistService] Failed to play: $e');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
      debugPrint('⏸️ [PlaylistService] Paused');
    } catch (e) {
      debugPrint('❌ [PlaylistService] Failed to pause: $e');
    }
  }

  /// Resume playback
  Future<void> resume() async {
    try {
      await _audioPlayer.play();
      _isPlaying = true;
      debugPrint('▶️ [PlaylistService] Resumed');
    } catch (e) {
      debugPrint('❌ [PlaylistService] Failed to resume: $e');
    }
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      debugPrint('⏹️ [PlaylistService] Stopped');
    } catch (e) {
      debugPrint('❌ [PlaylistService] Failed to stop: $e');
    }
  }

  /// Skip to next track (random selection)
  Future<void> nextTrack() async {
    // Move to next track in shuffled playlist
    _currentTrackIndex = (_currentTrackIndex + 1) % _shuffledPlaylist.length;

    // If we've reached the end, reshuffle
    if (_currentTrackIndex == 0) {
      debugPrint('🔄 [PlaylistService] Playlist ended, reshuffling...');
      _shufflePlaylist();
    }

    // Play the new track
    await play();
  }

  /// Get next track options (for UI preview)
  ///
  /// Returns a list of 2 upcoming tracks
  List<String> getNextTrackOptions() {
    final options = <String>[];
    for (int i = 1; i <= 2; i++) {
      final nextIndex = (_currentTrackIndex + i) % _shuffledPlaylist.length;
      options.add(_getTrackName(_shuffledPlaylist[nextIndex]));
    }
    return options;
  }

  /// Set volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);

    if (!_isMuted) {
      await _audioPlayer.setVolume(_volume);
    }

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, _volume);

    debugPrint(
        '🔊 [PlaylistService] Volume set to: ${(_volume * 100).round()}%');
  }

  /// Toggle mute
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;

    await _audioPlayer.setVolume(_isMuted ? 0.0 : _volume);

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mutedKey, _isMuted);

    debugPrint('🔇 [PlaylistService] Mute toggled: $_isMuted');
  }

  /// Mute
  Future<void> mute() async {
    if (!_isMuted) {
      await toggleMute();
    }
  }

  /// Unmute
  Future<void> unmute() async {
    if (_isMuted) {
      await toggleMute();
    }
  }

  /// Get current track name (e.g., "Track 1")
  String _getCurrentTrackName() {
    return _getTrackName(_shuffledPlaylist[_currentTrackIndex]);
  }

  /// Extract track name from path
  String _getTrackName(String path) {
    final filename = path.split('/').last.replaceAll('.mp3', '');
    // k1.mp3 -> Track 1
    final trackNumber = filename.replaceAll('k', '');
    return 'Track $trackNumber';
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    debugPrint('🗑️ [PlaylistService] Disposed');
  }
}
