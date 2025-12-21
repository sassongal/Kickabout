import 'package:flutter/material.dart';
import 'package:kattrick/models/match_result.dart';
import 'package:kattrick/models/team.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// PendingApprovalsWidget - Shows match results awaiting manager approval
///
/// Allows manager to approve or reject match results submitted by moderators
class PendingApprovalsWidget extends StatelessWidget {
  final List<MatchResult> pendingMatches;
  final List<Team> teams;
  final Function(String matchId) onApprove;
  final Function(String matchId, String reason) onReject;

  const PendingApprovalsWidget({
    super.key,
    required this.pendingMatches,
    required this.teams,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingMatches.isEmpty) {
      return const SizedBox.shrink();
    }

    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${pendingMatches.length}',
                    style: PremiumTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ממתינים לאישור',
                  style: PremiumTypography.techHeadline.copyWith(fontSize: 16),
                ),
                const Spacer(),
                Icon(
                  Icons.pending_actions,
                  color: Colors.orange,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...pendingMatches.map((match) => _buildPendingMatchCard(
                  context,
                  match,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingMatchCard(BuildContext context, MatchResult match) {
    // Find teams by color
    final teamA = teams.firstWhere(
      (t) => (t.color ?? t.name) == match.teamAColor,
      orElse: () => Team(
        teamId: match.teamAColor,
        name: match.teamAColor,
        playerIds: [],
      ),
    );
    final teamB = teams.firstWhere(
      (t) => (t.color ?? t.name) == match.teamBColor,
      orElse: () => Team(
        teamId: match.teamBColor,
        name: match.teamBColor,
        playerIds: [],
      ),
    );

    final teamAColor = teamA.colorValue ?? 0xFF2196F3;
    final teamBColor = teamB.colorValue ?? 0xFFFF5722;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Match result display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Team A
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Color(teamAColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    match.teamAColor,
                    style: PremiumTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${match.scoreA}',
                    style: PremiumTypography.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // VS
              Text(
                '-',
                style: PremiumTypography.bodyMedium.copyWith(
                  color: PremiumColors.textSecondary,
                ),
              ),

              // Team B
              Row(
                children: [
                  Text(
                    '${match.scoreB}',
                    style: PremiumTypography.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    match.teamBColor,
                    style: PremiumTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Color(teamBColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Submission info
          if (match.loggedBy != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 14,
                    color: PremiumColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'הוגש על ידי מנהל',
                    style: PremiumTypography.bodySmall.copyWith(
                      color: PremiumColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onApprove(match.matchId),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('אשר'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(context, match),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('דחה'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, MatchResult match) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('דחיית תוצאה'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'למה אתה דוחה את התוצאה הזו?',
              style: PremiumTypography.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'סיבה',
                hintText: 'לדוגמה: התוצאה שגויה',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('נא להזין סיבה')),
                );
                return;
              }
              Navigator.pop(ctx);
              onReject(match.matchId, reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('דחה'),
          ),
        ],
      ),
    );
  }
}
