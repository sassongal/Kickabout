import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kattrick/theme/premium_theme.dart';

class CommunityWelcomeCard extends StatelessWidget {
  const CommunityWelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: PremiumColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: PremiumShadows.md,
        border: Border.all(color: PremiumColors.border),
      ),
      child: Stack(
        children: [
          // Background decoration (subtle pattern or gradient)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    PremiumColors.primary.withValues(alpha: 0.05),
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Caster/Broadcaster Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: PremiumColors.primary, width: 2),
                    boxShadow: PremiumShadows.sm,
                    image: const DecorationImage(
                      image: AssetImage(
                          'assets/images/splash/referee_onboarding.png'), // Fallback/Placeholder
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Welcome Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ברוכים הבאים לקהילה!',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: PremiumColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'כאן תוכלו למצוא שחקנים, להצטרף להאבים, ולהתעדכן בכל מה שחם בכדורגל השכונתי. תהנו!',
                        style: PremiumTypography.bodySmall.copyWith(
                          color: PremiumColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
