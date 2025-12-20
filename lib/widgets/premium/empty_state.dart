import 'package:flutter/material.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// Premium empty state widget
class PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Widget? illustration; // Optional illustration instead of icon

  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.illustration,
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
              illustration ??
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          PremiumColors.primary.withValues(alpha: 0.2),
                          PremiumColors.secondary.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 64,
                      color: PremiumColors.textTertiary,
                    ),
                  ),
              const SizedBox(height: 24),
              Text(
                title,
                style: PremiumTypography.heading3,
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  style: PremiumTypography.bodyMedium.copyWith(
                    color: PremiumColors.textTertiary,
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
