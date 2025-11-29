import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kickadoor/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);

      // Try to find hub by invitation code in settings
      // For now, we'll search all hubs (in production, you'd use a better query)
      final allHubs = await hubsRepo.getAllHubs(limit: 1000);

      final matchingHub = allHubs.firstWhere(
        (hub) {
          final code = hub.settings['invitationCode'] as String?;
          return code != null &&
              code.toUpperCase() == widget.invitationCode.toUpperCase();
        },
        orElse: () => allHubs.firstWhere(
          (hub) =>
              hub.hubId.substring(0, 8).toUpperCase() ==
              widget.invitationCode.toUpperCase(),
          orElse: () => throw Exception('Hub not found'),
        ),
      );

      if (!mounted) return;
      setState(() {
        _hub = matchingHub;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = l10n.hubNotFoundWithInviteCode;
        _isLoading = false;
      });
    }
  }

  Future<void> _joinHub() async {
    if (_hub == null) return;
    final l10n = AppLocalizations.of(context)!;

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      if (!context.mounted) return;
      SnackbarHelper.showError(context, l10n.pleaseLoginFirst);
      context.go('/auth');
      return;
    }

    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final hub = await hubsRepo.getHub(_hub!.hubId);
      if (!mounted) return;
      if (hub == null) {
        SnackbarHelper.showError(context, l10n.hubNotFound);
        return;
      }

      // Check if invitations are enabled
      final invitationsEnabled =
          hub.settings['invitationsEnabled'] as bool? ?? true;
      if (!mounted) return;
      if (!invitationsEnabled) {
        SnackbarHelper.showError(context, l10n.hubInvitationsDisabled);
        return;
      }

      // Check join mode
      final joinMode = hub.settings['joinMode'] as String? ?? 'auto';

      // Prevent double-join using user profile hubIds
      final currentUser = await ref.read(usersRepositoryProvider).getUser(currentUserId);
      if (currentUser != null && currentUser.hubIds.contains(hub.hubId)) {
        if (!mounted) return;
        SnackbarHelper.showInfo(context, l10n.joinedHubSuccess(hub.name));
        context.go('/hubs/${hub.hubId}');
        return;
      }

      if (joinMode == 'auto') {
        // Auto join
        await hubsRepo.addMember(_hub!.hubId, currentUserId);
        if (!mounted) return;
        SnackbarHelper.showSuccess(context, l10n.joinedHubSuccess(hub.name));
        context.go('/hubs/${hub.hubId}');
      } else {
        // Approval required - create a join request
        // For now, we'll just add them (in production, you'd create a join request)
        await hubsRepo.addMember(_hub!.hubId, currentUserId);
        if (!mounted) return;
        SnackbarHelper.showSuccess(context, l10n.joinRequestSent);
        context.go('/hubs/${hub.hubId}');
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(context, l10n.joinHubError(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return FuturisticScaffold(
        title: l10n.joinHubTitle,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _hub == null) {
      return FuturisticScaffold(
        title: l10n.joinHubTitle,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error ?? l10n.hubNotFound,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: Text(l10n.backToHome),
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
      title: l10n.joinHubTitle,
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
                    if (hub.description != null &&
                        hub.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        hub.description!,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people, size: 20),
                        const SizedBox(width: 8),
                        Text(l10n.memberCount(hub.memberIds.length)),
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.hubRequiresApproval,
                          style: const TextStyle(fontSize: 14),
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
              label: Text(
                  requiresApproval ? l10n.sendJoinRequest : l10n.joinHubButton),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/'),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
