import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kattrick/core/providers/services_providers.dart';
import 'package:kattrick/features/profile/domain/models/user.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/player_avatar.dart';

/// AtmosphericProfileHeader - Premium immersive header for home screen
///
/// Features:
/// - Dynamic time-of-day background images (Day/Sunset/Night)
/// - Real weather service with current temperature
/// - Profile avatar above name
/// - User age and city display
/// - Statistics button navigation
/// - Black overlay + gradient scrim for seamless blending
/// - Premium typography with Montserrat for user name
class AtmosphericProfileHeader extends ConsumerStatefulWidget {
  const AtmosphericProfileHeader({
    required this.user,
    required this.currentUserId,
    super.key,
  });

  final User user;
  final String currentUserId;

  @override
  ConsumerState<AtmosphericProfileHeader> createState() =>
      _AtmosphericProfileHeaderState();
}

class _AtmosphericProfileHeaderState
    extends ConsumerState<AtmosphericProfileHeader> {
  String? _weatherData;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final weatherService = ref.read(weatherServiceProvider);

    // Try to get user location, fallback to Jerusalem coordinates
    final latitude = widget.user.location?.latitude ?? 31.7683;
    final longitude = widget.user.location?.longitude ?? 35.2137;

    final weather = await weatherService.getCurrentWeather(
      latitude: latitude,
      longitude: longitude,
    );

    if (mounted && weather != null) {
      setState(() {
        _weatherData = '${weather.temperature}°C';
      });
    }
  }

  /// Determines which background asset to use based on current time
  String _getBackgroundAsset() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 6 && hour < 17) {
      // Day: 06:00-17:00
      return 'assets/images/Headerlight.png';
    } else if (hour >= 17 && hour < 19) {
      // Sunset: 17:00-19:00
      return 'assets/images/splash/HeaderSunset.png';
    } else {
      // Night: 19:00-06:00
      return 'assets/images/Headernight.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cityDisplay =
        widget.user.city?.isNotEmpty == true ? widget.user.city! : 'ישראל';
    final weatherDisplay = _weatherData ?? 'טוען...';
    final ageDisplay = widget.user.age.toString();
    // Use extension getter for display name (falls back smartly)
    final nameDisplay = UserDisplayName(widget.user).displayName;

    return Semantics(
      label: 'פרופיל $nameDisplay, גיל $ageDisplay, $cityDisplay, מזג אוויר $weatherDisplay',
      child: SizedBox(
        width: double.infinity,
        height: 280, // Optimized height for better screen balance
        child: Stack(
          children: [
            // Background image (time-of-day based)
            Positioned.fill(
              child: Image.asset(
                _getBackgroundAsset(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to gradient background if asset fails
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: PremiumColors.primaryGradient,
                    ),
                  );
                },
              ),
            ),

            // Black overlay for text readability (40% opacity)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ),

            // Bottom scrim gradient (blends into scaffold background)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 200,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      PremiumColors.background, // #FAFAFA
                    ],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
            ),

            // Premium Weather Gadget (top-left)
            Positioned(
              top: 16,
              left: 16,
              child: _PremiumWeatherGadget(
                temperature: weatherDisplay,
              ),
            ),

            // Content layer (avatar, name, metadata, and button)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Profile Avatar (above name)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: PlayerAvatar(
                        user: widget.user,
                        size: AvatarSize.lg, // 96px diameter
                        clickable: false,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // User Name (H1 style, large and bold)
                    Text(
                      nameDisplay,
                      style: GoogleFonts.montserrat(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Metadata row: [Age] • [City] (weather removed from here)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'גיל $ageDisplay • $cityDisplay',
                            style: GoogleFonts.heebo(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.95),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  offset: const Offset(0, 1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Statistics Button
                        _StatisticsButton(
                          onPressed: () => context.push(
                            '/profile/${widget.currentUserId}/performance',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium Weather Gadget - Floating weather display in hero
class _PremiumWeatherGadget extends StatelessWidget {
  const _PremiumWeatherGadget({
    required this.temperature,
  });

  final String temperature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Weather icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.amber.withValues(alpha: 0.8),
                  Colors.orange.withValues(alpha: 0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.wb_sunny,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Temperature
          Text(
            temperature,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Statistics Button - Compact button for navigating to performance screen
class _StatisticsButton extends StatelessWidget {
  const _StatisticsButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1565C0), // Primary blue
            Color(0xFF0D47A1), // Primary dark
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'סטטיסטיקה',
                  style: GoogleFonts.heebo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
