import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/screens/hub/hub_invitations_screen.dart';
import 'package:go_router/go_router.dart';

/// Hub Settings Screen - הגדרות מורחבות ל-Hub
class HubSettingsScreen extends ConsumerStatefulWidget {
  final String hubId;

  const HubSettingsScreen({
    super.key,
    required this.hubId,
  });

  @override
  ConsumerState<HubSettingsScreen> createState() => _HubSettingsScreenState();
}

class _HubSettingsScreenState extends ConsumerState<HubSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final hubsRepo = ref.watch(hubsRepositoryProvider);
    final hubStream = hubsRepo.watchHub(widget.hubId);

    return StreamBuilder<Hub?>(
      stream: hubStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return FuturisticScaffold(
            title: 'הגדרות Hub',
            body: const FuturisticLoadingState(message: 'טוען הגדרות...'),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return FuturisticScaffold(
            title: 'הגדרות Hub',
            body: FuturisticEmptyState(
              icon: Icons.error_outline,
              title: 'שגיאה',
              message: snapshot.error?.toString() ?? 'Hub לא נמצא',
              action: ElevatedButton.icon(
                onPressed: () {
                  // Retry by rebuilding
                  setState(() {});
                },
                icon: const Icon(Icons.refresh),
                label: const Text('נסה שוב'),
              ),
            ),
          );
        }

        final hub = snapshot.data!;
        final settings = hub.settings;

        return FuturisticScaffold(
          title: 'הגדרות Hub',
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Rating Mode
              Card(
                child: ExpansionTile(
                  title: const Text('מצב דירוג'),
                  subtitle: Text(
                    settings['ratingMode'] == 'advanced'
                        ? 'דירוג מתקדם (1-10)'
                        : 'דירוג בסיסי (1-7)',
                  ),
                  children: [
                    RadioListTile<String>(
                      title: const Text('דירוג בסיסי (1-7)'),
                      subtitle: const Text('ציון יחיד לכל שחקן'),
                      value: 'basic',
                      groupValue: settings['ratingMode'] as String? ?? 'basic',
                      onChanged: (value) => _updateSetting('ratingMode', value),
                    ),
                    RadioListTile<String>(
                      title: const Text('דירוג מתקדם (1-10)'),
                      subtitle: const Text('8 קטגוריות דירוג'),
                      value: 'advanced',
                      groupValue: settings['ratingMode'] as String? ?? 'basic',
                      onChanged: (value) => _updateSetting('ratingMode', value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Privacy Settings
              Card(
                child: ExpansionTile(
                  title: const Text('הגדרות פרטיות'),
                  subtitle: Text(
                    settings['privacy'] == 'private'
                        ? 'Hub פרטי'
                        : 'Hub פתוח',
                  ),
                  children: [
                    RadioListTile<String>(
                      title: const Text('Hub פתוח'),
                      subtitle: const Text('כל אחד יכול להצטרף'),
                      value: 'public',
                      groupValue: settings['privacy'] as String? ?? 'public',
                      onChanged: (value) => _updateSetting('privacy', value),
                    ),
                    RadioListTile<String>(
                      title: const Text('Hub פרטי'),
                      subtitle: const Text('רק בהזמנה'),
                      value: 'private',
                      groupValue: settings['privacy'] as String? ?? 'public',
                      onChanged: (value) => _updateSetting('privacy', value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Join Mode
              Card(
                child: ExpansionTile(
                  title: const Text('מצב הרשמה'),
                  subtitle: Text(
                    settings['joinMode'] == 'approval'
                        ? 'דורש אישור'
                        : 'הצטרפות אוטומטית',
                  ),
                  children: [
                    RadioListTile<String>(
                      title: const Text('הצטרפות אוטומטית'),
                      subtitle: const Text('כל אחד יכול להצטרף מיד'),
                      value: 'auto',
                      groupValue: settings['joinMode'] as String? ?? 'auto',
                      onChanged: (value) => _updateSetting('joinMode', value),
                    ),
                    RadioListTile<String>(
                      title: const Text('דורש אישור'),
                      subtitle: const Text('מנהל Hub צריך לאשר'),
                      value: 'approval',
                      groupValue: settings['joinMode'] as String? ?? 'auto',
                      onChanged: (value) => _updateSetting('joinMode', value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Notifications
              Card(
                child: SwitchListTile(
                  title: const Text('התראות'),
                  subtitle: const Text('שלח התראות לחברי Hub על משחקים חדשים'),
                  value: settings['notificationsEnabled'] as bool? ?? true,
                  onChanged: (value) => _updateSetting('notificationsEnabled', value),
                ),
              ),
              const SizedBox(height: 8),

              // Chat
              Card(
                child: SwitchListTile(
                  title: const Text('צ\'אט Hub'),
                  subtitle: const Text('אפשר צ\'אט בין חברי Hub'),
                  value: settings['chatEnabled'] as bool? ?? true,
                  onChanged: (value) => _updateSetting('chatEnabled', value),
                ),
              ),
              const SizedBox(height: 8),

              // Feed
              Card(
                child: SwitchListTile(
                  title: const Text('פיד פעילות'),
                  subtitle: const Text('אפשר פוסטים בפיד Hub'),
                  value: settings['feedEnabled'] as bool? ?? true,
                  onChanged: (value) => _updateSetting('feedEnabled', value),
                ),
              ),
              const SizedBox(height: 16),
              // Venues Management
              Card(
                child: ListTile(
                  title: const Text('ניהול מגרשים'),
                  subtitle: const Text('הוסף וערוך מגרשים של ההוב'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => context.push('/venues/search?hubId=${widget.hubId}&select=true'),
                ),
              ),
              const SizedBox(height: 8),
              // Invitations
              Card(
                child: ListTile(
                  title: const Text('הזמנות ל-Hub'),
                  subtitle: const Text('נהל קישורי הזמנה וקודים'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HubInvitationsScreen(hubId: widget.hubId),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final hub = await hubsRepo.getHub(widget.hubId);
      if (hub == null) {
        SnackbarHelper.showError(context, 'Hub לא נמצא');
        return;
      }

      final updatedSettings = Map<String, dynamic>.from(hub.settings);
      updatedSettings[key] = value;

      await hubsRepo.updateHub(widget.hubId, {
        'settings': updatedSettings,
      });

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'ההגדרה עודכנה בהצלחה');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בעדכון הגדרה: $e');
      }
    }
  }
}

