import 'package:flutter/material.dart';
import 'package:kickabout/theme/futuristic_theme.dart';

/// Futuristic loading state widget
class FuturisticLoadingState extends StatelessWidget {
  final String? message;

  const FuturisticLoadingState({
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
                  FuturisticColors.primary.withValues(alpha: 0.2),
                  FuturisticColors.secondary.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                FuturisticColors.secondary,
              ),
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 24),
            Text(
              message!,
              style: FuturisticTypography.bodyMedium.copyWith(
                color: FuturisticColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

