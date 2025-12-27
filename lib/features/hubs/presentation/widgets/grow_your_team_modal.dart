import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/features/hubs/presentation/screens/add_manual_player_dialog.dart';
import 'package:kattrick/features/hubs/presentation/widgets/contact_picker_dialog.dart';
import 'package:share_plus/share_plus.dart';

/// Modal shown immediately after hub creation to help grow the team
class GrowYourTeamModal extends ConsumerWidget {
  final Hub hub;

  const GrowYourTeamModal({
    super.key,
    required this.hub,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: PremiumCard(
        elevation: PremiumCardElevation.xl,
        glassmorphism: true,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.group_add,
                    color: Theme.of(context).primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'בנה את הקבוצה שלך',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'הוסף שחקנים ל-${hub.name}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Option 1: Share via WhatsApp
            _buildOption(
              context,
              icon: Icons.share,
              iconColor: Colors.green,
              title: 'שתף קישור WhatsApp',
              description: 'שתף הזמנה לקבוצה עם החברים',
              onTap: () async {
                Navigator.of(context).pop();
                await _shareHubOnWhatsApp(context, hub);
              },
            ),
            const SizedBox(height: 12),

            // Option 2: Add from Contacts
            _buildOption(
              context,
              icon: Icons.contacts,
              iconColor: Colors.purple,
              title: 'הוסף מאנשי הקשר',
              description: 'בחר שחקן מרשימת אנשי הקשר',
              onTap: () async {
                Navigator.of(context).pop();
                await _addFromContacts(context, hub.hubId);
              },
            ),
            const SizedBox(height: 12),

            // Option 3: Add Manually
            _buildOption(
              context,
              icon: Icons.person_add,
              iconColor: const Color(0xFF2E7D32), // Forest green
              title: 'הוסף ידנית',
              description: 'הוסף שחקן בלי שהוא יוריד את האפליקציה',
              onTap: () async {
                Navigator.of(context).pop();
                await showDialog(
                  context: context,
                  builder: (context) => AddManualPlayerDialog(hubId: hub.hubId),
                );
              },
            ),
            const SizedBox(height: 24),

            // Skip button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'אעשה את זה מאוחר יותר',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return PremiumCard(
      onTap: onTap,
      elevation: PremiumCardElevation.sm,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
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
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  /// Share hub on WhatsApp
  Future<void> _shareHubOnWhatsApp(BuildContext context, Hub hub) async {
    try {
      // Generate deep link (you'll need to implement this based on your deep linking setup)
      final String shareText = '''
היי! הצטרף לקבוצת הכדורגל שלנו "${hub.name}" באפליקציית Kickaboor!

להצטרפות, הורד את האפליקציה וחפש את הקבוצה שלנו.
''';

      // Share using share_plus
      await Share.share(
        shareText,
        subject: 'הזמנה לקבוצת ${hub.name}',
      );
    } catch (e) {
      debugPrint('Error sharing hub: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה בשיתוף'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Add player from contacts
  Future<void> _addFromContacts(BuildContext context, String hubId) async {
    await showDialog(
      context: context,
      builder: (context) => ContactPickerDialog(hubId: hubId),
    );
  }
}
