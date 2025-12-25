import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kattrick/widgets/common/premium_scaffold.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';

/// Hub Invitations Screen - ניהול הזמנות ל-Hub
class HubInvitationsScreen extends ConsumerStatefulWidget {
  final String hubId;

  const HubInvitationsScreen({
    super.key,
    required this.hubId,
  });

  @override
  ConsumerState<HubInvitationsScreen> createState() =>
      _HubInvitationsScreenState();
}

class _HubInvitationsScreenState extends ConsumerState<HubInvitationsScreen> {
  @override
  Widget build(BuildContext context) {
    final hubsRepo = ref.watch(hubsRepositoryProvider);
    final hubStream = hubsRepo.watchHub(widget.hubId);

    return StreamBuilder<Hub?>(
      stream: hubStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return PremiumScaffold(
            title: 'הזמנות ל-Hub',
            body: const Center(child: KineticLoadingAnimation(size: 60)),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return PremiumScaffold(
            title: 'הזמנות ל-Hub',
            body: Center(
              child: Text('שגיאה: ${snapshot.error ?? 'Hub לא נמצא'}'),
            ),
          );
        }

        final hub = snapshot.data!;
        final invitationCode = hub.settings['invitationCode'] as String? ??
            widget.hubId.substring(0, 8).toUpperCase();

        // Generate invitation link
        final invitationLink = 'https://kattrick.app/invite/$invitationCode';

        return PremiumScaffold(
          title: 'הזמנות ל-Hub',
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'קישור הזמנה',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        invitationLink,
                        style: const TextStyle(
                            fontSize: 14, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _copyToClipboard(invitationLink),
                              icon: const Icon(Icons.copy),
                              label: const Text('העתק קישור'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _shareInvitation(invitationLink, hub.name),
                              icon: const Icon(Icons.share),
                              label: const Text('שתף'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'קוד הזמנה',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        invitationCode,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _copyToClipboard(invitationCode),
                        icon: const Icon(Icons.copy),
                        label: const Text('העתק קוד'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'איך זה עובד?',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('1. שתף את הקישור או הקוד עם חברים'),
                      const Text('2. הם יוכלו להצטרף ל-Hub דרך הקישור'),
                      const Text('3. אם ה-Hub דורש אישור, תקבל התראה'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: SwitchListTile(
                  title: const Text('הזמנות פעילות'),
                  subtitle: const Text('אפשר להצטרף דרך קישור הזמנה'),
                  value: hub.settings['invitationsEnabled'] as bool? ?? true,
                  onChanged: (value) =>
                      _updateSetting('invitationsEnabled', value),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      SnackbarHelper.showSuccess(context, 'הועתק ללוח');
    }
  }

  Future<void> _shareInvitation(String link, String hubName) async {
    try {
      await Share.share(
        'הצטרף ל-Hub "$hubName" ב-Kattrick!\n$link',
        subject: 'הזמנה ל-Hub $hubName',
      );
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בשיתוף: $e');
      }
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final hub = await hubsRepo.getHub(widget.hubId);
      if (!context.mounted) return;
      if (hub == null) {
        SnackbarHelper.showError(context, 'Hub לא נמצא');
        return;
      }

      final updatedSettings = Map<String, dynamic>.from(hub.settings);
      updatedSettings[key] = value;

      await hubsRepo.updateHub(widget.hubId, {
        'settings': updatedSettings,
      });

      if (!context.mounted) return;
      SnackbarHelper.showSuccess(context, 'ההגדרה עודכנה בהצלחה');
    } catch (e) {
      if (!context.mounted) return;
      SnackbarHelper.showError(context, 'שגיאה בעדכון הגדרה: $e');
    }
  }
}
