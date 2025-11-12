import 'package:flutter/material.dart';
import 'package:kickabout/widgets/kicka_ball_logo.dart';

/// Compact version of KICKA BALL logo for small spaces (AppBar, etc.)
class KickaBallLogoCompact extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final Color? secondaryColor;

  const KickaBallLogoCompact({
    super.key,
    this.size = 32,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KickaBallLogo(
      size: size,
      showText: false,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
    );
  }
}

