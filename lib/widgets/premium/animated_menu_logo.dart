import 'package:flutter/material.dart';

class AnimatedMenuLogo extends StatefulWidget {
  final double size;

  const AnimatedMenuLogo({super.key, this.size = 90.0});

  @override
  State<AnimatedMenuLogo> createState() => _AnimatedMenuLogoState();
}

class _AnimatedMenuLogoState extends State<AnimatedMenuLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
      Scaffold.of(context).openDrawer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(4.0),
          child: Image.asset(
            'assets/logo/KattruckLOGOFULL.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.menu, size: 32),
          ),
        ),
      ),
    );
  }
}
