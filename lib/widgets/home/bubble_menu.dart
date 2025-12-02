import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kattrick/theme/futuristic_theme.dart';

/// Bubble Menu Item - פריט בתפריט הבועות
class BubbleMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const BubbleMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

/// Bubble Menu - תפריט צף מונפש בהשראת ReactBits
class BubbleMenu extends StatefulWidget {
  final List<BubbleMenuItem> items;

  const BubbleMenu({
    super.key,
    required this.items,
  });

  @override
  State<BubbleMenu> createState() => _BubbleMenuState();
}

class _BubbleMenuState extends State<BubbleMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.125, // 45 degrees = 1/8 turn
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        // רקע שקוף כשהתפריט פתוח - סגירה בלחיצה
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleMenu,
              child: Container(
                color: Colors.black
                    .withValues(alpha: 0.8), // Darker backdrop for focus
              ),
            ),
          ),

        // פריטי התפריט - במרכז המסך
        if (_isExpanded)
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.items.length, (index) {
                  final item = widget.items[index];
                  // Reverse index for animation delay (bottom items animate first if we want, or top first)
                  // Let's animate from top to bottom
                  final delay = index * 0.1;

                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final slideValue = Curves.easeOutBack.transform(
                        (_controller.value - delay).clamp(0.0, 1.0),
                      );

                      return Transform.scale(
                        scale: slideValue,
                        child: Opacity(
                          opacity: slideValue.clamp(0.0, 1.0),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: _BubbleItem(
                      icon: item.icon,
                      label: item.label,
                      color: item.color ?? FuturisticColors.primary,
                      onTap: () {
                        _toggleMenu();
                        item.onTap();
                      },
                    ),
                  );
                }),
              ),
            ),
          ),

        // הכפתור הראשי - צף משמאל למטה
        Positioned(
          bottom: 16,
          left: 16,
          child: GestureDetector(
            onTap: _toggleMenu,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value * 3.14159 * 2,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          FuturisticColors.primary,
                          FuturisticColors.primaryDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color:
                              FuturisticColors.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isExpanded ? Icons.close : Icons.add,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// פריט בועה בודד
class _BubbleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BubbleItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // הבועה
          Container(
            width: 60, // Larger bubble
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: color.withValues(alpha: 0.5), // Stronger border
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3), // Stronger glow
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 30, // Larger icon
            ),
          ),
          const SizedBox(height: 10), // More spacing
          // התווית
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black
                  .withValues(alpha: 0.8), // High contrast background
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12, // Larger text
                fontWeight: FontWeight.w700, // Bolder
                color: Colors.white, // White text on dark bg
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick Actions Bubble Menu - תפריט עם כל הפעולות המהירות
class QuickActionsBubbleMenu extends StatelessWidget {
  const QuickActionsBubbleMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BubbleMenu(
      items: [
        BubbleMenuItem(
          icon: Icons.group_add,
          label: 'צור האב',
          color: FuturisticColors.primary,
          onTap: () => context.push('/hubs/create'),
        ),
        BubbleMenuItem(
          icon: Icons.explore,
          label: 'גלה',
          color: FuturisticColors.secondary,
          onTap: () => context.push('/discover'),
        ),
        BubbleMenuItem(
          icon: Icons.person_search,
          label: 'מצא שחקנים',
          color: FuturisticColors.accent,
          onTap: () => context.push('/players'),
        ),
        BubbleMenuItem(
          icon: Icons.sports_soccer,
          label: 'צור משחק',
          color: const Color(0xFFFF6B35),
          onTap: () => context.push('/games/create'),
        ),
      ],
    );
  }
}
