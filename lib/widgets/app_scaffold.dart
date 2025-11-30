import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/widgets/futuristic/bottom_navigation_bar.dart';
import 'package:kattrick/widgets/futuristic/offline_indicator.dart';

/// App scaffold with AppBar and Hebrew titles
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final bool forceBottomNav;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final bool showBottomNav;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.forceBottomNav = false,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = true,
    this.showBottomNav = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        automaticallyImplyLeading: showBackButton,
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showBottomNav || forceBottomNav
          ? FuturisticBottomNavBar(currentRoute: currentRoute)
          : null,
    );
  }
}
