import 'package:flutter/material.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';

/// Futuristic empty state widget
class FuturisticEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const FuturisticEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      FuturisticColors.primary.withValues(alpha: 0.2),
                      FuturisticColors.secondary.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: FuturisticColors.textTertiary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: FuturisticTypography.heading3,
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  style: FuturisticTypography.bodyMedium.copyWith(
                    color: FuturisticColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 24),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

