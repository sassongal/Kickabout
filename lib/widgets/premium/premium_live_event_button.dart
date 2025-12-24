import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium "אירוע LIVE" button with pulsing animation
class PremiumLiveEventButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const PremiumLiveEventButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<PremiumLiveEventButton> createState() => _PremiumLiveEventButtonState();
}

class _PremiumLiveEventButtonState extends State<PremiumLiveEventButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late AnimationController _pulseDotController;
  late Animation<double> _pulseDotAnimation;

  @override
  void initState() {
    super.initState();
    
    // Main pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Pulsing dot animation (faster)
    _pulseDotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseDotAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseDotController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pulseDotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _pulseDotController]),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.onPressed != null && !widget.isLoading
              ? _scaleAnimation.value
              : 1.0,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF1744), // Red
                  Color(0xFFFF5252), // Light Red
                  Color(0xFFFF6B6B), // Lighter Red
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.onPressed != null && !widget.isLoading
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF1744).withOpacity(
                          _glowAnimation.value * 0.7,
                        ),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFF5252).withOpacity(
                          _glowAnimation.value * 0.5,
                        ),
                        blurRadius: 30,
                        spreadRadius: 6,
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onPressed,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else ...[
                        // Pulsing dot
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(
                                  _pulseDotAnimation.value * 0.8,
                                ),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'אירוע LIVE',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.0,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.play_circle_filled,
                          size: 24,
                          color: Colors.white,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

