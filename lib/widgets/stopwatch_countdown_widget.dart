import 'package:flutter/material.dart';
import 'package:kattrick/screens/stopwatch/advanced_stopwatch_screen.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// Premium Stopwatch/Countdown Widget for Home Screen AppBar
/// Tapping opens the advanced stopwatch screen
class StopwatchCountdownWidget extends StatelessWidget {
  const StopwatchCountdownWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AdvancedStopwatchScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Tooltip(
            message: 'Stopwatch & Timer',
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    PremiumColors.surfaceVariant.withValues(alpha: 0.5),
                    PremiumColors.surface.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: PremiumColors.primary.withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: PremiumColors.primary.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.timer_outlined,
                size: 26,
                color: PremiumColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
