import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/features/games/domain/models/game_signup.dart';
import 'package:kattrick/features/profile/domain/models/user.dart';
import 'package:kattrick/l10n/app_localizations.dart';
import 'package:kattrick/widgets/common/premium_avatar.dart';

/// Ride-sharing (Trempiyada) card for game detail screen
///
/// Shows:
/// - Drivers offering rides (with available seats)
/// - Players looking for rides
/// - Buttons to offer/request rides
class RideSharingCard extends ConsumerWidget {
  final String gameId;
  final List<GameSignup> signups;
  final Map<String, User> userMap;
  final String? currentUserId;
  final Function(bool offeringRide, int? availableSeats) onOfferRideToggle;
  final Function(bool needsRide, String? driverId) onRequestRideToggle;

  const RideSharingCard({
    super.key,
    required this.gameId,
    required this.signups,
    required this.userMap,
    required this.currentUserId,
    required this.onOfferRideToggle,
    required this.onRequestRideToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (currentUserId == null) {
      return const SizedBox.shrink();
    }

    // Get current user's signup
    final mySignup = signups.firstWhere(
      (s) => s.playerId == currentUserId,
      orElse: () => GameSignup(
        playerId: currentUserId!,
        signedUpAt: DateTime.now(),
      ),
    );

    // Get drivers (players offering rides)
    final drivers = signups
        .where((s) => s.offeringRide && s.availableSeats != null && s.availableSeats! > 0)
        .toList();

    // Get passengers (players needing rides)
    final passengers = signups.where((s) => s.needsRide).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.directions_car, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  l10n.rideSharing,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current user controls
            _buildUserControls(context, l10n, mySignup),

            if (drivers.isNotEmpty || passengers.isNotEmpty) ...[
              const Divider(height: 32),

              // Drivers list
              if (drivers.isNotEmpty) ...[
                Text(
                  l10n.drivers,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...drivers.map((signup) => _buildDriverTile(context, l10n, signup)),
              ],

              // Passengers list
              if (passengers.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.passengersNeeded,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...passengers.map((signup) => _buildPassengerTile(context, signup)),
              ],
            ],

            if (drivers.isEmpty && passengers.isEmpty && !mySignup.offeringRide && !mySignup.needsRide)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.noDriversAvailable,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserControls(BuildContext context, AppLocalizations l10n, GameSignup mySignup) {
    final currentUser = userMap[currentUserId];
    final hasCar = currentUser?.hasCar ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Offer ride button (only if user has a car)
        if (hasCar)
          Row(
            children: [
              Expanded(
                child: mySignup.offeringRide
                    ? ElevatedButton.icon(
                        onPressed: () => onOfferRideToggle(false, null),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: Text(l10n.cancelRideOffer),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: () => _showOfferRideDialog(context, l10n),
                        icon: const Icon(Icons.directions_car, size: 18),
                        label: Text(l10n.offerRide),
                      ),
              ),
            ],
          ),

        const SizedBox(height: 8),

        // Request ride button
        Row(
          children: [
            Expanded(
              child: mySignup.needsRide
                  ? ElevatedButton.icon(
                      onPressed: () => onRequestRideToggle(false, null),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: Text(l10n.cancelRideRequest),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: () => _showRequestRideDialog(context, l10n),
                      icon: const Icon(Icons.person, size: 18),
                      label: Text(l10n.requestRide),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDriverTile(BuildContext context, AppLocalizations l10n, GameSignup signup) {
    final user = userMap[signup.playerId];
    if (user == null) return const SizedBox.shrink();

    final isMyRequest = signup.playerId == currentUserId;

    return ListTile(
      leading: PremiumAvatar(
        user: user,
        radius: 20,
      ),
      title: Text(user.displayName ?? user.name),
      subtitle: Text(l10n.seatsAvailable(signup.availableSeats ?? 0)),
      trailing: isMyRequest
          ? const Chip(
              label: Text('אתה'),
              backgroundColor: Colors.blue,
              labelStyle: TextStyle(color: Colors.white),
            )
          : null,
      dense: true,
    );
  }

  Widget _buildPassengerTile(BuildContext context, GameSignup signup) {
    final user = userMap[signup.playerId];
    if (user == null) return const SizedBox.shrink();

    final isMe = signup.playerId == currentUserId;
    final requestedDriver = signup.requestedDriverId != null
        ? userMap[signup.requestedDriverId]
        : null;

    return ListTile(
      leading: PremiumAvatar(
        user: user,
        radius: 20,
      ),
      title: Text(user.displayName ?? user.name),
      subtitle: requestedDriver != null
          ? Text('ביקש טרמפ מ-${requestedDriver.displayName ?? requestedDriver.name}')
          : null,
      trailing: isMe
          ? const Chip(
              label: Text('אתה'),
              backgroundColor: Colors.blue,
              labelStyle: TextStyle(color: Colors.white),
            )
          : null,
      dense: true,
    );
  }

  void _showOfferRideDialog(BuildContext context, AppLocalizations l10n) {
    int selectedSeats = 2; // Default: 2 available seats

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.offerRide),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.availableSeats),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: selectedSeats > 1
                        ? () => setState(() => selectedSeats--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '$selectedSeats',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: selectedSeats < 7
                        ? () => setState(() => selectedSeats++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () {
                onOfferRideToggle(true, selectedSeats);
                Navigator.of(context).pop();
              },
              child: const Text('אישור'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestRideDialog(BuildContext context, AppLocalizations l10n) {
    final drivers = signups
        .where((s) => s.offeringRide && s.availableSeats != null && s.availableSeats! > 0)
        .toList();

    if (drivers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noDriversAvailable)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectDriver),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final signup = drivers[index];
              final user = userMap[signup.playerId];
              if (user == null) return const SizedBox.shrink();

              return ListTile(
                leading: PremiumAvatar(
                  user: user,
                  radius: 20,
                ),
                title: Text(user.displayName ?? user.name),
                subtitle: Text(l10n.seatsAvailable(signup.availableSeats ?? 0)),
                onTap: () {
                  onRequestRideToggle(true, signup.playerId);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.rideRequestSent)),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );
  }
}
