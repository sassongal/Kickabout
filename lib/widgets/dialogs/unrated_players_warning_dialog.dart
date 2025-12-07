import 'package:flutter/material.dart';
import 'package:kattrick/models/models.dart';

/// Dialog that warns about unrated players before team generation
class UnratedPlayersWarningDialog extends StatelessWidget {
  final List<User> unratedPlayers;
  final VoidCallback onContinue;
  final VoidCallback onRateNow;

  const UnratedPlayersWarningDialog({
    super.key,
    required this.unratedPlayers,
    required this.onContinue,
    required this.onRateNow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning Icon & Title
            Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'שחקנים ללא דירוג',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Warning Message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${unratedPlayers.length} שחקנים ללא דירוג',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'שחקנים אלו יקבלו דירוג ברירת מחדל של 4.0 (אמצע הסקאלה), '
                    'מה שעלול להשפיע על איכות חלוקת הכוחות.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Unrated Players List
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: unratedPlayers.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (context, index) {
                  final player = unratedPlayers[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundImage: player.photoUrl != null
                          ? NetworkImage(player.photoUrl!)
                          : null,
                      child: player.photoUrl == null
                          ? Text(
                              player.name[0].toUpperCase(),
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                    ),
                    title: Text(
                      player.name,
                      style: theme.textTheme.bodyMedium,
                    ),
                    subtitle: Text(
                      player.preferredPosition,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '4.0',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('המשך בכל זאת'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onRateNow,
                    icon: const Icon(Icons.star),
                    label: const Text('דרג עכשיו'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
