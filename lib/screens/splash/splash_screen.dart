import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/core/app_assets.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// Premium splash screen with animated logo
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _glowController;
  late AnimationController _rotationController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotation;
  late Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();

    // Logo scale and fade animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    // Subtle rotation animation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoRotation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.easeInOut,
      ),
    );

    // Glow pulse animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowOpacity = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    // Start logo animation
    if (mounted) {
      _logoController.forward();
      _rotationController.repeat(reverse: true);
    }

    // Navigate after animations complete
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted && context.mounted) {
      // Navigate to welcome screen (router will handle redirects)
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient (always visible)
          Container(
            decoration: const BoxDecoration(
              gradient: PremiumColors.backgroundGradient,
            ),
          ),

          // Animated logo with multiple effects
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _logoController,
                _rotationController,
                _glowController,
              ]),
              builder: (context, child) {
                return Transform.rotate(
                  angle: _logoRotation.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Opacity(
                      opacity: _logoOpacity.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow effect behind logo
                          AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, child) {
                              return Container(
                                width: 300,
                                height: 300,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: PremiumColors.primary
                                          .withOpacity(_glowOpacity.value),
                                      blurRadius: 40,
                                      spreadRadius: 20,
                                    ),
                                    BoxShadow(
                                      color: PremiumColors.primary
                                          .withOpacity(_glowOpacity.value * 0.5),
                                      blurRadius: 60,
                                      spreadRadius: 30,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          // Logo image
                          Container(
                            constraints: const BoxConstraints(
                              maxWidth: 250,
                              maxHeight: 250,
                            ),
                            child: Image.asset(
                              AppAssets.logoFull,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to gradient if image fails to load
                                return Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: PremiumColors.primary.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.sports_soccer,
                                    size: 100,
                                    color: PremiumColors.primary,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Loading indicator at the bottom
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _logoOpacity,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: const KineticLoadingAnimation(
                    size: 40,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
