import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kattrick/features/profile/domain/models/user.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/core/audio/audio_controller.dart';

/// Premium Drawer - Side menu for navigation and profile
class PremiumDrawer extends StatelessWidget {
  final User? user;
  final String currentUserId;
  final VoidCallback onLogout;

  const PremiumDrawer({
    super.key,
    required this.user,
    required this.currentUserId,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return _PremiumDrawerContent(
      user: user,
      currentUserId: currentUserId,
      onLogout: onLogout,
    );
  }
}

class _PremiumDrawerContent extends ConsumerWidget {
  final User? user;
  final String currentUserId;
  final VoidCallback onLogout;

  const _PremiumDrawerContent({
    required this.user,
    required this.currentUserId,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: PremiumColors.surface,
      child: Column(
        children: [
          // Header with User Profile
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: PremiumColors.primaryGradient,
            ),
            currentAccountPicture: user != null
                ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: PlayerAvatar(
                        user: user!, size: AvatarSize.md, clickable: false),
                  )
                : const Icon(Icons.person, size: 60, color: Colors.white),
            accountName: Text(
              user != null ? UserDisplayName(user!).displayName : 'אורח',
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold, color: Colors.white),
            ),
            accountEmail: null,
          ),

          ListTile(
            leading: const Icon(Icons.person_outline,
                color: PremiumColors.textPrimary),
            title: Text('הפרופיל שלי', style: PremiumTypography.bodyMedium),
            onTap: () {
              context.pop(); // Close drawer
              context.push('/profile/$currentUserId');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined,
                color: PremiumColors.textPrimary),
            title: Text('הגדרות', style: PremiumTypography.bodyMedium),
            onTap: () {
              context.pop();
              context.push('/profile/$currentUserId/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline,
                color: PremiumColors.textPrimary),
            title: Text('אודות', style: PremiumTypography.bodyMedium),
            onTap: () {
              context.pop();
              // context.push('/about'); // TODO: Define route
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: PremiumColors.error),
            title: Text('התנתק',
                style: PremiumTypography.bodyMedium
                    .copyWith(color: PremiumColors.error)),
            onTap: () {
              context.pop();
              onLogout();
            },
          ),
          const Spacer(),
          const Divider(),
          // Sound Toggle - Drawer Bottom
          Consumer(
            builder: (context, ref, child) {
              final audioAsync = ref.watch(audioControllerProvider);
              return audioAsync.when(
                data: (isMuted) => ListTile(
                  onTap: () =>
                      ref.read(audioControllerProvider.notifier).toggleMute(),
                  leading: Icon(
                    isMuted ? Icons.music_off : Icons.music_note,
                    color: isMuted
                        ? PremiumColors.textSecondary
                        : PremiumColors.primary,
                  ),
                  title: Text(
                    isMuted ? 'הפעל מוזיקה' : 'השתק מוזיקה',
                    style: PremiumTypography.bodyMedium.copyWith(
                      color: isMuted
                          ? PremiumColors.textSecondary
                          : PremiumColors.primary,
                      fontWeight: isMuted ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  trailing: Switch.adaptive(
                    value: !isMuted,
                    onChanged: (_) =>
                        ref.read(audioControllerProvider.notifier).toggleMute(),
                    activeColor: PremiumColors.primary,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
