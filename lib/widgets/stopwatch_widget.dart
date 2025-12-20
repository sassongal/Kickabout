import 'package:flutter/material.dart';
import 'package:kattrick/utils/stopwatch_utility.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// Reusable Stopwatch Widget with controls
///
/// Features:
/// - Large digital display
/// - Start/Pause/Reset buttons
/// - Compact and full-size modes
/// - Hebrew text support
class StopwatchWidget extends StatefulWidget {
  final StopwatchUtility stopwatch;
  final bool compact;
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onReset;
  final Color? accentColor;
  final bool showControls;

  const StopwatchWidget({
    super.key,
    required this.stopwatch,
    this.compact = false,
    this.onStart,
    this.onPause,
    this.onReset,
    this.accentColor,
    this.showControls = true,
  });

  @override
  State<StopwatchWidget> createState() => _StopwatchWidgetState();
}

class _StopwatchWidgetState extends State<StopwatchWidget> {
  @override
  void initState() {
    super.initState();
    widget.stopwatch.addListener(_onStopwatchUpdate);
  }

  @override
  void dispose() {
    widget.stopwatch.removeListener(_onStopwatchUpdate);
    super.dispose();
  }

  void _onStopwatchUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleStart() {
    widget.stopwatch.start();
    widget.onStart?.call();
  }

  void _handlePause() {
    widget.stopwatch.pause();
    widget.onPause?.call();
  }

  void _handleReset() {
    widget.stopwatch.reset();
    widget.onReset?.call();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor ?? PremiumColors.primary;

    if (widget.compact) {
      return _buildCompactView(accentColor);
    }

    return _buildFullView(accentColor);
  }

  Widget _buildCompactView(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.stopwatch.isRunning
            ? accentColor.withValues(alpha: 0.1)
            : PremiumColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.stopwatch.isRunning
              ? accentColor
              : PremiumColors.border,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.stopwatch.isRunning ? Icons.timer : Icons.timer_outlined,
            size: 18,
            color: widget.stopwatch.isRunning ? accentColor : PremiumColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            StopwatchUtility.formatMMSS(widget.stopwatch.elapsed),
            style: PremiumTypography.techHeadline.copyWith(
              fontSize: 16,
              color: widget.stopwatch.isRunning ? accentColor : PremiumColors.textPrimary,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullView(Color accentColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Digital Display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: widget.stopwatch.isRunning
                ? accentColor.withValues(alpha: 0.1)
                : PremiumColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.stopwatch.isRunning
                  ? accentColor
                  : PremiumColors.border,
              width: 2,
            ),
            boxShadow: widget.stopwatch.isRunning ? [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.stopwatch.isRunning ? Icons.timer : Icons.timer_outlined,
                size: 32,
                color: widget.stopwatch.isRunning ? accentColor : PremiumColors.textSecondary,
              ),
              const SizedBox(width: 16),
              Text(
                StopwatchUtility.formatMMSS(widget.stopwatch.elapsed),
                style: PremiumTypography.heading1.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: widget.stopwatch.isRunning ? accentColor : PremiumColors.textPrimary,
                  fontFeatures: [const FontFeature.tabularFigures()],
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),

        // Controls
        if (widget.showControls) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Start/Pause Button
              ElevatedButton.icon(
                onPressed: widget.stopwatch.isRunning ? _handlePause : _handleStart,
                icon: Icon(
                  widget.stopwatch.isRunning ? Icons.pause : Icons.play_arrow,
                  size: 24,
                ),
                label: Text(
                  widget.stopwatch.isRunning ? 'עצור' : 'התחל',
                  style: PremiumTypography.labelLarge,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.stopwatch.isRunning
                      ? Colors.orange[700]
                      : Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Reset Button
              OutlinedButton.icon(
                onPressed: widget.stopwatch.elapsed.inSeconds > 0
                    ? _handleReset
                    : null,
                icon: const Icon(Icons.restart_alt, size: 24),
                label: Text(
                  'אפס',
                  style: PremiumTypography.labelLarge,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PremiumColors.textSecondary,
                  side: BorderSide(
                    color: widget.stopwatch.elapsed.inSeconds > 0
                        ? PremiumColors.border
                        : PremiumColors.border.withValues(alpha: 0.3),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
