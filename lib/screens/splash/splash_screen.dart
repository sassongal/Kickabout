import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/core/app_assets.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';

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
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    
    // Ball trajectory animation
    _ballController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
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
    
    _startAnimations();
  }

  void _startAnimations() async {
    // Start ball animation
    if (mounted) {
      _ballController.forward();
    }
    
    // Wait for ball to reach center, then show logo
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _logoController.forward();
    }
    
    // Navigate after animations complete (shorter delay for better UX)
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted && context.mounted) {
      // Navigate to welcome screen (router will handle redirects)
      context.go('/welcome');
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
        fit: StackFit.expand,
        children: [
          // Background gradient (always visible)
          Container(
            decoration: const BoxDecoration(
              gradient: FuturisticColors.backgroundGradient,
            ),
          ),
          // Loading screen image - full screen (with fallback)
          AnimatedBuilder(
            animation: _logoScale,
            builder: (context, child) {
              return Opacity(
                opacity: _logoScale.value.clamp(0.0, 1.0), // Clamp to valid range
                child: Image.asset(
                  AppAssets.splashLoading,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to gradient if image fails to load
                    return const SizedBox.shrink(); // Already have gradient background
                  },
                ),
              );
            },
          ),
          // Loading indicator (always visible)
          const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
          
          // Optional: Add a subtle overlay for better text visibility if needed
          // Container(
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //       begin: Alignment.topCenter,
          //       end: Alignment.bottomCenter,
          //       colors: [
          //         Colors.transparent,
          //         FuturisticColors.background.withValues(alpha: 0.3),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
