import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/data/repositories.dart';
import 'package:kattrick/l10n/app_localizations.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/features/hubs/domain/models/hub_role.dart';
import 'package:kattrick/shared/domain/models/targeting_criteria.dart';
import 'package:kattrick/features/games/presentation/widgets/strategies/game_detail_sections.dart';

class PendingGameState extends StatelessWidget {
  final Game game;
  final String gameId;
  final UserRole role;
  final bool isCreator;
  final bool isSignedUp;
  final bool isGameFull;
  final List<GameSignup> confirmedSignups;
  final List<GameSignup> pendingSignups;
  final UsersRepository usersRepo;
  final String? currentUserId;
  final Future<void> Function(BuildContext context, Game game, bool isSignedUp)
      onToggleSignup;
  final void Function(String playerId) onApprovePlayer;
  final void Function(String playerId) onRejectPlayer;

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
    required this.usersRepo,
    required this.currentUserId,
    required this.onToggleSignup,
    required this.onApprovePlayer,
    required this.onRejectPlayer,
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
          if (isGameFull && !isSignedUp)
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
}
