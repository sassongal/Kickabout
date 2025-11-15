import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/gradient_button.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:permission_handler/permission_handler.dart';

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
    // If on permissions page, request permissions
    if (_currentPage == _pages.length - 2 && _pages[_currentPage].isPermissionsPage == true) {
      await _requestPermissions();
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

  Future<void> _requestPermissions() async {
    try {
      // Request location permission
      final locationStatus = await Permission.location.request();
      if (locationStatus.isDenied) {
        debugPrint('Location permission denied');
      }

      // Request notification permission
      final notificationStatus = await Permission.notification.request();
      if (notificationStatus.isDenied) {
        debugPrint('Notification permission denied');
      }

      // Request camera permission (for photos)
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus.isDenied) {
        debugPrint('Camera permission denied');
      }

      // Request storage permission (for photos)
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isDenied) {
        debugPrint('Storage permission denied');
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FuturisticScaffold(
      title: 'KICKADOOR',
      showBackButton: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: FuturisticColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      'דלג',
                      style: FuturisticTypography.labelMedium,
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

              // Page indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildPageIndicator(index == _currentPage),
                ),
              ),

              const SizedBox(height: 24),

              // Next/Get Started button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: GradientButton(
                  label: _currentPage == _pages.length - 1 ? 'התחל' : 'הבא',
                  icon: _currentPage == _pages.length - 1 
                      ? Icons.check 
                      : Icons.arrow_forward,
                  onPressed: _nextPage,
                  width: double.infinity,
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

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
        ],
      ),
    );
  }

  Widget _buildPermissionsPage(OnboardingPage page) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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

            // Permissions list
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildPermissionItem(
                      Icons.location_on,
                      'מיקום',
                      'למציאת Hubs ומשחקים לידך',
                    ),
                    const Divider(),
                    _buildPermissionItem(
                      Icons.notifications,
                      'התראות',
                      'לקבלת עדכונים על משחקים והודעות',
                    ),
                    const Divider(),
                    _buildPermissionItem(
                      Icons.camera_alt,
                      'מצלמה',
                      'לצילום תמונות במשחקים',
                    ),
                    const Divider(),
                    _buildPermissionItem(
                      Icons.photo_library,
                      'גלריה',
                      'לשיתוף תמונות מהמשחקים',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: FuturisticColors.secondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: FuturisticTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: FuturisticTypography.bodySmall.copyWith(
                    color: FuturisticColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive 
            ? FuturisticColors.secondary 
            : FuturisticColors.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
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

