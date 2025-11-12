import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kickabout/theme/futuristic_theme.dart';
import 'package:kickabout/widgets/kicka_ball_logo.dart';

/// Futuristic splash screen with animated football trajectory
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _ballController;
  late AnimationController _logoController;
  late AnimationController _glowController;
  late Animation<Offset> _ballAnimation;
  late Animation<double> _logoScale;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Ball trajectory animation
    _ballController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _ballAnimation = Tween<Offset>(
      begin: const Offset(-0.5, 0.5),
      end: const Offset(0.5, -0.3),
    ).animate(CurvedAnimation(
      parent: _ballController,
      curve: Curves.easeInOut,
    ));
    
    // Logo scale animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );
    
    // Glow pulse animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _startAnimations();
  }

  void _startAnimations() async {
    // Start ball animation
    _ballController.forward();
    
    // Wait for ball to reach center, then show logo
    await Future.delayed(const Duration(milliseconds: 1000));
    _logoController.forward();
    
    // Navigate after animations complete
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _ballController.dispose();
    _logoController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FuturisticColors.background,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: FuturisticColors.backgroundGradient,
            ),
          ),
          
          // Animated ball trajectory
          AnimatedBuilder(
            animation: _ballAnimation,
            builder: (context, child) {
              return Positioned(
                left: MediaQuery.of(context).size.width * 
                    (0.5 + _ballAnimation.value.dx),
                top: MediaQuery.of(context).size.height * 
                    (0.5 + _ballAnimation.value.dy),
                child: Transform.scale(
                  scale: 1.0 - (_ballController.value * 0.5),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          FuturisticColors.secondary,
                          FuturisticColors.secondary.withValues(alpha: 0.3),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: FuturisticColors.secondary.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.sports_soccer,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Logo in center
          Center(
            child: AnimatedBuilder(
              animation: _logoScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoScale.value,
                  child: AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              FuturisticColors.primary.withValues(alpha: 0.3),
                              FuturisticColors.primary.withValues(alpha: 0.1),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: FuturisticColors.secondary.withValues(
                                alpha: _glowAnimation.value * 0.5,
                              ),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            KickaBallLogo(
                              size: 120,
                              showText: false,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'עתיד הכדורגל',
                              style: FuturisticTypography.bodySmall.copyWith(
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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

