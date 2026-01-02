import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/utils/stopwatch_utility.dart';
import 'package:kattrick/widgets/app_scaffold.dart';

/// Full-screen stopwatch screen with hero animation
class FullScreenStopwatchScreen extends ConsumerStatefulWidget {
  final StopwatchUtility stopwatchUtility;
  final int elapsedOffsetSeconds;
  final bool isRunning;
  final bool isCountdownMode;
  final Function(bool) onRunningChanged;
  final Function() onReset;

  const FullScreenStopwatchScreen({
    super.key,
    required this.stopwatchUtility,
    required this.elapsedOffsetSeconds,
    required this.isRunning,
    required this.isCountdownMode,
    required this.onRunningChanged,
    required this.onReset,
  });

  @override
  ConsumerState<FullScreenStopwatchScreen> createState() =>
      _FullScreenStopwatchScreenState();
}

class _FullScreenStopwatchScreenState
    extends ConsumerState<FullScreenStopwatchScreen> {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'סטופר',
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black87,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Large stopwatch display (MM:SS:mm format)
              Hero(
                tag: 'stopwatch',
                child: Material(
                  color: Colors.transparent,
                  child: Center(
                    child: ExcludeSemantics(
                      child: AnimatedBuilder(
                        animation: widget.stopwatchUtility,
                        builder: (context, _) {
                          final totalMilliseconds =
                              (widget.elapsedOffsetSeconds * 1000) +
                                  (widget.stopwatchUtility.isRunning
                                      ? widget.stopwatchUtility.elapsed
                                          .inMilliseconds
                                      : 0);

                          const durationMinutes = 12; // Default if not found
                          final timeLimitMilliseconds =
                              durationMinutes * 60 * 1000;

                          final displayMs = widget.isCountdownMode
                              ? (timeLimitMilliseconds - totalMilliseconds)
                                  .clamp(0, timeLimitMilliseconds)
                              : totalMilliseconds;

                          final totalSeconds = displayMs ~/ 1000;
                          final minutes = totalSeconds ~/ 60;
                          final seconds = totalSeconds % 60;
                          final centiseconds = (displayMs % 1000) ~/ 10;

                          return Text(
                            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}:${centiseconds.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 72, // Stable large size
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'monospace',
                              letterSpacing: 4,
                            ),
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Play/Pause button
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onRunningChanged(!widget.isRunning);
                    },
                    icon: Icon(
                      widget.isRunning
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      size: 32,
                    ),
                    label: Text(
                      widget.isRunning ? 'השהה' : 'התחל',
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Reset button
                  ElevatedButton.icon(
                    onPressed: widget.onReset,
                    icon: const Icon(Icons.refresh, size: 28),
                    label: const Text(
                      'איפוס',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
