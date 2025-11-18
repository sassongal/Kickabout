import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kickadoor/widgets/futuristic/gradient_button.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_card.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickadoor/routing/app_router.dart';

/// Onboarding screen with tutorial walkthrough
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'ברוכים הבאים ל-Kickadoor!',
      description: 'הרשת החברתית לכדורגל שכונתי בישראל',
      icon: Icons.sports_soccer,
      color: FuturisticColors.primary,
    ),
    OnboardingPage(
      title: 'מצא שחקנים ו-Hubs',
      description: 'גלה שחקנים לידך, הצטרף ל-Hubs, וצור קהילה פעילה',
      icon: Icons.people,
      color: FuturisticColors.secondary,
    ),
    OnboardingPage(
      title: 'ארגן משחקים',
      description: 'צור משחקים, הרשם למשחקים, וצור קבוצות מאוזנות',
      icon: Icons.event,
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'דרג ועקוב אחרי ביצועים',
      description: 'דרג שחקנים, עקוב אחרי הסטטיסטיקות שלך, וצבור נקודות',
      icon: Icons.analytics,
      color: Colors.purple,
    ),
    OnboardingPage(
      title: 'התחבר לקהילה',
      description: 'פוסטים, צ\'אט, הודעות פרטיות - הכל במקום אחד',
      icon: Icons.chat,
      color: Colors.green,
    ),
    OnboardingPage(
      title: 'הרשאות',
      description: 'אנחנו זקוקים להרשאות כדי לספק לך חוויה מיטבית',
      icon: Icons.security,
      color: Colors.orange,
      isPermissionsPage: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    // If on permissions page, only request notification permission
    // Other permissions will be requested Just-in-Time when needed
    if (_currentPage == _pages.length - 2 && _pages[_currentPage].isPermissionsPage == true) {
      await _requestNotificationPermission();
    }
    
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  /// Request only notification permission during onboarding
  /// Other permissions (location, camera) will be requested Just-in-Time when needed
  Future<void> _requestNotificationPermission() async {
    try {
      // Only request notification permission here
      // This is the only permission that makes sense to request upfront
      // as it's needed for game reminders and messages
      final notificationStatus = await Permission.notification.request();
      if (notificationStatus.isDenied) {
        debugPrint('Notification permission denied');
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      
      // Invalidate the provider to force it to reload with the new value
      if (mounted) {
        try {
          final container = ProviderScope.containerOf(context);
          container.invalidate(onboardingStatusProvider);
          
          // Wait a bit for the provider to reload
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          debugPrint('Error invalidating provider: $e');
          // Continue anyway - the router might still work
        }
        
        // Now navigate - the router will see the updated value
        context.go('/');
      }
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      if (mounted) {
        // Even if saving fails, try to navigate
        // The router will handle the redirect logic
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;
    
    // Figma design: No AppBar, Skip button top-left, content centered
    return Scaffold(
      backgroundColor: FuturisticColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: FuturisticColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button (only if not last page)
              if (!isLastPage)
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        'דלג',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: FuturisticColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),

              const Spacer(),
              
              // Bottom Section (Page indicators + Button)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // Page indicator (Figma style)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: index == _currentPage ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: index == _currentPage
                                ? FuturisticColors.primary
                                : FuturisticColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Next/Get Started button
                    GradientButton(
                      label: isLastPage ? 'התחל' : 'הבא',
                      icon: isLastPage ? Icons.check : Icons.arrow_forward,
                      onPressed: _nextPage,
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    if (page.isPermissionsPage) {
      return _buildPermissionsPage(page);
    }

    // Figma design: Icon 128px, Title, Description centered
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon (128px matching Figma)
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  page.color,
                  page.color.withValues(alpha: 0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: page.color.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),

          // Title (Figma style: Orbitron, 1.75rem)
          Text(
            page.title,
            style: GoogleFonts.orbitron(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: FuturisticColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description (Figma style: Inter, 1rem)
          Text(
            page.description,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: FuturisticColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsPage(OnboardingPage page) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 32), // Add top padding
            // Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    page.color,
                    page.color.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Icon(
                page.icon,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 48),

            // Title
            Text(
              page.title,
              style: FuturisticTypography.techHeadline.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              page.description,
              style: FuturisticTypography.bodyLarge.copyWith(
                fontSize: 18,
                color: FuturisticColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Permissions list (Figma style: FuturisticCard with icons)
            Column(
              children: [
                _buildPermissionItem(
                  Icons.notifications,
                  'התראות',
                  'לקבלת עדכונים על משחקים והודעות',
                  isRequested: true,
                ),
                const SizedBox(height: 12),
                _buildPermissionItem(
                  Icons.location_on,
                  'מיקום',
                  'יידרש בעת שימוש במפה או חיפוש הובים',
                  isRequested: false,
                ),
                const SizedBox(height: 12),
                _buildPermissionItem(
                  Icons.camera_alt,
                  'מצלמה',
                  'יידרש בעת צילום תמונות במשחקים',
                  isRequested: false,
                ),
              ],
            ),
            const SizedBox(height: 48), // Add spacing at bottom for better scroll
          ],
        ),
    );
  }

  Widget _buildPermissionItem(
    IconData icon,
    String title,
    String description, {
    bool isRequested = false,
  }) {
    // Figma design: White card with icon in colored background, check icon on right
    return FuturisticCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon in colored background
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: FuturisticColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: FuturisticColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Title and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: FuturisticColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: FuturisticColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Check icon (green if requested)
          Icon(
            Icons.check,
            color: isRequested 
                ? FuturisticColors.secondary 
                : FuturisticColors.textTertiary,
            size: 20,
          ),
        ],
      ),
    );
  }

}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isPermissionsPage;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isPermissionsPage = false,
  });
}

