import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget to display and manage payment status for a game (Sprint 2.2)
class PaymentStatusCard extends StatelessWidget {
  final Game game;
  final List<GameSignup> confirmedSignups;
  final Map<String, User> playerUsers; // Map of userId -> User for player names
  final UserRole role;
  final bool isCreator;
  final String? currentUserId;
  final Future<void> Function(String playerId, bool hasPaid)? onUpdatePaymentStatus;
  final String? hubPaymentLink; // Deep link to Bit/PayBox for direct payment

  const PaymentStatusCard({
    super.key,
    required this.game,
    required this.confirmedSignups,
    required this.playerUsers,
    required this.role,
    required this.isCreator,
    required this.currentUserId,
    this.onUpdatePaymentStatus,
    this.hubPaymentLink,
  });

  Future<void> _openPaymentLink(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    if (hubPaymentLink == null || hubPaymentLink!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.paymentLinkNotConfigured),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(hubPaymentLink!);
      if (await canLaunchUrl(uri)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.openingPaymentApp),
            duration: const Duration(seconds: 1),
          ),
        );
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Cannot launch URL';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.couldNotOpenPaymentLink),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Only show if game has a cost set
    if (game.gameCost == null || game.gameCost! <= 0) {
      return const SizedBox.shrink();
    }

    final isManager = isCreator || role == UserRole.admin;
    final paymentStatus = game.paymentStatus;
    final paidCount = paymentStatus.values.where((paid) => paid).length;
    final totalPlayers = confirmedSignups.length;
    final totalCollected = paidCount * game.gameCost!;
    final totalExpected = totalPlayers * game.gameCost!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.payments, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Text(
                  'תשלום',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '₪${game.gameCost!.toStringAsFixed(0)} לשחקן',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'סטטוס',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$paidCount/$totalPlayers שילמו',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Theme.of(context).dividerColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'סה"כ נגבה',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₪${totalCollected.toStringAsFixed(0)} / ₪${totalExpected.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: paidCount == totalPlayers ? Colors.green : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Manager actions
            if (isManager) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'סמן כשולם',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Player payment checkboxes
              ...confirmedSignups.map((signup) {
                final hasPaid = paymentStatus[signup.playerId] ?? false;
                final playerName = playerUsers[signup.playerId]?.name ?? signup.playerId;
                return CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    playerName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  subtitle: hasPaid
                    ? const Text('שולם', style: TextStyle(color: Colors.green, fontSize: 12))
                    : const Text('ממתין לתשלום', style: TextStyle(color: Colors.orange, fontSize: 12)),
                  value: hasPaid,
                  onChanged: onUpdatePaymentStatus != null
                    ? (bool? value) {
                        if (value != null) {
                          onUpdatePaymentStatus!(signup.playerId, value);
                        }
                      }
                    : null,
                  secondary: Icon(
                    hasPaid ? Icons.check_circle : Icons.pending,
                    color: hasPaid ? Colors.green : Colors.orange,
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Generate payment request message button
              OutlinedButton.icon(
                onPressed: () => _showPaymentRequestDialog(context),
                icon: const Icon(Icons.message),
                label: const Text('צור הודעת תשלום'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],

            // Player view - show their payment status
            if (!isManager && currentUserId != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: paymentStatus[currentUserId] == true
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: paymentStatus[currentUserId] == true
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          paymentStatus[currentUserId] == true ? Icons.check_circle : Icons.pending,
                          color: paymentStatus[currentUserId] == true ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            paymentStatus[currentUserId] == true
                              ? 'סומנת כמי ששילם ✓'
                              : 'ממתין לתשלום של ₪${game.gameCost!.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: paymentStatus[currentUserId] == true ? Colors.green[700] : Colors.orange[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // "Pay Now" button - only show if not paid and payment link is configured
                    if (paymentStatus[currentUserId] != true &&
                        hubPaymentLink != null &&
                        hubPaymentLink!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openPaymentLink(context),
                          icon: const Icon(Icons.payment),
                          label: Text(l10n.payNow),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPaymentRequestDialog(BuildContext context) {
    // Get manager name from current user (simplified for now)
    final unpaidPlayers = confirmedSignups.where((signup) {
      final hasPaid = game.paymentStatus[signup.playerId] ?? false;
      return !hasPaid;
    }).toList();

    if (unpaidPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('כל השחקנים שילמו! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    // Generate payment request message
    final playerNames = unpaidPlayers.map((s) => playerUsers[s.playerId]?.name ?? s.playerId).join(', ');
    final message = '''היי!
המשחק ${game.location != null && game.location!.isNotEmpty ? 'ב-${game.location}' : ''} עולה ₪${game.gameCost!.toStringAsFixed(0)} לשחקן.

נא לשלם למארגן המשחק בביט/פייבוקס.

תודה! ⚽''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('הודעת בקשת תשלום'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'שחקנים שטרם שילמו (${unpaidPlayers.length}):',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              playerNames,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('סגור'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ההודעה הועתקה ללוח! כעת אפשר לשלוח בוואטסאפ'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('העתק ללוח'),
          ),
        ],
      ),
    );
  }
}
