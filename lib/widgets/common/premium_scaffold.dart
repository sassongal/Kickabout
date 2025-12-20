import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/premium/app_bar_with_logo.dart';
import 'package:kattrick/widgets/premium/bottom_navigation_bar.dart';
import 'package:kattrick/widgets/premium/offline_indicator.dart';

import 'package:kattrick/widgets/premium/kinetic_background.dart';

/// Premium scaffold with custom AppBar styling
class PremiumScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final bool showBottomNav;

  const PremiumScaffold({
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
      backgroundColor: PremiumColors.background,
      appBar: AppBarWithLogo(
        title: title,
        actions: actions,
        showBackButton: showBackButton,
      ),
      body: KineticBackground(
        child: Column(
          children: [
            const OfflineIndicator(),
            Expanded(
              child: body,
            ),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showBottomNav
          ? PremiumBottomNavBar(currentRoute: currentRoute)
          : null,
    );
  }
}
