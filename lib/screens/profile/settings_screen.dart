import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kattrick/widgets/futuristic/futuristic_card.dart';
import 'package:kattrick/widgets/futuristic/loading_state.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/theme/futuristic_theme.dart';

/// Settings Screen - Account settings and logout
class SettingsScreen extends ConsumerStatefulWidget {
  final String userId;

  const SettingsScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      final user = await usersRepo.getUser(widget.userId);
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FuturisticColors.surface,
        title: Text(
          'התנתקות',
          style: FuturisticTypography.heading3.copyWith(
            color: FuturisticColors.textPrimary,
          ),
        ),
        content: Text(
          'האם אתה בטוח שברצונך להתנתק?',
          style: FuturisticTypography.bodyMedium.copyWith(
            color: FuturisticColors.textSecondary,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: FuturisticColors.surfaceVariant,
            width: 1,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'ביטול',
              style: FuturisticTypography.labelLarge.copyWith(
                color: FuturisticColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FuturisticColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'התנתק',
              style: FuturisticTypography.labelLarge,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return; // User cancelled
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          'התנתקת בהצלחה',
        );

        // Navigate to auth screen (replace current route)
        context.go('/auth');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'שגיאה בהתנתקות: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _currentUser == null) {
      return FuturisticScaffold(
        title: 'הגדרות',
        body: const FuturisticLoadingState(message: 'טוען הגדרות...'),
      );
    }

    return FuturisticScaffold(
      title: 'הגדרות',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Account Section
            _buildSectionHeader('חשבון'),
            const SizedBox(height: 8),
            FuturisticCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.edit,
                    title: 'ערוך פרופיל',
                    subtitle: 'עדכן את פרטי הפרופיל שלך',
                    onTap: () => context.push('/profile/${widget.userId}/edit'),
                  ),
                  const Divider(height: 1, color: FuturisticColors.surfaceVariant),
                  _buildSettingTile(
                    icon: Icons.privacy_tip,
                    title: 'הגדרות פרטיות',
                    subtitle: 'נהל את הגדרות הפרטיות שלך',
                    onTap: () => context.push('/profile/${widget.userId}/privacy'),
                  ),
                ],
              ),
            ),

            // Preferences Section
            _buildSectionHeader('העדפות'),
            const SizedBox(height: 8),
            FuturisticCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.notifications,
                    title: 'ניהול התראות',
                    subtitle: 'בחר אילו התראות לקבל',
                    onTap: () => context.push('/profile/${widget.userId}/notifications'),
                  ),
                  const Divider(height: 1, color: FuturisticColors.surfaceVariant),
                  _buildSettingTile(
                    icon: Icons.location_on,
                    title: 'מיקום',
                    subtitle: 'שיתוף מיקום אוטומטי',
                    onTap: () {
                      SnackbarHelper.showInfo(
                        context,
                        'הגדרות מיקום זמינות בהגדרות המכשיר',
                      );
                    },
                  ),
                ],
              ),
            ),

            // App Section
            _buildSectionHeader('אפליקציה'),
            const SizedBox(height: 8),
            FuturisticCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.info_outline,
                    title: 'אודות',
                    subtitle: 'מידע על האפליקציה',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: FuturisticColors.surface,
                          title: Text(
                            'אודות Kattrick',
                            style: FuturisticTypography.heading3.copyWith(
                              color: FuturisticColors.textPrimary,
                            ),
                          ),
                          content: Text(
                            'Kattrick - אפליקציית כדורגל קהילתית\n\n'
                            'חבר שחקנים, צור הובים, ארגן משחקים וצור קהילה סביב אהבת הכדורגל.',
                            style: FuturisticTypography.bodyMedium.copyWith(
                              color: FuturisticColors.textSecondary,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: FuturisticColors.surfaceVariant,
                              width: 1,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'סגור',
                                style: FuturisticTypography.labelLarge.copyWith(
                                  color: FuturisticColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: FuturisticColors.surfaceVariant),
                  _buildSettingTile(
                    icon: Icons.help_outline,
                    title: 'עזרה ותמיכה',
                    subtitle: 'שאלות נפוצות וצור קשר',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: FuturisticColors.surface,
                          title: Text(
                            'עזרה ותמיכה',
                            style: FuturisticTypography.heading3.copyWith(
                              color: FuturisticColors.textPrimary,
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'צריך עזרה?',
                                style: FuturisticTypography.bodyMedium.copyWith(
                                  color: FuturisticColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // TODO: Open email client or support form
                                  SnackbarHelper.showInfo(
                                    context,
                                    'שלח אימייל ל: support@kattrick.app',
                                  );
                                },
                                icon: const Icon(Icons.email),
                                label: const Text('צור קשר'),
                                style: TextButton.styleFrom(
                                  foregroundColor: FuturisticColors.primary,
                                ),
                              ),
                            ],
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: FuturisticColors.surfaceVariant,
                              width: 1,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'סגור',
                                style: FuturisticTypography.labelLarge.copyWith(
                                  color: FuturisticColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: FuturisticColors.surfaceVariant),
                  _buildSettingTile(
                    icon: Icons.description,
                    title: 'תנאי שימוש',
                    subtitle: 'קרא את תנאי השימוש',
                    onTap: () {
                      SnackbarHelper.showInfo(
                        context,
                        'תנאי השימוש זמינים באתר kattrick.app/terms',
                      );
                    },
                  ),
                  const Divider(height: 1, color: FuturisticColors.surfaceVariant),
                  _buildSettingTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'מדיניות פרטיות',
                    subtitle: 'קרא את מדיניות הפרטיות',
                    onTap: () {
                      SnackbarHelper.showInfo(
                        context,
                        'מדיניות הפרטיות זמינה באתר kattrick.app/privacy',
                      );
                    },
                  ),
                ],
              ),
            ),

            // Logout Section
            const SizedBox(height: 8),
            FuturisticCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: _buildSettingTile(
                icon: Icons.logout,
                title: 'התנתק',
                subtitle: 'התנתק מהחשבון שלך',
                iconColor: FuturisticColors.error,
                textColor: FuturisticColors.error,
                onTap: _handleLogout,
                showLoading: _isLoading,
              ),
            ),

            // User Info (if available)
            if (_currentUser != null) ...[
              const SizedBox(height: 24),
              _buildUserInfoCard(_currentUser!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title,
        style: FuturisticTypography.labelLarge.copyWith(
          color: FuturisticColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    bool showLoading = false,
  }) {
    return InkWell(
      onTap: showLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? FuturisticColors.primary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor ?? FuturisticColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FuturisticTypography.labelLarge.copyWith(
                      color: textColor ?? FuturisticColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: FuturisticTypography.bodySmall.copyWith(
                        color: FuturisticColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FuturisticColors.primary,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_left,
                color: FuturisticColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(User user) {
    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'מידע על החשבון',
            style: FuturisticTypography.labelLarge.copyWith(
              color: FuturisticColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (user.email.isNotEmpty)
            _buildInfoRow('אימייל', user.email),
          if (user.name.isNotEmpty)
            _buildInfoRow('שם', user.name),
          _buildInfoRow(
            'תאריך הצטרפות',
            _formatDate(user.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: FuturisticTypography.bodySmall.copyWith(
                color: FuturisticColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: FuturisticTypography.bodyMedium.copyWith(
                color: FuturisticColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

