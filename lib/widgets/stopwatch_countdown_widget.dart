import 'package:flutter/material.dart';
import 'package:kattrick/screens/stopwatch/advanced_stopwatch_screen.dart';

/// Stopwatch/Countdown Widget for Home Screen AppBar
/// Tapping opens the advanced stopwatch screen
class StopwatchCountdownWidget extends StatelessWidget {
  const StopwatchCountdownWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.timer_outlined,
        color: Colors.grey.shade700,
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AdvancedStopwatchScreen(),
          ),
        );
      },
      tooltip: 'Stopwatch & Timer',
    );
  }
}
