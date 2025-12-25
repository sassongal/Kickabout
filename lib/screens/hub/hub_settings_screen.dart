import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/l10n/app_localizations.dart';
import 'package:kattrick/widgets/common/premium_scaffold.dart';
import 'package:kattrick/widgets/premium/loading_state.dart';
import 'package:kattrick/widgets/premium/empty_state.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/core/providers/complex_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/models/hub_role.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/screens/hub/hub_invitations_screen.dart';
import 'package:kattrick/widgets/hub/hub_venues_manager.dart';
import 'package:kattrick/widgets/hub/hub_banner_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kattrick/services/storage_service.dart';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';
import 'package:kattrick/widgets/input/city_autocomplete_field.dart';
import 'package:kattrick/utils/city_utils.dart';

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
  bool _isUploadingHero = false;

  Future<void> _uploadHeroImage(Hub hub) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );
      if (image == null) return;

      final sizeBytes = await image.length();
      if (sizeBytes > 10 * 1024 * 1024) {
        if (mounted) {
          SnackbarHelper.showError(
              context, 'הקובץ גדול מדי (מעל 10MB). בחר תמונה קלה יותר.');
        }
        return;
      }

      setState(() => _isUploadingHero = true);
      final storage = StorageService();
      await storage.deleteHubHeroPhoto(hub.hubId); // clean previous
      final url = await storage.uploadHubHeroPhoto(hub.hubId, image);

      final hubsRepo = ref.read(hubsRepositoryProvider);
      await hubsRepo.updateHub(hub.hubId, {'profileImageUrl': url});

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'תמונת ה-Hub עודכנה בהצלחה');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בהעלאת תמונת ה-Hub: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingHero = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Check admin permissions
    final roleAsync = ref.watch(hubRoleProvider(widget.hubId));

    return roleAsync.when(
      data: (role) {
        if (role != UserRole.admin) {
          return PremiumScaffold(
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

        // Use unified hub state provider
        final hubAsync = ref.watch(hubStreamProvider(widget.hubId));

        return hubAsync.when(
          data: (hub) {
            if (hub == null) {
              return PremiumScaffold(
                title: l10n.hubSettingsTitle,
                body: PremiumEmptyState(
                  icon: Icons.error_outline,
                  title: l10n.error,
                  message: l10n.hubNotFound,
                  action: ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(hubStreamProvider(widget.hubId));
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.tryAgain),
                  ),
                ),
              );
            }

            // ignore: deprecated_member_use
            final settings = hub.legacySettings ?? {};

            return PremiumScaffold(
              title: l10n.hubSettingsTitle,
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Hub Banner Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: HubBannerPicker(
                        initialUrl: hub.bannerUrl,
                        onBannerSelected: (url) {
                          ref
                              .read(hubsRepositoryProvider)
                              .updateHub(hub.hubId, {'bannerUrl': url});
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // City & Region
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: _HubCityEditor(
                        hubId: widget.hubId,
                        initialCity: hub.city,
                        initialRegion: hub.region,
                      ),
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

                  // Allow Join Requests and Allow Moderators to Create Games
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('אפשר בקשות הצטרפות'),
                          subtitle: const Text(
                              'אם כבוי, לא ניתן לשלוח בקשות הצטרפות להאב'),
                          value: settings['allowJoinRequests'] as bool? ?? true,
                          onChanged: (value) =>
                              _updateSetting('allowJoinRequests', value),
                        ),
                        const Divider(),
                        SwitchListTile(
                          title: const Text('מנחים יכולים לפתוח משחקים'),
                          subtitle: const Text(
                              'אפשר למנחים ליצור משחקים מאירועים (ברירת מחדל: מנהל בלבד)'),
                          value: settings['allowModeratorsToCreateGames']
                                  as bool? ??
                              false,
                          onChanged: (value) => _updateSetting(
                              'allowModeratorsToCreateGames', value),
                        ),
                      ],
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
                    child: ExpansionTile(
                      title: Text(l10n.manageVenues),
                      subtitle: Text(l10n.manageVenuesDescription),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _HubVenuesEditor(
                            hubId: widget.hubId,
                            hubCity: hub.city,
                            initialVenueIds: hub.venueIds,
                            initialMainVenueId:
                                hub.mainVenueId ?? hub.primaryVenueId,
                          ),
                        ),
                      ],
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
                  const SizedBox(height: 8),
                  // Custom Permissions Management
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.admin_panel_settings,
                          color: Colors.blue),
                      title: const Text('הרשאות מותאמות אישית'),
                      subtitle: const Text(
                        'ניהול הרשאות ספציפיות לשחקנים בודדים',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => context
                          .push('/hubs/${widget.hubId}/custom-permissions'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Hub Insights Dashboard
                  Card(
                    child: ListTile(
                      leading:
                          const Icon(Icons.analytics, color: Colors.purple),
                      title: const Text('ניתוח נתונים ותובנות'),
                      subtitle: const Text(
                        'סטטיסטיקות מתקדמות ומעקב אחר ביצועי ההאב',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () =>
                          context.push('/hubs/${widget.hubId}/insights'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Delete Hub (only for managers)
                  Card(
                    color: Colors.red.shade50,
                    child: ListTile(
                      leading:
                          const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text(
                        'מחיקת ההאב',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'פעולה זו תמחק את ההאב לצמיתות. כל הנתונים יימחקו ולא ניתן לשחזר אותם.',
                        style: TextStyle(color: Colors.red),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Colors.red),
                      onTap: () => _showDeleteHubDialog(context, hub),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => PremiumScaffold(
            title: l10n.hubSettingsTitle,
            body: PremiumLoadingState(message: l10n.loadingSettings),
          ),
          error: (error, stack) => PremiumScaffold(
            title: l10n.hubSettingsTitle,
            body: PremiumEmptyState(
              icon: Icons.error_outline,
              title: l10n.error,
              message: error.toString(),
              action: ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(hubStreamProvider(widget.hubId));
                },
                icon: const Icon(Icons.refresh),
                label: Text(l10n.tryAgain),
              ),
            ),
          ),
        );
      },
      loading: () => PremiumScaffold(
        title: l10n.hubSettingsTitle,
        body: PremiumLoadingState(message: l10n.checkingPermissions),
      ),
      error: (error, stack) => PremiumScaffold(
        title: l10n.hubSettingsTitle,
        body: PremiumEmptyState(
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

      // ignore: deprecated_member_use
      final updatedSettings = Map<String, dynamic>.from(hub.legacySettings ?? {});
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

  /// Show confirmation dialog before deleting hub
  Future<void> _showDeleteHubDialog(BuildContext context, Hub hub) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            const Text(
              'מחיקת ההאב',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'האם אתה בטוח שאתה רוצה למחוק את ההאב "${hub.name}"?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'פעולה זו תמחק לצמיתות:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('• את ההאב וכל הנתונים שלו'),
                  Text('• את כל האירועים והמשחקים'),
                  Text('• את כל הפוסטים והתגובות'),
                  Text('• את כל רשימת החברים'),
                  SizedBox(height: 8),
                  Text(
                    'פעולה זו אינה הפיכה!',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'ביטול',
              style: TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'מחק לצמיתות',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: KineticLoadingAnimation(size: 40),
      ),
    );

    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final currentUserId = ref.read(currentUserIdProvider);
      if (currentUserId == null) {
        throw Exception('משתמש לא מחובר');
      }
      await hubsRepo.deleteHub(widget.hubId, currentUserId);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      SnackbarHelper.showSuccess(context, 'ההאב נמחק בהצלחה');

      // Navigate back to home screen
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      SnackbarHelper.showError(
        context,
        'שגיאה במחיקת ההאב: ${e.toString()}',
      );
    }
  }
}

/// Widget for editing hub venues
class _HubVenuesEditor extends ConsumerStatefulWidget {
  final String hubId;
  final String? hubCity;
  final List<String> initialVenueIds;
  final String? initialMainVenueId;

  const _HubVenuesEditor({
    required this.hubId,
    this.hubCity,
    required this.initialVenueIds,
    this.initialMainVenueId,
  });

  @override
  ConsumerState<_HubVenuesEditor> createState() => _HubVenuesEditorState();
}

class _HubVenuesEditorState extends ConsumerState<_HubVenuesEditor> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Venue> _venues = [];
  String? _mainVenueId;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadVenues();
    _mainVenueId = widget.initialMainVenueId;
  }

  Future<void> _loadVenues() async {
    try {
      final venuesRepo = ref.read(venuesRepositoryProvider);
      final futures = widget.initialVenueIds.map((id) async {
        try {
          return await venuesRepo.getVenue(id);
        } catch (e) {
          debugPrint('⚠️ Error loading venue $id: $e');
          return null; // Return null if venue not found
        }
      });
      final venues = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _venues = venues.whereType<Venue>().toList();
          _isLoading = false;
        });
        debugPrint('✅ Loaded ${_venues.length} venues for hub ${widget.hubId}');
      }
    } catch (e) {
      debugPrint('❌ Error loading venues: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveVenues() async {
    setState(() => _isSaving = true);

    try {
      debugPrint('💾 Starting to save venues for hub ${widget.hubId}');
      debugPrint('   Venues count: ${_venues.length}');
      debugPrint('   Main venue ID: $_mainVenueId');
      debugPrint('   Venue IDs: ${_venues.map((v) => v.venueId).toList()}');

      final hubsRepo = ref.read(hubsRepositoryProvider);
      final locationService = ref.read(locationServiceProvider);

      // 1. First, update the venueIds list if it changed
      final newVenueIds = _venues.map((v) => v.venueId).toList();
      debugPrint('📝 Updating hub venueIds: $newVenueIds');
      await hubsRepo.updateHub(widget.hubId, {
        'venueIds': newVenueIds,
      });
      debugPrint('✅ Updated hub venueIds');

      // 2. If a main venue is selected, use the dedicated function that handles transaction
      // This ensures both Hub and Venue are updated atomically (including hubCount)
      if (_mainVenueId != null) {
        debugPrint('📝 Setting primary venue: $_mainVenueId');
        // This function updates primaryVenueId, mainVenueId, primaryVenueLocation, and venue hubCount
        await hubsRepo.setHubPrimaryVenue(widget.hubId, _mainVenueId!);
        debugPrint('✅ Set primary venue');

        // Also update location and geohash for consistency (mainVenueId is already updated by setHubPrimaryVenue)
        final mainVenue = _venues.firstWhere(
          (v) => v.venueId == _mainVenueId,
          orElse: () => _venues.first,
        );
        final location = mainVenue.location;
        final geohash = locationService.generateGeohash(
          location.latitude,
          location.longitude,
        );

        await hubsRepo.updateHub(widget.hubId, {
          'location': location,
          'geohash': geohash,
        });
      } else {
        // If no main venue selected, clear the fields
        await hubsRepo.updateHub(widget.hubId, {
          'mainVenueId': null,
          'primaryVenueId': null,
          'primaryVenueLocation': null,
          'location': null,
          'geohash': null,
        });
      }

      // 3. Link secondary venues (for consistency with hubCount)
      final venuesRepo = ref.read(venuesRepositoryProvider);
      debugPrint('📝 Linking secondary venues...');
      for (final venue in _venues) {
        // Only link if it's not the main venue (main venue is handled by setHubPrimaryVenue)
        if (venue.venueId != _mainVenueId) {
          debugPrint('   Linking venue ${venue.venueId} (${venue.name})');
          await venuesRepo.linkSecondaryVenueToHub(widget.hubId, venue.venueId);
          debugPrint('   ✅ Linked venue ${venue.venueId}');
        }
      }
      debugPrint('✅ All venues linked successfully');

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'מגרשי הבית עודכנו בהצלחה');
        setState(() => _hasChanges = false);
      }
      debugPrint('🎉 Venues saved successfully for hub ${widget.hubId}');
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving venues: $e');
      debugPrint('   Stack trace: $stackTrace');
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בעדכון מגרשים: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: KineticLoadingAnimation(size: 40));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubVenuesManager(
          initialVenues: _venues,
          initialMainVenueId: _mainVenueId,
          hubId: widget.hubId, // Pass hubId so venues get it when created
          hubCity: widget.hubCity, // Filter venues by hub city
          onChanged: (venues, mainVenueId) {
            setState(() {
              _venues = venues;
              _mainVenueId = mainVenueId;
              _hasChanges = true;
            });
          },
        ),
        const SizedBox(height: 16),
        if (_hasChanges)
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveVenues,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: KineticLoadingAnimation(size: 20),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'שומר...' : 'שמור שינויים'),
          ),
      ],
    );
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
                  child: KineticLoadingAnimation(size: 20),
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
                  child: KineticLoadingAnimation(size: 20),
                )
              : const Icon(Icons.save),
          label: Text(_isSaving ? l10n.saving : l10n.saveLink),
        ),
      ],
    );
  }
}

/// Widget for editing hub city
class _HubCityEditor extends ConsumerStatefulWidget {
  final String hubId;
  final String? initialCity;
  final String? initialRegion;

  const _HubCityEditor({
    required this.hubId,
    this.initialCity,
    this.initialRegion,
  });

  @override
  ConsumerState<_HubCityEditor> createState() => _HubCityEditorState();
}

class _HubCityEditorState extends ConsumerState<_HubCityEditor> {
  late TextEditingController _cityController;
  String? _calculatedRegion;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.initialCity ?? '');
    _calculatedRegion = widget.initialRegion;

    // Calculate region from city if city exists
    if (widget.initialCity != null && widget.initialCity!.isNotEmpty) {
      _calculatedRegion = CityUtils.getRegionForCity(widget.initialCity!);
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveCity() async {
    setState(() => _isSaving = true);

    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final city = _cityController.text.trim();
      final region = city.isNotEmpty ? CityUtils.getRegionForCity(city) : null;

      await hubsRepo.updateHub(widget.hubId, {
        'city': city.isNotEmpty ? city : null,
        'region': region,
      });

      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'העיר והאזור עודכנו בהצלחה');
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, 'שגיאה בעדכון העיר: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'עיר ואזור',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (_calculatedRegion != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'אזור: $_calculatedRegion',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        CityAutocompleteField(
          controller: _cityController,
          labelText: 'עיר ראשית',
          hintText: 'בחר עיר...',
          helperText: 'האזור מחושב אוטומטית לפי העיר',
          onCitySelected: (city) {
            setState(() {
              _calculatedRegion = CityUtils.getRegionForCity(city);
            });
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveCity,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: KineticLoadingAnimation(size: 20),
                )
              : const Icon(Icons.save),
          label: Text(_isSaving ? 'שומר...' : 'שמור שינויים'),
        ),
      ],
    );
  }
}
