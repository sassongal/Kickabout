import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/widgets/common/premium_scaffold.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/utils/venue_seeder_service.dart';

/// Admin Dashboard Screen - Central hub for admin operations
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isSeeding = false;
  String _seedingStatus = '';

  Future<void> _seedVenues() async {
    setState(() {
      _isSeeding = true;
      _seedingStatus = 'מאכלס מגרשים...';
    });

    try {
      final seeder = ref.read(venueSeederServiceProvider);
      await seeder.seedMajorCities();

      if (mounted) {
        setState(() {
          _isSeeding = false;
          _seedingStatus = 'הושלם!';
        });
        SnackbarHelper.showSuccess(context, 'אכלוס מגרשים הסתיים בהצלחה!');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSeeding = false;
          _seedingStatus = 'שגיאה: $e';
        });
        SnackbarHelper.showError(context, 'שגיאה באכלוס: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: 'Admin Console',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'ניהול מערכת',
              style: PremiumTypography.heading1.copyWith(
                color: PremiumColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'כלים לניהול ותחזוקת המערכת',
              style: PremiumTypography.bodyMedium.copyWith(
                color: PremiumColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Admin Tools Grid
            _buildAdminTile(
              title: 'Generate Dummy Data',
              subtitle: 'צור נתוני בדיקה (משתמשים, משחקים, האבים)',
              icon: Icons.science,
              color: Colors.blue,
              onTap: () => context.push('/admin/generate-dummy-data'),
            ),
            const SizedBox(height: 16),

            _buildAdminTile(
              title: 'Seed Venues DB',
              subtitle: 'אכלס מגרשים מ-Google Places (ערים מרכזיות)',
              icon: Icons.stadium,
              color: Colors.orange,
              isLoading: _isSeeding,
              statusText: _seedingStatus,
              onTap: _isSeeding ? null : _seedVenues,
            ),
            const SizedBox(height: 16),

            _buildAdminTile(
              title: 'Review Venue Edits',
              subtitle: 'בקר והאשר הצעות עריכה למגרשים',
              icon: Icons.rate_review,
              color: Colors.purple,
              onTap: () {
                // TODO: Implement venue edit review screen
                SnackbarHelper.showInfo(context, 'בקרוב - מסך אישור עריכות');
              },
            ),
            const SizedBox(height: 16),

            _buildAdminTile(
              title: 'System Analytics',
              subtitle: 'נתונים סטטיסטיים על השימוש במערכת',
              icon: Icons.analytics,
              color: Colors.green,
              onTap: () {
                // TODO: Implement analytics screen
                SnackbarHelper.showInfo(context, 'בקרוב - דשבורד אנליטיקה');
              },
            ),
            const SizedBox(height: 16),

            _buildAdminTile(
              title: 'User Management',
              subtitle: 'ניהול משתמשים והרשאות',
              icon: Icons.people,
              color: Colors.teal,
              onTap: () {
                // TODO: Implement user management screen
                SnackbarHelper.showInfo(context, 'בקרוב - ניהול משתמשים');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool isLoading = false,
    String? statusText,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3), width: 2),
      ),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: PremiumTypography.heading3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: PremiumTypography.bodySmall.copyWith(
                        color: PremiumColors.textSecondary,
                      ),
                    ),
                    if (statusText != null && statusText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        statusText,
                        style: PremiumTypography.bodySmall.copyWith(
                          color: isLoading ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Loading or Arrow
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
