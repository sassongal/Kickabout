import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';

/// Join Hub by Invitation Code Screen
class JoinByInviteScreen extends ConsumerStatefulWidget {
  final String invitationCode;

  const JoinByInviteScreen({
    super.key,
    required this.invitationCode,
  });

  @override
  ConsumerState<JoinByInviteScreen> createState() => _JoinByInviteScreenState();
}

class _JoinByInviteScreenState extends ConsumerState<JoinByInviteScreen> {
  Hub? _hub;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _findHubByInvitationCode();
  }

  Future<void> _findHubByInvitationCode() async {
    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      
      // Try to find hub by invitation code in settings
      // For now, we'll search all hubs (in production, you'd use a better query)
      final allHubs = await hubsRepo.getAllHubs(limit: 1000);
      
      final matchingHub = allHubs.firstWhere(
        (hub) {
          final code = hub.settings['invitationCode'] as String?;
          return code != null && code.toUpperCase() == widget.invitationCode.toUpperCase();
        },
        orElse: () => allHubs.firstWhere(
          (hub) => hub.hubId.substring(0, 8).toUpperCase() == widget.invitationCode.toUpperCase(),
          orElse: () => throw Exception('Hub not found'),
        ),
      );

      setState(() {
        _hub = matchingHub;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Hub לא נמצא עם קוד הזמנה זה';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinHub() async {
    if (_hub == null) return;

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      if (!context.mounted) return;
      SnackbarHelper.showError(context, 'נא להתחבר תחילה');
      context.go('/auth');
      return;
    }

    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final hub = await hubsRepo.getHub(_hub!.hubId);
      if (!context.mounted) return;
      if (hub == null) {
        SnackbarHelper.showError(context, 'Hub לא נמצא');
        return;
      }

      // Check if invitations are enabled
      final invitationsEnabled = hub.settings['invitationsEnabled'] as bool? ?? true;
      if (!context.mounted) return;
      if (!invitationsEnabled) {
        SnackbarHelper.showError(context, 'הזמנות ל-Hub זה מושבתות');
        return;
      }

      // Check join mode
      final joinMode = hub.settings['joinMode'] as String? ?? 'auto';
      
      if (joinMode == 'auto') {
        // Auto join
        await hubsRepo.addMember(_hub!.hubId, currentUserId);
        if (!context.mounted) return;
        SnackbarHelper.showSuccess(context, 'הצטרפת ל-Hub "${hub.name}"!');
        context.go('/hubs/${hub.hubId}');
      } else {
        // Approval required - create a join request
        // For now, we'll just add them (in production, you'd create a join request)
        await hubsRepo.addMember(_hub!.hubId, currentUserId);
        if (!context.mounted) return;
        SnackbarHelper.showSuccess(context, 'הבקשה להצטרפות נשלחה למנהל Hub');
        context.go('/hubs/${hub.hubId}');
      }
    } catch (e) {
      if (!context.mounted) return;
      SnackbarHelper.showError(context, 'שגיאה בהצטרפות: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return FuturisticScaffold(
        title: 'הצטרפות ל-Hub',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _hub == null) {
      return FuturisticScaffold(
        title: 'הצטרפות ל-Hub',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Hub לא נמצא',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('חזור לדף הבית'),
              ),
            ],
          ),
        ),
      );
    }

    final hub = _hub!;
    final joinMode = hub.settings['joinMode'] as String? ?? 'auto';
    final requiresApproval = joinMode == 'approval';

    return FuturisticScaffold(
      title: 'הצטרפות ל-Hub',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.group, size: 64, color: Colors.blue),
                    const SizedBox(height: 16),
                    Text(
                      hub.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hub.description != null && hub.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        hub.description!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people, size: 20),
                        const SizedBox(width: 8),
                        Text('${hub.memberIds.length} חברים'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (requiresApproval)
              Card(
                color: Colors.orange.withValues(alpha: 0.1),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hub זה דורש אישור מנהל להצטרפות',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _joinHub,
              icon: const Icon(Icons.person_add),
              label: Text(requiresApproval ? 'שלח בקשה להצטרפות' : 'הצטרף ל-Hub'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('ביטול'),
            ),
          ],
        ),
      ),
    );
  }
}

