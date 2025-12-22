import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/widgets/premium/spotlight_card.dart';
import 'package:kattrick/widgets/premium/empty_state.dart';
import 'package:kattrick/widgets/premium/skeleton_loader.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/services/error_handler_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';

/// Hub Events Tab - shows events and allows registration
class HubEventsTab extends ConsumerStatefulWidget {
  final String hubId;
  final Hub hub;
  final bool isManager;

  const HubEventsTab({
    super.key,
    required this.hubId,
    required this.hub,
    required this.isManager,
  });

  @override
  ConsumerState<HubEventsTab> createState() => _HubEventsTabState();
}

class _HubEventsTabState extends ConsumerState<HubEventsTab> {
  @override
  Widget build(BuildContext context) {
    final hubEventsRepo = ref.watch(hubEventsRepositoryProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final eventsStream = hubEventsRepo.watchHubEvents(widget.hubId);

    return StreamBuilder<List<HubEvent>>(
      stream: eventsStream,
      builder: (context, snapshot) {
        final slivers = <Widget>[];

        // Create event button (managers only)
        if (widget.isManager) {
          slivers.add(
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/hubs/${widget.hubId}/events/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('צור אירוע'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          slivers.add(
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SkeletonLoader(height: 150),
                  ),
                  childCount: 3,
                ),
              ),
            ),
          );
          return CustomScrollView(slivers: slivers);
        }

        if (snapshot.hasError) {
          slivers.add(
            SliverFillRemaining(
              hasScrollBody: false,
              child: PremiumEmptyState(
                icon: Icons.error_outline,
                title: 'שגיאה בטעינת אירועים',
                message: ErrorHandlerService().handleException(
                  snapshot.error,
                  context: 'Hub events tab',
                ),
                action: ElevatedButton.icon(
                  onPressed: () {
                    // Retry by rebuilding
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('נסה שוב'),
                ),
              ),
            ),
          );
          return CustomScrollView(slivers: slivers);
        }

        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          slivers.add(
            SliverFillRemaining(
              hasScrollBody: false,
              child: PremiumEmptyState(
                icon: Icons.event_note,
                title: 'אין אירועים',
                message: widget.isManager
                    ? 'צור אירוע חדש כדי להתחיל'
                    : 'אין אירועים זמינים כרגע',
                action: widget.isManager
                    ? ElevatedButton.icon(
                        onPressed: () =>
                            context.push('/hubs/${widget.hubId}/events/create'),
                        icon: const Icon(Icons.add),
                        label: const Text('צור אירוע'),
                      )
                    : null,
              ),
            ),
          );
          return CustomScrollView(slivers: slivers);
        }

        final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'he');

        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final event = events[index];
                  final startTime = event.startedAt ?? event.eventDate;
                  final happeningWindowEnd =
                      startTime.add(const Duration(hours: 5));
                  final isHappeningNow = event.isStarted &&
                      DateTime.now().isBefore(happeningWindowEnd);
                  final isRegistered = currentUserId != null &&
                      event.registeredPlayerIds.contains(currentUserId);
                  final isPast = DateTime.now().isAfter(happeningWindowEnd);

                  return SpotlightCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    onTap: widget.isManager
                        ? () => context.push(
                            '/hubs/${widget.hubId}/events/${event.eventId}/manage')
                        : null,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Edit Icon Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: PremiumTypography.techHeadline
                                        .copyWith(
                                      fontSize: 18,
                                    ),
                                  ),
                                  if (isHappeningNow)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: _StatusPill(
                                        label: 'מתרחש',
                                        color: Colors.green,
                                        pulse: true,
                                      ),
                                    )
                                  else if (isPast)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              PremiumColors.surfaceVariant,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'עבר',
                                          style: PremiumTypography.labelSmall
                                              .copyWith(
                                            color:
                                                PremiumColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Edit Icon for Managers
                            if (widget.isManager && !isPast && !event.isStarted)
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                color: PremiumColors.primary,
                                tooltip: 'ערוך פרטי אירוע',
                                onPressed: () => context.push(
                                    '/hubs/${widget.hubId}/events/${event.eventId}/edit'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Description
                        if (event.description != null &&
                            event.description!.isNotEmpty) ...[
                          Text(
                            event.description!,
                            style: PremiumTypography.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                        ],
                        // Date and time
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: PremiumColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateFormat.format(event.eventDate),
                              style: PremiumTypography.bodyMedium,
                            ),
                          ],
                        ),
                        // Location with navigation - load venue if venueId exists
                        if (event.venueId != null &&
                            event.venueId!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          StreamBuilder<Venue?>(
                            stream: ref
                                .read(venuesRepositoryProvider)
                                .watchVenue(event.venueId!),
                            builder: (context, venueSnapshot) {
                              final venue = venueSnapshot.data;
                              final locationText = venue?.name ??
                                  event.location ??
                                  'מיקום לא צוין';
                              final locationPoint =
                                  venue?.location ?? event.locationPoint;

                              if (locationText.isEmpty ||
                                  locationText == 'מיקום לא צוין') {
                                return const SizedBox.shrink();
                              }

                              return Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 18,
                                    color: PremiumColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          locationText,
                                          style:
                                              PremiumTypography.bodyMedium,
                                        ),
                                        if (venue?.address != null &&
                                            venue!.address != locationText)
                                          Text(
                                            venue.address!,
                                            style: PremiumTypography
                                                .bodySmall
                                                .copyWith(
                                              color: PremiumColors
                                                  .textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Navigation button
                                  if (locationPoint != null)
                                    IconButton(
                                      icon: const Icon(Icons.navigation,
                                          size: 20),
                                      color: PremiumColors.primary,
                                      tooltip: 'נווט למגרש',
                                      onPressed: () => _navigateToLocation(
                                        locationPoint.latitude,
                                        locationPoint.longitude,
                                        locationText,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ] else if (event.location != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 18,
                                color: PremiumColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event.location!,
                                  style: PremiumTypography.bodyMedium,
                                ),
                              ),
                              // Navigation button
                              if (event.locationPoint != null)
                                IconButton(
                                  icon: const Icon(Icons.navigation, size: 20),
                                  color: PremiumColors.primary,
                                  tooltip: 'נווט למגרש',
                                  onPressed: () => _navigateToLocation(
                                    event.locationPoint!.latitude,
                                    event.locationPoint!.longitude,
                                    event.location!,
                                  ),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Registered count with max participants
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 18,
                              color: PremiumColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${event.registeredPlayerIds.length}/${event.maxParticipants} נרשמו',
                              style: PremiumTypography.bodySmall.copyWith(
                                color: PremiumColors.textSecondary,
                              ),
                            ),
                            if (event.registeredPlayerIds.length >=
                                event.maxParticipants) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'הרשמה סגורה',
                                  style:
                                      PremiumTypography.labelSmall.copyWith(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Show registered participants list (expandable)
                        if (event.registeredPlayerIds.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _RegisteredParticipantsList(
                            event: event,
                            hubId: widget.hubId,
                          ),
                        ],
                        // Pay via PayBox button (if payment link exists and user is registered)
                        if (widget.hub.paymentLink != null &&
                            widget.hub.paymentLink!.isNotEmpty &&
                            currentUserId != null &&
                            isRegistered &&
                            !isPast) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse(widget.hub.paymentLink!);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                } else {
                                  if (mounted) {
                                    SnackbarHelper.showError(
                                        context, 'לא ניתן לפתוח קישור תשלום');
                                  }
                                }
                              },
                              icon: const Icon(Icons.payment, size: 20),
                              label: const Text('שלם ב-PayBox 💰'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Event Started Logic (Manager Only)
                        if (widget.isManager && !isPast) ...[
                          SwitchListTile(
                            title: const Text('האירוע התחיל'),
                            value: event.isStarted,
                            onChanged: (value) async {
                              if (value == event.isStarted) return;
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('אישור התחלת אירוע'),
                                  content:
                                      const Text('האם אתה בטוח שהאירוע התחיל?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('ביטול'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('אישור'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm != true) return;

                              try {
                                final eventsRepo =
                                    ref.read(hubEventsRepositoryProvider);
                                await eventsRepo.updateHubEvent(
                                  widget.hubId,
                                  event.eventId,
                                  {
                                    'isStarted': value,
                                    'status': value ? 'ongoing' : 'upcoming',
                                    if (value)
                                      'startedAt': FieldValue.serverTimestamp(),
                                  },
                                );
                              } catch (e) {
                                if (mounted) {
                                  final messenger =
                                      ScaffoldMessenger.maybeOf(context);
                                  if (messenger != null) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('שגיאה בעדכון אירוע: $e')),
                                    );
                                  }
                                }
                              }
                            },
                            secondary: const Icon(Icons.timer),
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (event.isStarted) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => context.push(
                                  '/hubs/${widget.hubId}/events/${event.eventId}/team-maker',
                                ),
                                icon: const Icon(Icons.groups),
                                label: const Text('יוצר כוחות'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PremiumColors.accent,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                        // Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (currentUserId != null && !isPast) ...[
                              ElevatedButton.icon(
                                onPressed: (event.registeredPlayerIds.length >=
                                            event.maxParticipants &&
                                        !isRegistered)
                                    ? null
                                    : (isRegistered
                                        // 🔒 LOCK: Cannot unregister if event is started
                                        ? (event.isStarted
                                            ? null
                                            : () => _unregisterFromEvent(event))
                                        : () => _registerToEvent(event)),
                                icon: Icon(
                                  isRegistered
                                      ? Icons.cancel
                                      : Icons.check_circle,
                                ),
                                label: Text(
                                  isRegistered
                                      ? (event.isStarted
                                          ? 'משחק בתהליך'
                                          : 'ביטל הרשמה')
                                      : 'הירשם',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isRegistered
                                      ? PremiumColors.surfaceVariant
                                      : PremiumColors.primary,
                                  foregroundColor: isRegistered
                                      ? PremiumColors.textSecondary
                                      : Colors.white,
                                ),
                              ),
                            ] else if (widget.isManager) ...[
                              // Generate Teams button (if event hasn't passed and no teams exist)
                              if (!isPast && event.teams.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ElevatedButton.icon(
                                    onPressed: () => context.push(
                                        '/hubs/${widget.hubId}/events/${event.eventId}/team-maker'),
                                    icon: const Icon(Icons.group, size: 18),
                                    label: const Text('צור קבוצות'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: PremiumColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ),
                              // Log Game button (if event has passed and no game exists)
                              if (isPast &&
                                  (event.gameId == null ||
                                      event.gameId!.isEmpty))
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ElevatedButton.icon(
                                    onPressed: () => context.push(
                                        '/hubs/${widget.hubId}/events/${event.eventId}/log-game'),
                                    icon: const Icon(Icons.sports_soccer,
                                        size: 18),
                                    label: const Text('רשום משחק'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: PremiumColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ),
                              // Manage button
                              ElevatedButton.icon(
                                onPressed: () => context.push(
                                    '/hubs/${widget.hubId}/events/${event.eventId}/manage'),
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('ניהול'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PremiumColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteEvent(event),
                                color: PremiumColors.error,
                                tooltip: 'מחק',
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
                childCount: events.length,
              ),
            ),
          ),
        );

        return CustomScrollView(slivers: slivers);
      },
    );
  }

  Future<void> _registerToEvent(HubEvent event) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    // Check if event is full
    if (event.registeredPlayerIds.length >= event.maxParticipants) {
      final joinWaiting = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('האירוע מלא'),
          content: const Text('האם ברצונך להצטרף לרשימת ההמתנה?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('הצטרף'),
            ),
          ],
        ),
      );

      if (joinWaiting != true) return;
    }

    try {
      final hubEventsRepo = ref.read(hubEventsRepositoryProvider);
      final result = await hubEventsRepo.registerToEvent(
          widget.hubId, event.eventId, currentUserId);

      final isWaitingList = result < 0;
      final registrationNumber = result.abs();

      // Create feed post about registration
      try {
        final feedRepo = ref.read(feedRepositoryProvider);
        final usersRepo = ref.read(usersRepositoryProvider);
        final user = await usersRepo.getUser(currentUserId);
        final userName = user?.name ?? 'מישהו';

        String postText;
        if (isWaitingList) {
          postText =
              '$userName הצטרף לרשימת ההמתנה לאירוע "${event.title}" (מקום $registrationNumber)';
        } else {
          postText =
              '$userName נרשם לאירוע "${event.title}" ($registrationNumber/${event.maxParticipants})';
        }

        final feedPost = FeedPost(
          postId: '',
          hubId: widget.hubId,
          authorId: currentUserId,
          type: 'event_registration',
          text: postText,
          entityId: event.eventId,
          createdAt: DateTime.now(),
        );
        await feedRepo.createPost(feedPost);
      } catch (e) {
        debugPrint('Failed to create feed post for event registration: $e');
        // Don't fail registration if feed post fails
      }

      if (!mounted || !context.mounted) return;
      if (isWaitingList) {
        SnackbarHelper.showSuccess(context, 'הצטרפת לרשימת ההמתנה!');
      } else {
        SnackbarHelper.showSuccess(context, 'נרשמת לאירוע!');
      }
    } catch (e) {
      if (!mounted || !context.mounted) return;
      if (e.toString().contains('full')) {
        SnackbarHelper.showError(context, 'האירוע מלא, אין מקום להרשמה נוספת');
      } else {
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _navigateToLocation(
    double latitude,
    double longitude,
    String locationName,
  ) async {
    // Try Waze first, fallback to Google Maps
    final wazeUrl = Uri.parse(
      'https://waze.com/ul?ll=$latitude,$longitude&navigate=yes',
    );
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    // Show dialog to choose navigation app
    if (!mounted) return;

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('בחר אפליקציית ניווט'),
        content: Text('נווט ל$locationName'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('ביטול'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'waze'),
            icon: const Icon(Icons.navigation),
            label: const Text('Waze'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'maps'),
            icon: const Icon(Icons.map),
            label: const Text('Google Maps'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (choice == null || choice == 'cancel' || !mounted) return;

    try {
      final url = choice == 'waze' ? wazeUrl : googleMapsUrl;

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          SnackbarHelper.showError(context, 'לא ניתן לפתוח אפליקציית ניווט');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בפתיחת ניווט: $e');
      }
    }
  }

  Future<void> _unregisterFromEvent(HubEvent event) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    try {
      final hubEventsRepo = ref.read(hubEventsRepositoryProvider);
      await hubEventsRepo.unregisterFromEvent(
          widget.hubId, event.eventId, currentUserId);
      if (!mounted || !context.mounted) return;
      SnackbarHelper.showSuccess(context, 'ביטלת הרשמה לאירוע');
    } catch (e) {
      if (!mounted || !context.mounted) return;
      SnackbarHelper.showErrorFromException(context, e);
    }
  }

  Future<void> _deleteEvent(HubEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת אירוע'),
        content: Text('האם אתה בטוח שברצונך למחוק את האירוע "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('מחק'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final hubEventsRepo = ref.read(hubEventsRepositoryProvider);
        await hubEventsRepo.deleteEvent(widget.hubId, event.eventId);
        if (!mounted || !context.mounted) return;
        SnackbarHelper.showSuccess(context, 'אירוע נמחק');
      } catch (e) {
        if (!mounted || !context.mounted) return;
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }
}

class _StatusPill extends StatefulWidget {
  final String label;
  final Color color;
  final bool pulse;

  const _StatusPill({
    required this.label,
    required this.color,
    this.pulse = false,
  });

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.85,
      upperBound: 1.05,
    );
    if (widget.pulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.label,
        style: PremiumTypography.labelSmall.copyWith(
          color: widget.color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (!widget.pulse) return pill;

    return ScaleTransition(
      scale: _controller,
      child: pill,
    );
  }
}

/// Widget to show registered participants list
class _RegisteredParticipantsList extends ConsumerStatefulWidget {
  final HubEvent event;
  final String hubId;

  const _RegisteredParticipantsList({
    required this.event,
    required this.hubId,
  });

  @override
  ConsumerState<_RegisteredParticipantsList> createState() =>
      _RegisteredParticipantsListState();
}

class _RegisteredParticipantsListState
    extends ConsumerState<_RegisteredParticipantsList> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Row(
            children: [
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: PremiumColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'משתתפים שנרשמו (${widget.event.registeredPlayerIds.length})',
                style: PremiumTypography.bodySmall.copyWith(
                  color: PremiumColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          FutureBuilder<List<User>>(
            future: ref
                .read(usersRepositoryProvider)
                .getUsers(widget.event.registeredPlayerIds),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: KineticLoadingAnimation(size: 40),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('שגיאה בטעינת משתתפים'),
                );
              }

              final users = snapshot.data ?? [];
              if (users.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('אין משתתפים'),
                );
              }

              return Column(
                children: users.map((user) {
                  final index =
                      widget.event.registeredPlayerIds.indexOf(user.uid) + 1;
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundImage: user.photoUrl != null
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null ? Text(user.name[0]) : null,
                    ),
                    title: Text(user.name),
                    trailing: Text(
                      '#$index',
                      style: PremiumTypography.bodySmall.copyWith(
                        color: PremiumColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ],
    );
  }
}
