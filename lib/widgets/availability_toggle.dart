import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickabout/data/repositories_providers.dart';

/// Widget for toggling player availability status
class AvailabilityToggle extends ConsumerWidget {
  final String userId;
  final String currentStatus;

  const AvailabilityToggle({
    super.key,
    required this.userId,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersRepo = ref.watch(usersRepositoryProvider);

    String getStatusLabel(String status) {
      switch (status) {
        case 'available':
          return 'זמין';
        case 'busy':
          return 'עסוק';
        case 'notAvailable':
          return 'לא זמין';
        default:
          return 'זמין';
      }
    }

    Color getStatusColor(String status) {
      switch (status) {
        case 'available':
          return Colors.green;
        case 'busy':
          return Colors.orange;
        case 'notAvailable':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    IconData getStatusIcon(String status) {
      switch (status) {
        case 'available':
          return Icons.check_circle;
        case 'busy':
          return Icons.schedule;
        case 'notAvailable':
          return Icons.cancel;
        default:
          return Icons.help;
      }
    }

    return PopupMenuButton<String>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getStatusIcon(currentStatus),
            color: getStatusColor(currentStatus),
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            getStatusLabel(currentStatus),
            style: TextStyle(
              color: getStatusColor(currentStatus),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      onSelected: (String newStatus) async {
        try {
          final user = await usersRepo.getUser(userId);
          if (user != null) {
            await usersRepo.updateUser(userId, {
              'availabilityStatus': newStatus,
            });
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('שגיאה בעדכון סטטוס: $e')),
            );
          }
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'available',
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('זמין'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'busy',
          child: Row(
            children: [
              Icon(Icons.schedule, color: Colors.orange),
              SizedBox(width: 8),
              Text('עסוק'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'notAvailable',
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red),
              SizedBox(width: 8),
              Text('לא זמין'),
            ],
          ),
        ),
      ],
    );
  }
}

