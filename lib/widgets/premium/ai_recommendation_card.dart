import 'package:flutter/material.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/common/premium_card.dart';

/// AI-powered recommendation card with smart insights
class AIRecommendationCard extends StatelessWidget {
  final String title;
  final String description;
  final String? metric;
  final String? metricLabel;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? accentColor;

  const AIRecommendationCard({
    super.key,
    required this.title,
    required this.description,
    this.metric,
    this.metricLabel,
    required this.icon,
    this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? PremiumColors.secondary;
    
    return PremiumCard(
      onTap: onTap,
      showGlow: true,
      child: Row(
        children: [
          // Icon with gradient background
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent,
                  accent.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI RECOMMENDATION',
                      style: PremiumTypography.labelSmall.copyWith(
                        color: accent,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: PremiumTypography.heading3,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: PremiumTypography.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Metric
          if (metric != null) ...[
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  metric!,
                  style: PremiumTypography.heading2.copyWith(
                    color: accent,
                  ),
                ),
                if (metricLabel != null)
                  Text(
                    metricLabel!,
                    style: PremiumTypography.bodySmall,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

