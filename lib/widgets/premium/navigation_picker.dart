import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// A premium navigation picker bottom sheet that allows users to choose
/// between Google Maps and Waze for navigation.
class NavigationPicker extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? title;

  const NavigationPicker({
    super.key,
    required this.latitude,
    required this.longitude,
    this.title,
  });

  /// Shows the navigation picker bottom sheet
  static Future<void> show(
    BuildContext context, {
    required double latitude,
    required double longitude,
    String? title,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => NavigationPicker(
        latitude: latitude,
        longitude: longitude,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'בחר אפליקציית ניווט',
            style: PremiumTypography.heading3.copyWith(color: Colors.white),
          ),
          if (title != null) ...[
            const SizedBox(height: 8),
            Text(
              title!,
              style: PremiumTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavigationOption(
                label: 'Google Maps',
                iconPath:
                    'assets/icons/google_maps.png', // Fallback to icon if missing
                iconData: Icons.map,
                color: const Color(0xFF4285F4),
                onTap: () => _launchGoogleMaps(context),
              ),
              _NavigationOption(
                label: 'Waze',
                iconPath:
                    'assets/icons/waze.png', // Fallback to icon if missing
                iconData: Icons.navigation,
                color: const Color(0xFF33CCFF),
                onTap: () => _launchWaze(context),
              ),
            ],
          ),

          const SizedBox(height: 32),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ביטול',
              style: PremiumTypography.labelLarge.copyWith(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _launchGoogleMaps(BuildContext context) async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (context.mounted) Navigator.pop(context);
    } else {
      _showError(context);
    }
  }

  Future<void> _launchWaze(BuildContext context) async {
    final url = Uri.parse('waze://?ll=$latitude,$longitude&navigate=yes');
    final fallbackUrl =
        Uri.parse('https://waze.com/ul?ll=$latitude,$longitude&navigate=yes');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (context.mounted) Navigator.pop(context);
    } else if (await canLaunchUrl(fallbackUrl)) {
      await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      if (context.mounted) Navigator.pop(context);
    } else {
      _showError(context);
    }
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('לא ניתן לפתוח את האפליקציה')),
    );
  }
}

class _NavigationOption extends StatelessWidget {
  final String label;
  final String iconPath;
  final IconData iconData;
  final Color color;
  final VoidCallback onTap;

  const _NavigationOption({
    required this.label,
    required this.iconPath,
    required this.iconData,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        width: 130,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                iconData,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: PremiumTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
