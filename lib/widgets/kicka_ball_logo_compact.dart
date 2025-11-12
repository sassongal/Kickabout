import 'package:flutter/material.dart';
import 'package:kickabout/widgets/kicka_ball_logo.dart';

/// Compact version of KICKADOOR logo for small spaces (AppBar, etc.)
class KickaBallLogoCompact extends StatelessWidget {
  final double size;

  const KickaBallLogoCompact({
    super.key,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return KickaBallLogo(
      size: size,
      showText: false,
    );
  }
}

