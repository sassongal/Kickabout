import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/data/repositories.dart';
import 'package:kattrick/widgets/futuristic/skeleton_loader.dart';

class HubVenuesList extends ConsumerWidget {
  final String hubId;
  final VenuesRepository venuesRepo;

  const HubVenuesList({
    super.key,
    required this.hubId,
    required this.venuesRepo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesStream = venuesRepo.watchVenuesByHub(hubId);

    return StreamBuilder<List<Venue>>(
      stream: venuesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SkeletonLoader(height: 60),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'שגיאה בטעינת מגרשים',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              ],
            ),
          );
        }

        final venues = snapshot.data ?? [];

        if (venues.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.location_off,
                  size: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  'אין מגרשים רשומים',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'מגרשים (${venues.length})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...venues.map((venue) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              venue.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            if (venue.address != null &&
                                venue.address!.isNotEmpty)
                              Text(
                                venue.address ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }
}
