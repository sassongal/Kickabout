import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/widgets/optimized_image.dart';

/// Player avatar widget matching Figma design with status ring
class PlayerAvatar extends StatelessWidget {
  final User user;
  final double? radius;
  final bool showName;
  final bool clickable;
  final AvatarSize? size; // New size enum for Figma design

  const PlayerAvatar({
    super.key,
    required this.user,
    this.radius,
    this.size,
    this.showName = false,
    this.clickable = true,
  }) : assert(radius == null || size == null, 'Cannot specify both radius and size');

  // Get radius from size or use provided radius
  double get _radius {
    if (radius != null) return radius!;
    switch (size ?? AvatarSize.md) {
      case AvatarSize.sm:
        return 20; // 40px / 2
      case AvatarSize.md:
        return 32; // 64px / 2
      case AvatarSize.lg:
        return 48; // 96px / 2
      case AvatarSize.xl:
        return 64; // 128px / 2
    }
  }

  // Get ring radius (slightly larger than avatar)
  double get _ringRadius {
    switch (size ?? AvatarSize.md) {
      case AvatarSize.sm:
        return 22; // 44px / 2
      case AvatarSize.md:
        return 34; // 68px / 2
      case AvatarSize.lg:
        return 50; // 100px / 2
      case AvatarSize.xl:
        return 68; // 136px / 2
    }
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return const Color(0xFF4CAF50); // Green
      case 'busy':
        return const Color(0xFFFF9800); // Orange
      case 'notAvailable':
      case 'unavailable':
        return const Color(0xFFF44336); // Red
      default:
        return Colors.grey;
    }
  }

  // Get user initials - prefer firstName/lastName if available
  String _getInitials() {
    // Use firstName and lastName if available
    if (user.firstName != null && user.lastName != null) {
      final first = user.firstName!.isNotEmpty ? user.firstName![0] : '';
      final last = user.lastName!.isNotEmpty ? user.lastName![0] : '';
      if (first.isNotEmpty && last.isNotEmpty) {
        return (first + last).toUpperCase();
      }
      if (first.isNotEmpty) return first.toUpperCase();
      if (last.isNotEmpty) return last.toUpperCase();
    }
    
    // Fallback to splitting name
    final parts = user.name.split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatarRadius = _radius;
    final ringRadius = radius == null ? _ringRadius : avatarRadius + 4; // Add 4px for ring if using custom radius
    final hasStatus = user.availabilityStatus.isNotEmpty;
    final statusColor = hasStatus ? _getStatusColor(user.availabilityStatus) : null;

    // Build the avatar with status ring
    Widget avatarWidget = Stack(
      clipBehavior: Clip.none,
      children: [
        // Status ring (conic gradient - 270 degrees)
        if (hasStatus && statusColor != null)
          Positioned(
            left: -2,
            top: -2,
            child: CustomPaint(
              size: Size(ringRadius * 2, ringRadius * 2),
              painter: _StatusRingPainter(
                color: statusColor,
                ringWidth: 2,
              ),
            ),
          ),
        // Avatar circle
        Container(
          width: avatarRadius * 2,
          height: avatarRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1976D2), Color(0xFF9C27B0)], // Blue to purple
            ),
          ),
          child: user.photoUrl != null && user.photoUrl!.isNotEmpty
              ? ClipOval(
                  child: OptimizedImage(
                    imageUrl: user.photoUrl!,
                    width: avatarRadius * 2,
                    height: avatarRadius * 2,
                    fit: BoxFit.cover,
                    errorWidget: _buildInitialsAvatar(avatarRadius),
                  ),
                )
              : _buildInitialsAvatar(avatarRadius),
        ),
      ],
    );

    // Wrap with click handler if clickable
    if (clickable) {
      avatarWidget = InkWell(
        onTap: () => context.push('/profile/${user.uid}'),
        borderRadius: BorderRadius.circular(avatarRadius),
        child: avatarWidget,
      );
    }

    // Add name if needed - prefer firstName/lastName if available
    if (showName) {
      final displayName = (user.firstName != null && user.lastName != null)
          ? '${user.firstName} ${user.lastName}'
          : user.name;
      
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          avatarWidget,
          const SizedBox(height: 4),
          Text(
            displayName,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return avatarWidget;
  }

  Widget _buildInitialsAvatar(double radius) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1976D2), Color(0xFF9C27B0)],
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(),
          style: GoogleFonts.montserrat(
            fontSize: radius * 0.6,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Status ring painter - draws a conic gradient ring (270 degrees)
class _StatusRingPainter extends CustomPainter {
  final Color color;
  final double ringWidth;

  _StatusRingPainter({
    required this.color,
    this.ringWidth = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - ringWidth) / 2;

    // Draw conic gradient ring (270 degrees filled, 90 degrees transparent)
    // We'll draw 3/4 of the circle
    final paint = Paint()
      ..color = color
      ..strokeWidth = ringWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw arc from -90 degrees (top) for 270 degrees (3/4 circle)
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2, // Start at top (-90 degrees)
      math.pi * 1.5, // 270 degrees (3/4 of circle)
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_StatusRingPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.ringWidth != ringWidth;
  }
}

/// Avatar size enum matching Figma design
enum AvatarSize {
  sm, // 40px
  md, // 64px
  lg, // 96px
  xl, // 128px
}
