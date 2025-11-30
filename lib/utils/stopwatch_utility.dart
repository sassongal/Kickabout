import 'dart:async';
import 'package:flutter/foundation.dart';

/// General-purpose stopwatch utility for the app
/// 
/// Features:
/// - Start/Stop/Pause/Resume
/// - Reset
/// - Elapsed time tracking
/// - Callbacks for time updates
/// - Formatting helpers
class StopwatchUtility extends ChangeNotifier {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  Duration _pausedDuration = Duration.zero;
  DateTime? _startTime;
  DateTime? _pauseTime;
  bool _isRunning = false;
  bool _isPaused = false;

  /// Current elapsed time
  Duration get elapsed => _elapsed;

  /// Is the stopwatch currently running?
  bool get isRunning => _isRunning;

  /// Is the stopwatch currently paused?
  bool get isPaused => _isPaused;

  /// Start time (when stopwatch was started)
  DateTime? get startTime => _startTime;

  /// Total elapsed time including paused time
  Duration get totalElapsed {
    if (_isRunning && _startTime != null) {
      return DateTime.now().difference(_startTime!) + _pausedDuration;
    }
    return _elapsed + _pausedDuration;
  }

  /// Start the stopwatch
  void start() {
    if (_isRunning) return;

    if (_isPaused) {
      // Resume from pause
      if (_pauseTime != null) {
        _pausedDuration += DateTime.now().difference(_pauseTime!);
      }
      _isPaused = false;
    } else {
      // Fresh start
      _startTime = DateTime.now();
      _elapsed = Duration.zero;
      _pausedDuration = Duration.zero;
    }

    _isRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_startTime != null) {
        _elapsed = DateTime.now().difference(_startTime!) - _pausedDuration;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  /// Pause the stopwatch
  void pause() {
    if (!_isRunning || _isPaused) return;

    _pauseTime = DateTime.now();
    _isRunning = false;
    _isPaused = true;
    _timer?.cancel();
    notifyListeners();
  }

  /// Stop the stopwatch (can be resumed later)
  void stop() {
    _isRunning = false;
    _isPaused = false;
    _timer?.cancel();
    notifyListeners();
  }

  /// Reset the stopwatch to zero
  void reset() {
    _isRunning = false;
    _isPaused = false;
    _elapsed = Duration.zero;
    _pausedDuration = Duration.zero;
    _startTime = null;
    _pauseTime = null;
    _timer?.cancel();
    notifyListeners();
  }

  /// Format duration as MM:SS
  static String formatMMSS(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format duration as HH:MM:SS
  static String formatHHMMSS(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format duration as human-readable string (e.g., "5 minutes", "1 hour 30 minutes")
  static String formatHumanReadable(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes > 0) {
        return '$hours שעות $minutes דקות';
      }
      return '$hours ${hours == 1 ? 'שעה' : 'שעות'}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} ${duration.inMinutes == 1 ? 'דקה' : 'דקות'}';
    } else {
      return '${duration.inSeconds} ${duration.inSeconds == 1 ? 'שנייה' : 'שניות'}';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

