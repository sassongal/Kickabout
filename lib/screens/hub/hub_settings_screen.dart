import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickadoor/l10n/app_localizations.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/models/hub_role.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/screens/hub/hub_invitations_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/utils/geohash_utils.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final hubsRepo = ref.watch(hubsRepositoryProvider);
    final hubStream = hubsRepo.watchHub(widget.hubId);

    // Check admin permissions
    final roleAsync = ref.watch(hubRoleProvider(widget.hubId));

    return roleAsync.when(
      data: (role) {
        if (role != UserRole.admin) {
          return FuturisticScaffold(
            title: l10n.hubSettingsTitle,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noAdminPermissionForScreen,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.onlyHubAdminsCanChangeSettings,
                    style: const TextStyle(color: Colors.grey),
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
                title: l10n.hubSettingsTitle,
                body: FuturisticLoadingState(message: l10n.loadingSettings),
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return FuturisticScaffold(
                title: l10n.hubSettingsTitle,
                body: FuturisticEmptyState(
                  icon: Icons.error_outline,
                  title: l10n.error,
                  message: snapshot.error?.toString() ?? l10n.hubNotFound,
                  action: ElevatedButton.icon(
                    onPressed: () {
                      // Retry by rebuilding
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.tryAgain),
                  ),
                ),
              );
            }

            final hub = snapshot.data!;
            final settings = hub.settings;

            return FuturisticScaffold(
              title: l10n.hubSettingsTitle,
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Rating Mode
                  Card(
                    child: ExpansionTile(
                      title: Text(l10n.ratingMode),
                      subtitle: Text(
                        settings['ratingMode'] == 'advanced'
                            ? l10n.advancedRating
                            : l10n.basicRating,
                      ),
                      children: [
                        ListTile(
                          title: Text(l10n.basicRating),
                          subtitle: Text(l10n.basicRatingDescription),
                          leading: Radio<String>(
                            value: 'basic',
                            // ignore: deprecated_member_use
                            groupValue:
                                settings['ratingMode'] as String? ?? 'basic',
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
                          title: Text(l10n.advancedRating),
                          subtitle: Text(l10n.advancedRatingDescription),
                          leading: Radio<String>(
                            value: 'advanced',
                            // ignore: deprecated_member_use
                            groupValue:
                                settings['ratingMode'] as String? ?? 'basic',
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
                      title: Text(l10n.privacySettings),
                      subtitle: Text(
                        settings['privacy'] == 'private'
                            ? l10n.privateHub
                            : l10n.publicHub,
                      ),
                      children: [
                        ListTile(
                          title: Text(l10n.publicHub),
                          subtitle: Text(l10n.publicHubDescription),
                          leading: Radio<String>(
                            value: 'public',
                            // ignore: deprecated_member_use
                            groupValue:
                                settings['privacy'] as String? ?? 'public',
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
                          title: Text(l10n.privateHub),
                          subtitle: Text(l10n.privateHubDescription),
                          leading: Radio<String>(
                            value: 'private',
                            // ignore: deprecated_member_use
                            groupValue:
                                settings['privacy'] as String? ?? 'public',
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
                      title: Text(l10n.joinMode),
                      subtitle: Text(
                        settings['joinMode'] == 'approval'
                            ? l10n.approvalRequired
                            : l10n.autoJoin,
                      ),
                      children: [
                        ListTile(
                          title: Text(l10n.autoJoin),
                          subtitle: Text(l10n.autoJoinDescription),
                          leading: Radio<String>(
                            value: 'auto',
                            // ignore: deprecated_member_use
                            groupValue:
                                settings['joinMode'] as String? ?? 'auto',
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
                          title: Text(l10n.approvalRequired),
                          subtitle: Text(l10n.approvalRequiredDescription),
                          leading: Radio<String>(
                            value: 'approval',
                            // ignore: deprecated_member_use
                            groupValue:
                                settings['joinMode'] as String? ?? 'auto',
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

                  // Allow Join Requests
                  Card(
                    child: SwitchListTile(
                      title: const Text('אפשר בקשות הצטרפות'),
                      subtitle: const Text(
                          'אם כבוי, לא ניתן לשלוח בקשות הצטרפות להאב'),
                      value: settings['allowJoinRequests'] as bool? ?? true,
                      onChanged: (value) =>
                          _updateSetting('allowJoinRequests', value),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Manager contact visibility
                  Card(
                    child: SwitchListTile(
                      title: const Text('הצג פרטי התקשרות של מנהל'),
                      subtitle: const Text(
                        'אפשר לשחקנים לראות פרטי קשר של מנהל ההאב כדי לפנות',
                      ),
                      value:
                          settings['showManagerContactInfo'] as bool? ?? true,
                      onChanged: (value) =>
                          _updateSetting('showManagerContactInfo', value),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Notifications
                  Card(
                    child: SwitchListTile(
                      title: Text(l10n.notifications),
                      subtitle: Text(l10n.notificationsDescription),
                      value: settings['notificationsEnabled'] as bool? ?? true,
                      onChanged: (value) =>
                          _updateSetting('notificationsEnabled', value),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Chat
                  Card(
                    child: SwitchListTile(
                      title: Text(l10n.hubChat),
                      subtitle: Text(l10n.hubChatDescription),
                      value: settings['chatEnabled'] as bool? ?? true,
                      onChanged: (value) =>
                          _updateSetting('chatEnabled', value),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Feed
                  Card(
                    child: SwitchListTile(
                      title: Text(l10n.activityFeed),
                      subtitle: Text(l10n.activityFeedDescription),
                      value: settings['feedEnabled'] as bool? ?? true,
                      onChanged: (value) =>
                          _updateSetting('feedEnabled', value),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Venues Management
                  Card(
                    child: ListTile(
                      title: Text(l10n.manageVenues),
                      subtitle: Text(l10n.manageVenuesDescription),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () async {
                        final selectedVenue = await context.push<Venue?>(
                          '/venues/search?hubId=${widget.hubId}&select=true',
                        );

                        if (selectedVenue != null) {
                          try {
                            final hubsRepo = ref.read(hubsRepositoryProvider);
                            final geohash = GeohashUtils.encode(
                              selectedVenue.location.latitude,
                              selectedVenue.location.longitude,
                              precision: 8,
                            );

                            await hubsRepo.updateHub(widget.hubId, {
                              'primaryVenueId': selectedVenue.venueId,
                              'primaryVenueLocation':
                                  selectedVenue.location,
                              'location': selectedVenue.location,
                              'geohash': geohash,
                            });

                            if (mounted) {
                              SnackbarHelper.showSuccess(
                                context,
                                'עודכן מגרש הבית של ההאב',
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              SnackbarHelper.showError(
                                context,
                                'שגיאה בעדכון מגרש הבית: $e',
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Hub Rules
                  Card(
                    child: ExpansionTile(
                      title: Text(l10n.hubRules),
                      subtitle: Text(
                        hub.hubRules != null && hub.hubRules!.isNotEmpty
                            ? l10n.characterCount(hub.hubRules!.length)
                            : l10n.noRulesDefined,
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
                  // Payment Link
                  Card(
                    child: ExpansionTile(
                      title: Text(l10n.paymentLinkLabel),
                      subtitle: Text(
                        hub.paymentLink != null && hub.paymentLink!.isNotEmpty
                            ? l10n.defined
                            : l10n.notDefined,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _PaymentLinkEditor(
                            hubId: widget.hubId,
                            initialLink: hub.paymentLink ?? '',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Invitations
                  Card(
                    child: ListTile(
                      title: Text(l10n.hubInvitations),
                      subtitle: Text(l10n.hubInvitationsDescription),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              HubInvitationsScreen(hubId: widget.hubId),
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
        title: l10n.hubSettingsTitle,
        body: FuturisticLoadingState(message: l10n.checkingPermissions),
      ),
      error: (error, stack) => FuturisticScaffold(
        title: l10n.hubSettingsTitle,
        body: FuturisticEmptyState(
          icon: Icons.error_outline,
          title: l10n.permissionCheckError,
          message: error.toString(),
        ),
      ),
    );
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final hub = await hubsRepo.getHub(widget.hubId);
      if (!mounted) return;
      if (hub == null) {
        SnackbarHelper.showError(context, l10n.hubNotFound);
        return;
      }

      final updatedSettings = Map<String, dynamic>.from(hub.settings);
      updatedSettings[key] = value;

      await hubsRepo.updateHub(widget.hubId, {
        'settings': updatedSettings,
      });

      if (!mounted) return;
      SnackbarHelper.showSuccess(context, l10n.settingUpdatedSuccess);
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, l10n.settingUpdateError(e.toString()));
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
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isSaving = true;
    });

    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      await hubsRepo.updateHub(widget.hubId, {
        'hubRules': _rulesController.text.trim(),
      });

      if (!mounted) return;
      SnackbarHelper.showSuccess(context, l10n.hubRulesSavedSuccess);
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, l10n.hubRulesSaveError(e.toString()));
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _rulesController,
          decoration: InputDecoration(
            labelText: l10n.hubRules,
            hintText: l10n.hubRulesHint,
            border: const OutlineInputBorder(),
            helperText: l10n.hubRulesHelper,
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
          label: Text(_isSaving ? l10n.saving : l10n.saveRules),
        ),
      ],
    );
  }
}

/// Widget for editing payment link
class _PaymentLinkEditor extends ConsumerStatefulWidget {
  final String hubId;
  final String initialLink;

  const _PaymentLinkEditor({
    required this.hubId,
    required this.initialLink,
  });

  @override
  ConsumerState<_PaymentLinkEditor> createState() => _PaymentLinkEditorState();
}

class _PaymentLinkEditorState extends ConsumerState<_PaymentLinkEditor> {
  late TextEditingController _linkController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _linkController = TextEditingController(text: widget.initialLink);
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _saveLink() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isSaving = true;
    });

    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final link = _linkController.text.trim();

      await hubsRepo.updateHub(widget.hubId, {
        'paymentLink': link.isNotEmpty ? link : null,
      });

      if (!mounted) return;
      SnackbarHelper.showSuccess(context, l10n.paymentLinkSavedSuccess);
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(
          context, l10n.paymentLinkSaveError(e.toString()));
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _linkController,
          decoration: InputDecoration(
            labelText: l10n.paymentLinkBitLabel,
            hintText: l10n.paymentLinkHint,
            border: const OutlineInputBorder(),
            helperText: l10n.paymentLinkHelper,
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveLink,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_isSaving ? l10n.saving : l10n.saveLink),
        ),
      ],
    );
  }
}
