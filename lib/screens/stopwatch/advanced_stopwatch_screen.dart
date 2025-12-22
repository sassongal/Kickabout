import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kattrick/widgets/common/home_logo_button.dart';

/// Advanced Stopwatch Screen with Lap Times and Countdown
/// Professional UI with modern design principles
class AdvancedStopwatchScreen extends StatefulWidget {
  const AdvancedStopwatchScreen({super.key});

  @override
  State<AdvancedStopwatchScreen> createState() =>
      _AdvancedStopwatchScreenState();
}

class _AdvancedStopwatchScreenState extends State<AdvancedStopwatchScreen>
    with SingleTickerProviderStateMixin {
  // Timer state
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  Duration? _countdownTarget;
  bool _isRunning = false;
  bool _isCountdownMode = false;
  final List<LapTime> _laps = [];
  late AnimationController _pulseController;

  // Countdown minute picker
  final FixedExtentScrollController _minuteController =
      FixedExtentScrollController(initialItem: 8); // Default 8 minutes
  int _selectedMinutes = 8;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Set default countdown to 8 minutes
    _countdownTarget = Duration(minutes: _selectedMinutes);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      setState(() {
        if (_isCountdownMode && _countdownTarget != null) {
          // Countdown mode
          final remaining =
              _countdownTarget!.inMilliseconds - _elapsed.inMilliseconds;
          if (remaining <= 0) {
            _elapsed = _countdownTarget!;
            _stopTimer();
            _onCountdownComplete();
          } else {
            _elapsed += const Duration(milliseconds: 10);
          }
        } else {
          // Stopwatch mode
          _elapsed += const Duration(milliseconds: 10);
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _elapsed = Duration.zero;
      _countdownTarget = null;
      _laps.clear();
    });
  }

  void _recordLap() {
    if (!_isRunning || _isCountdownMode) return;

    setState(() {
      final lapDuration = _laps.isEmpty
          ? _elapsed
          : Duration(
              milliseconds: _elapsed.inMilliseconds -
                  _laps.map((l) => l.duration.inMilliseconds).reduce((a, b) => a + b),
            );

      _laps.insert(
        0,
        LapTime(
          lapNumber: _laps.length + 1,
          duration: lapDuration,
          totalTime: _elapsed,
        ),
      );
    });
  }

  void _onCountdownComplete() {
    // Show completion dialog
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Time\'s Up!',
                style: GoogleFonts.orbitron(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Countdown completed',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateCountdownFromPicker() {
    setState(() {
      _countdownTarget = Duration(minutes: _selectedMinutes);
      _elapsed = Duration.zero;
    });
  }

  Duration _getCurrentDisplayTime() {
    if (_isCountdownMode && _countdownTarget != null) {
      final remaining =
          _countdownTarget!.inMilliseconds - _elapsed.inMilliseconds;
      return Duration(
          milliseconds: remaining.clamp(0, _countdownTarget!.inMilliseconds));
    }
    return _elapsed;
  }

  String _formatDuration(Duration duration, {bool showMillis = true}) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final millis = (duration.inMilliseconds.remainder(1000) / 10).floor();

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}${showMillis ? '.${millis.toString().padLeft(2, '0')}' : ''}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}${showMillis ? '.${millis.toString().padLeft(2, '0')}' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final displayTime = _getCurrentDisplayTime();
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        leadingWidth: AppBarHomeLogo.leadingWidth(showBackButton: canPop),
        leading: AppBarHomeLogo(showBackButton: canPop),
        automaticallyImplyLeading: false,
        title: Text(
          'Stopwatch',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Settings could go here
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode Selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        label: 'Stopwatch',
                        icon: Icons.timer_outlined,
                        isSelected: !_isCountdownMode,
                        onTap: () {
                          if (_isRunning) return;
                          setState(() {
                            _isCountdownMode = false;
                            _resetTimer();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ModeButton(
                        label: 'Countdown',
                        icon: Icons.hourglass_bottom_outlined,
                        isSelected: _isCountdownMode,
                        onTap: () {
                          if (_isRunning) return;
                          setState(() {
                            _isCountdownMode = true;
                            _resetTimer();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Time Display
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Circle
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing effect when running
                      if (_isRunning)
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 280 + (_pulseController.value * 20),
                              height: 280 + (_pulseController.value * 20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (_isCountdownMode
                                        ? Colors.orange
                                        : Colors.blue)
                                    .withOpacity(
                                        0.1 * (1 - _pulseController.value)),
                              ),
                            );
                          },
                        ),

                      // Main circle
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: (_isCountdownMode
                                      ? Colors.orange
                                      : Colors.blue)
                                  .withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatDuration(displayTime),
                                style: GoogleFonts.orbitron(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: _isRunning
                                      ? (_isCountdownMode
                                          ? Colors.orange.shade700
                                          : Colors.blue.shade700)
                                      : Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isCountdownMode ? 'REMAINING' : 'ELAPSED',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Countdown Minute Picker (only in countdown mode)
                  if (_isCountdownMode && !_isRunning) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Text(
                            'SELECT MINUTES',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Minute picker
                                SizedBox(
                                  width: 100,
                                  child: ListWheelScrollView.useDelegate(
                                    controller: _minuteController,
                                    itemExtent: 50,
                                    perspective: 0.005,
                                    diameterRatio: 1.2,
                                    physics: const FixedExtentScrollPhysics(),
                                    onSelectedItemChanged: (index) {
                                      setState(() {
                                        _selectedMinutes = index + 1;
                                        _updateCountdownFromPicker();
                                      });
                                    },
                                    childDelegate: ListWheelChildBuilderDelegate(
                                      childCount: 60,
                                      builder: (context, index) {
                                        final minute = index + 1;
                                        final isSelected =
                                            minute == _selectedMinutes;
                                        return Center(
                                          child: Text(
                                            minute.toString(),
                                            style: GoogleFonts.orbitron(
                                              fontSize: isSelected ? 32 : 24,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? Colors.orange.shade700
                                                  : Colors.grey.shade400,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'min',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Lap times display (only in stopwatch mode)
                  if (!_isCountdownMode && _laps.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'LAP TIMES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Lap Times List
          if (!_isCountdownMode && _laps.isNotEmpty)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: _laps.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) {
                    final lap = _laps[index];
                    final isFastest = _laps.length > 1 &&
                        lap.duration ==
                            _laps
                                .map((l) => l.duration)
                                .reduce((a, b) =>
                                    a.inMilliseconds < b.inMilliseconds
                                        ? a
                                        : b);
                    final isSlowest = _laps.length > 1 &&
                        lap.duration ==
                            _laps
                                .map((l) => l.duration)
                                .reduce((a, b) =>
                                    a.inMilliseconds > b.inMilliseconds
                                        ? a
                                        : b);

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isFastest
                              ? Colors.green.shade100
                              : isSlowest
                                  ? Colors.red.shade100
                                  : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '#${lap.lapNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isFastest
                                  ? Colors.green.shade700
                                  : isSlowest
                                      ? Colors.red.shade700
                                      : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        _formatDuration(lap.duration),
                        style: GoogleFonts.orbitron(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isFastest
                              ? Colors.green.shade700
                              : isSlowest
                                  ? Colors.red.shade700
                                  : Colors.black87,
                        ),
                      ),
                      trailing: Text(
                        _formatDuration(lap.totalTime, showMillis: false),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Control Buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reset Button
                  _ControlButton(
                    icon: Icons.refresh_rounded,
                    label: 'Reset',
                    color: Colors.grey.shade700,
                    backgroundColor: Colors.grey.shade100,
                    onPressed: _elapsed.inMilliseconds > 0 ? _resetTimer : null,
                  ),

                  const SizedBox(width: 16),

                  // Main Action Button (Start/Pause)
                  Expanded(
                    flex: 2,
                    child: _ControlButton(
                      icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      label: _isRunning ? 'Pause' : 'Start',
                      color: Colors.white,
                      backgroundColor: _isRunning
                          ? Colors.orange.shade600
                          : Colors.green.shade600,
                      onPressed: (_isCountdownMode && _countdownTarget == null)
                          ? null
                          : _toggleTimer,
                      isLarge: true,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Lap Button (only in stopwatch mode while running)
                  _ControlButton(
                    icon: Icons.flag_rounded,
                    label: 'Lap',
                    color: Colors.blue.shade700,
                    backgroundColor: Colors.blue.shade100,
                    onPressed:
                        (!_isCountdownMode && _isRunning) ? _recordLap : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Lap Time Model
class LapTime {
  final int lapNumber;
  final Duration duration;
  final Duration totalTime;

  LapTime({
    required this.lapNumber,
    required this.duration,
    required this.totalTime,
  });
}

// Mode Toggle Button Component
class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade600 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Control Button Component
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback? onPressed;
  final bool isLarge;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    this.onPressed,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1.0,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isLarge ? 20 : 16),
        elevation: onPressed != null ? 2 : 0,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(isLarge ? 20 : 16),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: isLarge ? 20 : 16,
              horizontal: isLarge ? 32 : 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: isLarge ? 32 : 24,
                  color: color,
                ),
                if (isLarge) ...[
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
