import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/routing/app_paths.dart';

class HomeLogoButton extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onPressed;

  const HomeLogoButton({
    super.key,
    this.height = 32,
    this.padding = const EdgeInsets.all(4),
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Home',
      child: InkWell(
        onTap: onPressed ?? () => context.go(AppPaths.home),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: padding,
          child: Image.asset(
            'assets/logo/KattrickLOGO.png',
            height: height,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class AppBarHomeLogo extends StatelessWidget {
  static const double _logoOnlyWidth = kToolbarHeight;
  static const double _logoWithBackWidth = 112;

  final bool showBackButton;
  final VoidCallback? onBack;
  final IconData? backIcon;
  final String? backTooltip;
  final double logoHeight;
  final EdgeInsetsGeometry logoPadding;

  const AppBarHomeLogo({
    super.key,
    required this.showBackButton,
    this.onBack,
    this.backIcon,
    this.backTooltip,
    this.logoHeight = 32,
    this.logoPadding = const EdgeInsets.all(4),
  });

  static double leadingWidth({required bool showBackButton}) =>
      showBackButton ? _logoWithBackWidth : _logoOnlyWidth;

  @override
  Widget build(BuildContext context) {
    final resolvedBackAction = onBack ??
        () {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
          }
        };
    final Widget? resolvedBackButton = showBackButton
        ? (backIcon != null
            ? IconButton(
                icon: Icon(backIcon),
                tooltip: backTooltip ??
                    MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: resolvedBackAction,
              )
            : BackButton(onPressed: resolvedBackAction))
        : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeLogoButton(height: logoHeight, padding: logoPadding),
        if (resolvedBackButton != null) const SizedBox(width: 4),
        if (resolvedBackButton != null) resolvedBackButton,
      ],
    );
  }
}
