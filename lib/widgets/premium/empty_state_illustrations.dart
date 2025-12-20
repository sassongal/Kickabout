import 'package:flutter/material.dart';
import 'package:kattrick/theme/premium_theme.dart';

class EmptyHubsIllustration extends StatelessWidget {
  const EmptyHubsIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            PremiumColors.primary.withValues(alpha: 0.2),
            PremiumColors.secondary.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.sports_soccer,
            size: 80,
            color: PremiumColors.primary.withValues(alpha: 0.4),
          ),
          Positioned(
            right: 30,
            top: 30,
            child: Icon(
              Icons.search,
              size: 40,
              color: PremiumColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyGamesIllustration extends StatelessWidget {
  const EmptyGamesIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: PremiumColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            child: Icon(
              Icons.directions_run,
              size: 60,
              color: PremiumColors.primary.withValues(alpha: 0.5),
            ),
          ),
          Icon(
            Icons.block,
            size: 40,
            color: Colors.red.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

class EmptyNotificationsIllustration extends StatelessWidget {
  const EmptyNotificationsIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 2),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * 0.1,
                child: Icon(
                  Icons.notifications_none_outlined,
                  size: 100,
                  color: PremiumColors.primary.withValues(alpha: 0.2),
                ),
              );
            },
          ),
          Icon(
            Icons.check_circle_outline,
            size: 40,
            color: Colors.green.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}
