import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/widgets/common/premium_scaffold.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/widgets/premium/loading_state.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// Privacy Settings Screen - Control what data is visible in search and profile
class PrivacySettingsScreen extends ConsumerStatefulWidget {
  final String userId;

  const PrivacySettingsScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  bool _isLoading = false;
  User? _currentUser;
  Map<String, bool> _privacySettings = {};

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
          _privacySettings = Map<String, bool>.from(user.privacySettings);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _savePrivacySettings() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      final updatedUser = _currentUser!.copyWith(
        privacySettings: Map<String, bool>.from(_privacySettings),
      );

      await usersRepo.setUser(updatedUser);

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          'הגדרות הפרטיות עודכנו בהצלחה!',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updatePrivacySetting(String key, bool value) {
    setState(() {
      _privacySettings[key] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return PremiumScaffold(
        title: 'הגדרות פרטיות',
        body: const PremiumLoadingState(message: 'טוען הגדרות...'),
      );
    }

    return PremiumScaffold(
      title: 'הגדרות פרטיות',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: PremiumColors.info,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'מידע',
                        style: PremiumTypography.techHeadline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'בחר אילו נתונים להציג בפרופיל שלך ובחיפוש. נתונים מוסתרים לא יופיעו למשתמשים אחרים.',
                    style: PremiumTypography.bodyMedium,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Privacy Settings
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'הגדרות פרטיות',
                    style: PremiumTypography.techHeadline,
                  ),
                  const SizedBox(height: 16),
                  
                  // Hide from Search
                  _buildPrivacySwitch(
                    'הסתר מהחיפוש',
                    'אם מופעל, הפרופיל שלך לא יופיע בתוצאות חיפוש',
                    'hideFromSearch',
                    Icons.search_off,
                  ),
                  
                  const Divider(),
                  
                  // Hide Email
                  _buildPrivacySwitch(
                    'הסתר אימייל',
                    'האימייל שלך לא יוצג בפרופיל',
                    'hideEmail',
                    Icons.email_outlined,
                  ),
                  
                  const Divider(),
                  
                  // Hide Phone
                  _buildPrivacySwitch(
                    'הסתר טלפון',
                    'מספר הטלפון שלך לא יוצג בפרופיל',
                    'hidePhone',
                    Icons.phone_outlined,
                  ),
                  
                  const Divider(),
                  
                  // Hide City
                  _buildPrivacySwitch(
                    'הסתר עיר',
                    'עיר המגורים שלך לא תוצג בפרופיל',
                    'hideCity',
                    Icons.location_city_outlined,
                  ),
                  
                  const Divider(),
                  
                  // Hide Stats
                  _buildPrivacySwitch(
                    'הסתר סטטיסטיקות',
                    'הסטטיסטיקות שלך (שערים, אסיסטים וכו\') לא יוצגו',
                    'hideStats',
                    Icons.analytics_outlined,
                  ),
                  
                  const Divider(),
                  
                  // Hide Ratings
                  _buildPrivacySwitch(
                    'הסתר דירוגים',
                    'הדירוגים והגרפים שלך לא יוצגו',
                    'hideRatings',
                    Icons.trending_up_outlined,
                  ),

                  const Divider(),

                  // Allow hub invites
                  _buildPrivacySwitch(
                    'אפשר לקבל הזמנות להאבים',
                    'אם מכובה, עדיין יראו אותך בחיפוש אבל לא יוכלו לשלוח לך הזמנת הצטרפות',
                    'allowHubInvites',
                    Icons.group_add_outlined,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Save Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _savePrivacySettings,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'שומר...' : 'שמור שינויים'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: PremiumColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySwitch(
    String title,
    String description,
    String key,
    IconData icon,
  ) {
    final value = _privacySettings[key] ?? false;
    
    return SwitchListTile(
      value: value,
      onChanged: (newValue) => _updatePrivacySetting(key, newValue),
      title: Row(
        children: [
          Icon(icon, size: 20, color: PremiumColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            title,
            style: PremiumTypography.labelLarge,
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 28, top: 4),
        child: Text(
          description,
          style: PremiumTypography.bodySmall,
        ),
      ),
      activeTrackColor: PremiumColors.primary.withValues(alpha: 0.5),
      activeThumbColor: PremiumColors.primary,
    );
  }
}
