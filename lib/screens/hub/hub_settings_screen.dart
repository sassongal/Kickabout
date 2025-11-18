import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/models/hub_role.dart';
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

    // Check admin permissions
    final roleAsync = ref.watch(hubRoleProvider(widget.hubId));

    return roleAsync.when(
      data: (role) {
        if (role != UserRole.admin) {
          return FuturisticScaffold(
            title: 'הגדרות Hub',
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 64, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'אין לך הרשאת ניהול למסך זה',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'רק מנהלי Hub יכולים לשנות הגדרות',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

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
                    ListTile(
                      title: const Text('דירוג בסיסי (1-7)'),
                      subtitle: const Text('ציון יחיד לכל שחקן'),
                      leading: Radio<String>(
                        value: 'basic',
                        // ignore: deprecated_member_use
                        groupValue: settings['ratingMode'] as String? ?? 'basic',
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          if (value != null) {
                            _updateSetting('ratingMode', value);
                          }
                        },
                      ),
                      onTap: () => _updateSetting('ratingMode', 'basic'),
                    ),
                    ListTile(
                      title: const Text('דירוג מתקדם (1-10)'),
                      subtitle: const Text('8 קטגוריות דירוג'),
                      leading: Radio<String>(
                        value: 'advanced',
                        // ignore: deprecated_member_use
                        groupValue: settings['ratingMode'] as String? ?? 'basic',
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          if (value != null) {
                            _updateSetting('ratingMode', value);
                          }
                        },
                      ),
                      onTap: () => _updateSetting('ratingMode', 'advanced'),
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
                    ListTile(
                      title: const Text('Hub פתוח'),
                      subtitle: const Text('כל אחד יכול להצטרף'),
                      leading: Radio<String>(
                        value: 'public',
                        // ignore: deprecated_member_use
                        groupValue: settings['privacy'] as String? ?? 'public',
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          if (value != null) {
                            _updateSetting('privacy', value);
                          }
                        },
                      ),
                      onTap: () => _updateSetting('privacy', 'public'),
                    ),
                    ListTile(
                      title: const Text('Hub פרטי'),
                      subtitle: const Text('רק בהזמנה'),
                      leading: Radio<String>(
                        value: 'private',
                        // ignore: deprecated_member_use
                        groupValue: settings['privacy'] as String? ?? 'public',
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          if (value != null) {
                            _updateSetting('privacy', value);
                          }
                        },
                      ),
                      onTap: () => _updateSetting('privacy', 'private'),
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
                    ListTile(
                      title: const Text('הצטרפות אוטומטית'),
                      subtitle: const Text('כל אחד יכול להצטרף מיד'),
                      leading: Radio<String>(
                        value: 'auto',
                        // ignore: deprecated_member_use
                        groupValue: settings['joinMode'] as String? ?? 'auto',
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          if (value != null) {
                            _updateSetting('joinMode', value);
                          }
                        },
                      ),
                      onTap: () => _updateSetting('joinMode', 'auto'),
                    ),
                    ListTile(
                      title: const Text('דורש אישור'),
                      subtitle: const Text('מנהל Hub צריך לאשר'),
                      leading: Radio<String>(
                        value: 'approval',
                        // ignore: deprecated_member_use
                        groupValue: settings['joinMode'] as String? ?? 'auto',
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          if (value != null) {
                            _updateSetting('joinMode', value);
                          }
                        },
                      ),
                      onTap: () => _updateSetting('joinMode', 'approval'),
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
              // Hub Rules
              Card(
                child: ExpansionTile(
                  title: const Text('חוקי האב'),
                  subtitle: Text(
                    hub.hubRules != null && hub.hubRules!.isNotEmpty
                        ? '${hub.hubRules!.length} תווים'
                        : 'אין חוקים מוגדרים',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _HubRulesEditor(
                        hubId: widget.hubId,
                        initialRules: hub.hubRules ?? '',
                      ),
                    ),
                  ],
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
      },
      loading: () => FuturisticScaffold(
        title: 'הגדרות Hub',
        body: const FuturisticLoadingState(message: 'בודק הרשאות...'),
      ),
      error: (error, stack) => FuturisticScaffold(
        title: 'הגדרות Hub',
        body: FuturisticEmptyState(
          icon: Icons.error_outline,
          title: 'שגיאה בבדיקת הרשאות',
          message: error.toString(),
        ),
      ),
    );
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

/// Widget for editing hub rules
class _HubRulesEditor extends ConsumerStatefulWidget {
  final String hubId;
  final String initialRules;

  const _HubRulesEditor({
    required this.hubId,
    required this.initialRules,
  });

  @override
  ConsumerState<_HubRulesEditor> createState() => _HubRulesEditorState();
}

class _HubRulesEditorState extends ConsumerState<_HubRulesEditor> {
  late TextEditingController _rulesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rulesController = TextEditingController(text: widget.initialRules);
  }

  @override
  void dispose() {
    _rulesController.dispose();
    super.dispose();
  }

  Future<void> _saveRules() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      await hubsRepo.updateHub(widget.hubId, {
        'hubRules': _rulesController.text.trim(),
      });

      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'חוקי האב נשמרו בהצלחה');
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, 'שגיאה בשמירת חוקים: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _rulesController,
          decoration: const InputDecoration(
            labelText: 'חוקי האב',
            hintText: 'הזן את חוקי האב כאן...',
            border: OutlineInputBorder(),
            helperText: 'השתמש בשורות נפרדות לכל חוק',
          ),
          maxLines: 10,
          minLines: 5,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveRules,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_isSaving ? 'שומר...' : 'שמור חוקים'),
        ),
      ],
    );
  }
}

