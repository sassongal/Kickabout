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
        fit: StackFit.expand,
        children: [
          // Loading screen image - full screen
          AnimatedBuilder(
            animation: _logoScale,
            builder: (context, child) {
              return Opacity(
                opacity: _logoScale.value,
                child: Image.asset(
                  AppAssets.splashLoading,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to gradient if image fails to load
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: FuturisticColors.backgroundGradient,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                ),
              );
            },
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

