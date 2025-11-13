import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:kickadoor/widgets/futuristic/app_bar_with_logo.dart';
import 'package:kickadoor/widgets/futuristic/bottom_navigation_bar.dart';
import 'package:kickadoor/widgets/futuristic/offline_indicator.dart';

/// Futuristic scaffold with custom AppBar styling
class FuturisticScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final bool showBottomNav;

  const FuturisticScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = true,
    this.showBottomNav = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: FuturisticColors.background,
      appBar: AppBarWithLogo(
        title: title,
        actions: actions,
        showBackButton: showBackButton,
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: FuturisticColors.backgroundGradient,
              ),
              child: body,
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showBottomNav
          ? FuturisticBottomNavBar(currentRoute: currentRoute)
          : null,
    );
  }
}

