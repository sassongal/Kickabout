import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/core/providers/auth_providers.dart';
import 'package:kattrick/core/providers/repositories_providers.dart';
import 'package:kattrick/core/providers/services_providers.dart';
import 'package:kattrick/features/games/domain/models/game.dart';
import 'package:kattrick/features/hubs/domain/models/hub.dart';
import 'package:kattrick/features/profile/domain/models/user.dart';
import 'package:kattrick/features/venues/domain/models/venue.dart';
import 'package:kattrick/shared/domain/models/enums/game_status.dart';
import 'package:kattrick/shared/domain/models/enums/signup_status.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Premium Map Card - A beautiful, interactive card for map markers
///
/// **Features:**
/// - Glassmorphic design with blur effect
/// - Polymorphic rendering (User/Game/Venue/Hub)
/// - Slide-up animation (300ms, easeOutCubic)
/// - Linktivity: Tappable card body + Quick action button
/// - Distance calculation from user location
///
/// **Usage:**
/// ```dart
/// PremiumMapCard(
///   item: selectedMarkerItem, // User | Game | Venue | Hub
///   userLocation: currentPosition,
///   onClose: () => setState(() => _selectedItem = null),
/// )
/// ```
class PremiumMapCard extends ConsumerWidget {
  const PremiumMapCard({
    super.key,
    required this.item,
    required this.onClose,
    this.userLocation,
  });

  final dynamic item; // User | Game | Venue | Hub
  final VoidCallback onClose;
  final Position? userLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToDetail(context),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Left: Avatar/Image
                      _buildAvatar(),
                      const SizedBox(width: 16),

                      // Middle: Title, Subtitle, Badge
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTitle(context),
                            const SizedBox(height: 4),
                            _buildSubtitle(context),
                            const SizedBox(height: 8),
                            _buildBadge(context),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Right: Quick Action Button
                      _buildQuickActionButton(context, ref),

                      // Close button (X)
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build avatar based on item type
  Widget _buildAvatar() {
    if (item is User) {
      final user = item as User;
      return CircleAvatar(
        radius: 30,
        backgroundColor: PremiumColors.primary,
        backgroundImage:
            user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
        child: user.photoUrl == null
            ? Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      );
    } else if (item is Game) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: PremiumColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.sports_soccer,
          color: PremiumColors.primary,
          size: 32,
        ),
      );
    } else if (item is Venue) {
      final venue = item as Venue;
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _getVenueSurfaceIcon(venue.surfaceType),
          color: Colors.green,
          size: 32,
        ),
      );
    } else if (item is Hub) {
      final hub = item as Hub;
      return CircleAvatar(
        radius: 30,
        backgroundColor: Colors.blue,
        backgroundImage: hub.logoUrl != null ? NetworkImage(hub.logoUrl!) : null,
        child: hub.logoUrl == null
            ? const Icon(Icons.groups, color: Colors.white, size: 32)
            : null,
      );
    }

    // Fallback
    return const CircleAvatar(
      radius: 30,
      backgroundColor: Colors.grey,
      child: Icon(Icons.location_on, color: Colors.white, size: 32),
    );
  }

  /// Build title based on item type
  Widget _buildTitle(BuildContext context) {
    String title = '';

    if (item is User) {
      title = (item as User).name;
    } else if (item is Game) {
      final game = item as Game;
      // Game doesn't have 'title', use location or default
      title = game.location ?? 'משחק';
    } else if (item is Venue) {
      title = (item as Venue).name;
    } else if (item is Hub) {
      title = (item as Hub).name;
    }

    return Text(
      title,
      style: PremiumTypography.labelLarge.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Build subtitle (distance + type-specific info)
  Widget _buildSubtitle(BuildContext context) {
    final distanceText = _calculateDistance();
    String typeInfo = '';

    if (item is User) {
      final user = item as User;
      final rating = user.currentRankScore;
      typeInfo = '⭐ ${rating.toStringAsFixed(1)}';
    } else if (item is Game) {
      final game = item as Game;
      typeInfo = game.location ?? '';
    } else if (item is Venue) {
      final venue = item as Venue;
      typeInfo = _getVenueSurfaceText(venue.surfaceType);
    } else if (item is Hub) {
      final hub = item as Hub;
      typeInfo = '${hub.memberCount} חברים';
    }

    return Row(
      children: [
        if (distanceText != null) ...[
          const Icon(Icons.near_me, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            distanceText,
            style: PremiumTypography.bodySmall.copyWith(color: Colors.grey[600]),
          ),
          if (typeInfo.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text('•', style: TextStyle(color: Colors.grey[400])),
            const SizedBox(width: 8),
          ],
        ],
        if (typeInfo.isNotEmpty)
          Expanded(
            child: Text(
              typeInfo,
              style: PremiumTypography.bodySmall.copyWith(color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  /// Build status badge based on item type
  Widget _buildBadge(BuildContext context) {
    Color badgeColor = Colors.grey;
    String badgeText = '';
    IconData? badgeIcon;

    if (item is Game) {
      final game = item as Game;
      switch (game.status) {
        case GameStatus.recruiting:
          badgeColor = Colors.green;
          badgeText = 'מגייסים';
          badgeIcon = Icons.people_outline;
          break;
        case GameStatus.inProgress:
          badgeColor = Colors.orange;
          badgeText = 'משחק חי';
          badgeIcon = Icons.sports_soccer;
          break;
        case GameStatus.scheduled:
          badgeColor = Colors.blue;
          badgeText = 'קבוע';
          badgeIcon = Icons.event;
          break;
        default:
          badgeColor = Colors.grey;
          badgeText = game.status.name;
      }
    } else if (item is Venue) {
      final venue = item as Venue;
      badgeColor = venue.isPublic ? Colors.green : Colors.orange;
      badgeText = venue.isPublic ? 'ציבורי' : 'פרטי';
      badgeIcon = venue.isPublic ? Icons.public : Icons.lock;
    } else if (item is Hub) {
      final hub = item as Hub;
      // Hub doesn't have isPublic, use isPrivate instead
      badgeColor = !hub.isPrivate ? Colors.blue : Colors.purple;
      badgeText = !hub.isPrivate ? 'פתוח להצטרפות' : 'פרטי';
      badgeIcon = !hub.isPrivate ? Icons.public : Icons.lock;
    } else if (item is User) {
      final user = item as User;
      // User doesn't have isAvailableForGames, use isActive instead
      if (user.isActive) {
        badgeColor = Colors.green;
        badgeText = 'זמין למשחק';
        badgeIcon = Icons.check_circle;
      } else {
        badgeColor = Colors.grey;
        badgeText = 'לא זמין';
        badgeIcon = Icons.cancel;
      }
    }

    if (badgeText.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeIcon != null) ...[
            Icon(badgeIcon, size: 14, color: badgeColor),
            const SizedBox(width: 4),
          ],
          Text(
            badgeText,
            style: PremiumTypography.labelSmall.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Build quick action button based on item type
  Widget _buildQuickActionButton(BuildContext context, WidgetRef ref) {
    IconData icon = Icons.chevron_left;
    Color color = PremiumColors.primary;

    if (item is User) {
      icon = Icons.message;
      color = Colors.blue;
    } else if (item is Game) {
      icon = Icons.add_circle;
      color = Colors.green;
    } else if (item is Venue) {
      icon = Icons.navigation;
      color = Colors.orange;
    } else if (item is Hub) {
      icon = Icons.group_add;
      color = Colors.purple;
    }

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () => _handleQuickAction(context, ref),
        icon: Icon(icon, color: color),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  /// Calculate distance from user location
  String? _calculateDistance() {
    if (userLocation == null) return null;

    double? lat;
    double? lng;

    if (item is Game) {
      final game = item as Game;
      if (game.locationPoint != null) {
        lat = game.locationPoint!.latitude;
        lng = game.locationPoint!.longitude;
      }
    } else if (item is Venue) {
      final venue = item as Venue;
      lat = venue.location.latitude;
      lng = venue.location.longitude;
    } else if (item is Hub) {
      final hub = item as Hub;
      if (hub.primaryVenueLocation != null) {
        lat = hub.primaryVenueLocation!.latitude;
        lng = hub.primaryVenueLocation!.longitude;
      }
    } else if (item is User) {
      final user = item as User;
      // User has location (GeographicPoint?) not lastKnownLocation
      if (user.location != null) {
        lat = user.location!.latitude;
        lng = user.location!.longitude;
      }
    }

    if (lat == null || lng == null) return null;

    final distanceMeters = Geolocator.distanceBetween(
      userLocation!.latitude,
      userLocation!.longitude,
      lat,
      lng,
    );

    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} מ\'';
    } else {
      final distanceKm = distanceMeters / 1000;
      return '${distanceKm.toStringAsFixed(1)} ק"מ';
    }
  }

  /// Navigate to detail screen based on item type
  void _navigateToDetail(BuildContext context) {
    if (item is User) {
      final user = item as User;
      context.push('/profile/${user.uid}');
    } else if (item is Game) {
      final game = item as Game;
      context.push('/games/${game.gameId}'); // Fixed: /games/:id not /game/:gameId
    } else if (item is Venue) {
      // No venue detail screen exists - navigate to discover venues instead
      context.push('/venues/discover');
    } else if (item is Hub) {
      final hub = item as Hub;
      context.push('/hubs/${hub.hubId}'); // Fixed: /hubs/:id not /hub/:hubId
    }
  }

  /// Handle quick action button based on item type
  Future<void> _handleQuickAction(BuildContext context, WidgetRef ref) async {
    final currentUserId = ref.read(currentUserIdProvider);

    if (currentUserId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('יש להתחבר תחילה')),
        );
      }
      return;
    }

    if (item is User) {
      // Message action - create conversation and navigate
      final user = item as User;
      try {
        final pmRepo = ref.read(privateMessagesRepositoryProvider);
        final conversationId = await pmRepo.getOrCreateConversation(
          currentUserId,
          user.uid,
        );

        if (context.mounted) {
          await context.push('/messages/$conversationId');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('שגיאה בפתיחת שיחה: $e')),
          );
        }
      }
    } else if (item is Game) {
      // Quick join game
      final game = item as Game;
      try {
        final signupService = ref.read(gameSignupServiceProvider);
        await signupService.setSignup(
          game.gameId,
          currentUserId,
          SignupStatus.confirmed,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('הצטרפת למשחק "${game.location ?? 'משחק'}" בהצלחה!'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'פרטים',
                textColor: Colors.white,
                onPressed: () => context.push('/games/${game.gameId}'),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'פרטים',
                textColor: Colors.white,
                onPressed: () => context.push('/games/${game.gameId}'),
              ),
            ),
          );
        }
      }
    } else if (item is Venue) {
      // Navigation action - open Waze/Google Maps
      final venue = item as Venue;
      await _openNavigation(
        venue.location.latitude,
        venue.location.longitude,
        venue.name,
        context,
      );
    } else if (item is Hub) {
      // Request join hub
      final hub = item as Hub;
      try {
        final membershipService = ref.read(hubMembershipServiceProvider);
        await membershipService.addMember(
          hubId: hub.hubId,
          userId: currentUserId,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('הצטרפת ל-${hub.name} בהצלחה!'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'פרטים',
                textColor: Colors.white,
                onPressed: () => context.push('/hubs/${hub.hubId}'),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'פרטים',
                textColor: Colors.white,
                onPressed: () => context.push('/hubs/${hub.hubId}'),
              ),
            ),
          );
        }
      }
    }
  }

  /// Open navigation to location (Waze or Google Maps)
  Future<void> _openNavigation(
    double lat,
    double lng,
    String name,
    BuildContext context,
  ) async {
    // Try Waze first (preferred in Israel)
    final wazeUrl = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');

    if (await canLaunchUrl(wazeUrl)) {
      await launchUrl(wazeUrl);
      return;
    }

    // Fallback to Google Maps
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('לא ניתן לפתוח ניווט')),
        );
      }
    }
  }

  /// Get venue surface icon
  IconData _getVenueSurfaceIcon(String surfaceType) {
    switch (surfaceType.toLowerCase()) {
      case 'grass':
        return Icons.grass;
      case 'artificial':
        return Icons.layers;
      case 'concrete':
        return Icons.square;
      default:
        return Icons.sports_soccer;
    }
  }

  /// Get venue surface text (Hebrew)
  String _getVenueSurfaceText(String surfaceType) {
    switch (surfaceType.toLowerCase()) {
      case 'grass':
        return 'דשא טבעי';
      case 'artificial':
        return 'דשא סינטטי';
      case 'concrete':
        return 'בטון';
      default:
        return surfaceType;
    }
  }
}
