import 'package:flutter/material.dart';
import 'package:kickabout/theme/futuristic_theme.dart';
import 'package:kickabout/widgets/futuristic/app_bar_with_logo.dart';

/// Futuristic scaffold with custom AppBar styling
class FuturisticScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;

  const FuturisticScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FuturisticColors.background,
      appBar: AppBarWithLogo(
        title: title,
        actions: actions,
        showBackButton: showBackButton,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: FuturisticColors.backgroundGradient,
        ),
        child: body,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

