import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'audio_controller.g.dart';

@Riverpod(keepAlive: true)
class AudioController extends _$AudioController with WidgetsBindingObserver {
  late final AudioPlayer _player;
  static const String _muteKey = 'audio_is_muted';

  @override
  FutureOr<bool> build() async {
    _player = AudioPlayer();

    // Register for app lifecycle callbacks
    WidgetsBinding.instance.addObserver(this);

    // Initialize player settings
    await _player.setAsset('assets/sound/Kattrick_Theme.mp3');
    await _player.setLoopMode(LoopMode.all);
    await _player.setVolume(0.4); // Moderate volume as requested

    // Load mute preference
    final prefs = await SharedPreferences.getInstance();
    final isMuted = prefs.getBool(_muteKey) ?? false;

    if (!isMuted) {
      await _player.play();
    } else {
      await _player.setVolume(0);
    }

    // Dispose player when provider is disposed
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _player.dispose();
    });

    return isMuted;
  }

  Future<void> toggleMute() async {
    try {
      final currentState = state.value ?? false;
      final newState = !currentState;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_muteKey, newState);

      if (newState) {
        await _player.setVolume(0);
        await _player.pause();
      } else {
        await _player.setVolume(0.4);
        await _player.play();
      }

      state = AsyncData(newState);
      debugPrint('Audio mute toggled: $newState');
    } catch (e, stackTrace) {
      debugPrint('Error toggling mute: $e');
      debugPrint('Stack trace: $stackTrace');
      // Keep local state even if SharedPreferences fails
      state = AsyncData(state.value ?? false);
    }
  }

  /// Ensures music is playing if not muted (useful for reappearing screens)
  Future<void> ensurePlaying() async {
    final isMuted = state.value ?? false;
    if (!isMuted && !_player.playing) {
      await _player.play();
    }
  }

  /// Set volume ducking (reduce volume temporarily for sound effects)
  /// Useful for high-priority sound effects like goal scoring
  Future<void> setDucking(bool enabled) async {
    try {
      if (enabled) {
        await _player.setVolume(0.15); // Duck volume to 15%
        debugPrint('Audio ducking enabled');
      } else {
        final isMuted = state.value ?? false;
        await _player.setVolume(isMuted ? 0.0 : 0.4); // Restore normal volume
        debugPrint('Audio ducking disabled');
      }
    } catch (e) {
      debugPrint('Error setting ducking: $e');
    }
  }

  /// Handle app lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Resume music when app returns to foreground
        ensurePlaying();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Music will pause automatically on some platforms
        // Can add fade-out or volume ducking here in the future
        break;
      default:
        break;
    }
  }
}
