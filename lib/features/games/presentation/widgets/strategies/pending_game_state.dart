import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/data/repositories.dart';
import 'package:kattrick/l10n/app_localizations.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/features/hubs/domain/models/hub_role.dart';
import 'package:kattrick/shared/domain/models/targeting_criteria.dart';
import 'package:kattrick/features/games/presentation/widgets/strategies/game_detail_sections.dart';
import 'package:kattrick/features/games/presentation/widgets/payment_status_card.dart';

class PendingGameState extends StatelessWidget {
  final Game game;
  final String gameId;
  final UserRole role;
  final bool isCreator;
  final bool isSignedUp;
  final bool isGameFull;
  final List<GameSignup> confirmedSignups;
  final List<GameSignup> pendingSignups;
  final Map<String, User> playerUsers;
  final UsersRepository usersRepo;
  final String? currentUserId;
  final Future<void> Function(BuildContext context, Game game, bool isSignedUp)
      onToggleSignup;
  final void Function(String playerId) onApprovePlayer;
  final void Function(String playerId) onRejectPlayer;
  final Future<void> Function(String reason)? onCancelGame;
  final Future<void> Function(BuildContext context, Game game)? onJoinWaitlist;
  final Future<void> Function(String playerId, bool hasPaid)? onUpdatePaymentStatus;
  final String? hubPaymentLink; // Payment link from Hub settings

  const PendingGameState({
    super.key,
    required this.game,
    required this.gameId,
    required this.role,
    required this.isCreator,
    required this.isSignedUp,
    required this.isGameFull,
    required this.confirmedSignups,
    required this.pendingSignups,
    required this.playerUsers,
    required this.usersRepo,
    required this.currentUserId,
    required this.onToggleSignup,
    required this.onApprovePlayer,
    required this.onRejectPlayer,
    this.onCancelGame,
    this.onJoinWaitlist,
    this.onUpdatePaymentStatus,
    this.hubPaymentLink,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = isCreator || role == UserRole.admin;
    final showPendingRequests = isAdmin && pendingSignups.isNotEmpty;
    final signupsPending = showPendingRequests ? <GameSignup>[] : pendingSignups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isCreator &&
            !isSignedUp &&
            game.targetingCriteria != null &&
            currentUserId != null)
          FutureBuilder<User?>(
            future: usersRepo.getUser(currentUserId!),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user == null) return const SizedBox.shrink();

              final age = DateTime.now().year - user.birthDate.year;
              final criteria = game.targetingCriteria!;
              final isAgeMatch =
                  (criteria.minAge == null || age >= criteria.minAge!) &&
                      (criteria.maxAge == null || age <= criteria.maxAge!);

              final isGenderMatch = true;

              if (!isAgeMatch || !isGenderMatch) {
                final genderSuffix = criteria.gender == PlayerGender.male
                    ? l10n.genderMaleSuffix
                    : criteria.gender == PlayerGender.female
                        ? l10n.genderFemaleSuffix
                        : '';
                final minAge = criteria.minAge?.toString() ?? '';
                final maxAge = criteria.maxAge?.toString() ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.targetingMismatchWarning(
                            minAge,
                            maxAge,
                            genderSuffix,
                          ),
                          style: const TextStyle(color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        if (currentUserId != null) ...[
          OutlinedButton.icon(
            onPressed: () => context.push('/games/$gameId/chat'),
            icon: const Icon(Icons.chat),
            label: Text(l10n.gameChatButton),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          if ((isCreator || role == UserRole.admin) && onCancelGame != null)
            ElevatedButton.icon(
              onPressed: () => _showCancelGameDialog(context, l10n, onCancelGame!),
              icon: const Icon(Icons.cancel),
              label: const Text('ביטול משחק'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          if ((isCreator || role == UserRole.admin) && onCancelGame != null)
            const SizedBox(height: 12),
          if (!isCreator && !isSignedUp && !isGameFull)
            ElevatedButton.icon(
              onPressed: () => onToggleSignup(context, game, isSignedUp),
              icon: const Icon(Icons.person_add),
              label: Text(game.requiresApproval
                  ? l10n.requestToJoin
                  : l10n.signupForGame),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          if (!isCreator &&
              isSignedUp &&
              pendingSignups.any((s) => s.playerId == currentUserId))
            ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.hourglass_empty),
              label: Text(l10n.requestSentPendingApproval),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey.withValues(alpha: 0.2),
                disabledForegroundColor: Colors.grey,
              ),
            ),
          if (!isCreator &&
              isSignedUp &&
              confirmedSignups.any((s) => s.playerId == currentUserId))
            ElevatedButton.icon(
              onPressed: () => onToggleSignup(context, game, isSignedUp),
              icon: const Icon(Icons.person_remove),
              label: Text(l10n.cancelSignup),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          if (isGameFull && !isSignedUp && onJoinWaitlist != null)
            ElevatedButton.icon(
              onPressed: () => onJoinWaitlist!(context, game),
              icon: const Icon(Icons.list),
              label: const Text('הצטרף לרשימת המתנה'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          if (isGameFull && !isSignedUp && onJoinWaitlist == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(l10n.gameFullWaitlist),
                ],
              ),
            ),
          if (isGameFull &&
              isSignedUp &&
              pendingSignups
                  .any((s) => s.playerId == currentUserId && s.status == SignupStatus.waitlist))
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_empty, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ברשימת המתנה - מקום #${_getWaitlistPosition(confirmedSignups, pendingSignups, currentUserId)}',
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onToggleSignup(context, game, isSignedUp),
                    child: const Text('עזוב רשימה'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
        ],
        if (showPendingRequests) ...[
          Card(
            color: Colors.orange.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        l10n.pendingRequestsTitle(pendingSignups.length),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...pendingSignups.map((signup) => PendingApprovalTile(
                        signup: signup,
                        usersRepo: usersRepo,
                        onApprove: onApprovePlayer,
                        onReject: onRejectPlayer,
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        // Payment tracking (Sprint 2.2)
        if (game.gameCost != null && game.gameCost! > 0)
          PaymentStatusCard(
            game: game,
            confirmedSignups: confirmedSignups,
            playerUsers: playerUsers,
            role: role,
            isCreator: isCreator,
            currentUserId: currentUserId,
            onUpdatePaymentStatus: onUpdatePaymentStatus,
            hubPaymentLink: hubPaymentLink,
          ),
        GameSignupsSection(
          confirmedSignups: confirmedSignups,
          pendingSignups: signupsPending,
          usersRepo: usersRepo,
          isAdmin: isAdmin,
          onRejectPlayer: onRejectPlayer,
        ),
      ],
    );
  }

  Future<void> _showCancelGameDialog(
    BuildContext context,
    AppLocalizations l10n,
    Future<void> Function(String reason) onCancelGame,
  ) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ביטול משחק'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'פעולה זו תבטל את המשחק ותודיע לכל השחקנים הרשומים. האם להמשיך?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'סיבת ביטול (חובה)',
                hintText: 'למשל: מזג אוויר גרוע, מגרש לא זמין',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                // Show error - reason is mandatory
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('אשר ביטול'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      await onCancelGame(reasonController.text.trim());
    }

    reasonController.dispose();
  }

  int _getWaitlistPosition(
    List<GameSignup> confirmedSignups,
    List<GameSignup> pendingSignups,
    String? userId,
  ) {
    if (userId == null) return 0;

    final allSignups = [...confirmedSignups, ...pendingSignups];
    final waitlistSignups = allSignups
        .where((s) => s.status == SignupStatus.waitlist)
        .toList()
      ..sort((a, b) => a.signedUpAt.compareTo(b.signedUpAt));

    return waitlistSignups.indexWhere((s) => s.playerId == userId) + 1;
  }
}
