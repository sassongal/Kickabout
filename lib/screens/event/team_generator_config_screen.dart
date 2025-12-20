import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/logic/team_maker.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/widgets/player_avatar.dart';

/// Configuration screen for team generation
/// Allows managers to review and adjust player ratings before generating teams
class TeamGeneratorConfigScreen extends ConsumerStatefulWidget {
  final String hubId;
  final String eventId;

  const TeamGeneratorConfigScreen({
    super.key,
    required this.hubId,
    required this.eventId,
  });

  @override
  ConsumerState<TeamGeneratorConfigScreen> createState() =>
      _TeamGeneratorConfigScreenState();
}

class _TeamGeneratorConfigScreenState
    extends ConsumerState<TeamGeneratorConfigScreen> {
  bool _isLoading = true;
  bool _isGenerating = false;
  Hub? _hub;
  HubEvent? _event;
  List<User> _registeredUsers = [];
  final Map<String, double> _tempRatings =
      {}; // Temporary ratings for this session
  final Map<String, PlayerRole> _tempRoles =
      {}; // Temporary roles for this session

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final eventsRepo = ref.read(hubEventsRepositoryProvider);
      final usersRepo = ref.read(usersRepositoryProvider);

      // Load hub and event
      final hub = await hubsRepo.getHub(widget.hubId);
      final event = await eventsRepo.getHubEvent(widget.hubId, widget.eventId);

      if (hub == null || event == null) {
        throw Exception('Hub or Event not found');
      }

      debugPrint('🔍 Event: ${event.title}');
      debugPrint('🔍 Event registeredPlayerIds: ${event.registeredPlayerIds}');
      debugPrint(
          '🔍 Event registeredPlayerIds length: ${event.registeredPlayerIds.length}');

      // Load registered users
      final users = await usersRepo.getUsers(event.registeredPlayerIds);
      debugPrint('🔍 Loaded users: ${users.length}');

      if (users.isEmpty) {
        throw Exception('לא ניתן לטעון את חברי ההאב - רשימה ריקה');
      }

      // Load manager ratings from HubMember subcollection
      final hubMembers = await hubsRepo.getHubMembersByIds(
          widget.hubId, event.registeredPlayerIds);
      final managerRatings = <String, double>{};
      for (final member in hubMembers) {
        managerRatings[member.userId] = member.managerRating;
      }

      if (mounted) {
        setState(() {
          _hub = hub;
          _event = event;
          _registeredUsers = users;

          // Initialize temp ratings from HubMember managerRating
          for (final user in users) {
            _tempRatings[user.uid] = managerRatings[user.uid] ?? 3.5;
            _tempRoles[user.uid] =
                PlayerRole.fromPosition(user.preferredPosition);
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  void _updateRating(String userId, double newRating) {
    setState(() {
      _tempRatings[userId] = newRating;
    });
  }

  void _updateRole(String userId, PlayerRole newRole) {
    setState(() {
      _tempRoles[userId] = newRole;
    });
  }

  Future<void> _generateTeams() async {
    if (_event == null || _registeredUsers.isEmpty) return;

    setState(() => _isGenerating = true);

    try {
      // Create PlayerForTeam list with temp ratings
      final playersForTeam = _registeredUsers.map((user) {
        return PlayerForTeam(
          uid: user.uid,
          rating: _tempRatings[user.uid] ?? 3.5,
          role: _tempRoles[user.uid] ?? PlayerRole.midfielder,
        );
      }).toList();

      // Navigate to results screen with the generated teams
      if (mounted) {
        context.push(
          '/events/${widget.eventId}/team-generator/result',
          extra: {
            'hubId': widget.hubId,
            'eventId': widget.eventId,
            'players': playersForTeam,
            'teamCount': _event!.teamCount,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppScaffold(
        title: 'הגדרת מחולל כוחות',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hub == null || _event == null) {
      return AppScaffold(
        title: 'הגדרת מחולל כוחות',
        body: const Center(child: Text('נתונים לא נמצאו')),
      );
    }

    return AppScaffold(
      title: 'הגדרת מחולל כוחות',
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instructions card
                  PremiumCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: PremiumColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'הנחיות',
                                style: PremiumTypography.techHeadline
                                    .copyWith(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'בדוק את הדירוגים והתפקידים של השחקנים. ניתן לשנות באופן זמני עבור אירוע זה.',
                            style: PremiumTypography.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Event info
                  Text(
                    'אירוע: ${_event!.title}',
                    style: PremiumTypography.heading1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_registeredUsers.length} שחקנים נרשמו | ${_event!.teamCount} קבוצות',
                    style: PremiumTypography.bodyMedium.copyWith(
                      color: PremiumColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Players list
                  Text(
                    'שחקנים',
                    style: PremiumTypography.techHeadline
                        .copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  ..._registeredUsers.map((user) {
                    final rating = _tempRatings[user.uid] ?? 3.5;
                    final role = _tempRoles[user.uid] ?? PlayerRole.midfielder;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PremiumCard(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  PlayerAvatar(
                                    user: user,
                                    size: AvatarSize.sm,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name,
                                          style: PremiumTypography.bodyLarge,
                                        ),
                                        Text(
                                          _getRoleDisplayName(role),
                                          style: PremiumTypography.bodySmall
                                              .copyWith(
                                            color:
                                                PremiumColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Rating slider
                              Row(
                                children: [
                                  Text(
                                    'דירוג:',
                                    style: PremiumTypography.bodySmall,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Slider(
                                      value: rating,
                                      min: 1.0,
                                      max: 10.0,
                                      divisions: 90,
                                      label: rating.toStringAsFixed(1),
                                      onChanged: (value) =>
                                          _updateRating(user.uid, value),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      rating.toStringAsFixed(1),
                                      style: PremiumTypography.heading2
                                          .copyWith(
                                        color: PremiumColors.primary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                              // Role selector
                              Wrap(
                                spacing: 8,
                                children: PlayerRole.values.map((r) {
                                  final isSelected = r == role;
                                  return ChoiceChip(
                                    label: Text(_getRoleDisplayName(r)),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) _updateRole(user.uid, r);
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          // Generate button at bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PremiumColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateTeams,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isGenerating ? 'מייצר...' : 'צור כוחות'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: PremiumColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(PlayerRole role) {
    return switch (role) {
      PlayerRole.goalkeeper => 'שוער',
      PlayerRole.defender => 'מגן',
      PlayerRole.midfielder => 'קשר',
      PlayerRole.attacker => 'תוקף',
    };
  }
}
