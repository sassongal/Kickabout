import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickadoor/services/connectivity_service.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Offline indicator banner that shows when device is offline
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineStatus = ref.watch(onlineStatusProvider);

    return onlineStatus.when(
      data: (isOnline) {
        if (isOnline) {
          return const SizedBox.shrink();
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: FuturisticColors.warning.withOpacity(0.9),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'אין חיבור לאינטרנט. האפליקציה תעבוד במצב לא מקוון.',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Small offline indicator icon (for AppBar)
class OfflineIndicatorIcon extends ConsumerWidget {
  const OfflineIndicatorIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineStatus = ref.watch(onlineStatusProvider);

    return onlineStatus.when(
      data: (isOnline) {
        if (isOnline) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(
            Icons.cloud_off_rounded,
            size: 20,
            color: FuturisticColors.warning,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Sync status indicator (shows when data is syncing)
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This can be extended to show Firestore sync status
    // For now, we'll just show online/offline status
    final onlineStatus = ref.watch(onlineStatusProvider);

    return onlineStatus.when(
      data: (isOnline) {
        if (!isOnline) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: FuturisticColors.warning.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sync_disabled_rounded,
                  size: 14,
                  color: FuturisticColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  'לא מקוון',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: FuturisticColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

