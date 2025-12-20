import 'package:flutter/material.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';

/// Premium loading state widget
class PremiumLoadingState extends StatelessWidget {
  final String? message;

  const PremiumLoadingState({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
            child: const KineticLoadingAnimation(size: 60),
          ),
          if (message != null) ...[
            const SizedBox(height: 24),
            Text(
              message!,
              style: PremiumTypography.bodyMedium.copyWith(
                color: PremiumColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
