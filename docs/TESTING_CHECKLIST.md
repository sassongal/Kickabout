# Testing Checklist for Phases 1-3 Refactoring

**Last Updated**: 2025-12-26
**Related Commits**: d7ebc8a, e710ce1

---

## Overview

This checklist helps verify that the Phase 1-3 refactoring changes work correctly before deploying to production.

**Changes to Test**:
- Phase 1: State management migration (16 files)
- Phase 2: Domain model business methods (Hub & Game)
- Phase 3: HubMembershipService integration (3 files)

---

## Phase 1: State Management Testing

### Hub Screens - AsyncValue Pattern

**Test**: All hub screens load correctly with proper loading/error states

- [ ] **hub_invitations_screen.dart**
  - Navigate to Hub → Settings → Invitations
  - Verify invitation code displays
  - Verify share/copy buttons work
  - Check loading state on initial load
  - Test error state (disconnect network)

- [ ] **hub_rules_screen.dart**
  - Navigate to Hub → Rules
  - Verify rules display when present
  - Verify empty state when no rules
  - Check loading spinner
  - Test error handling

- [ ] **hub_roles_screen.dart**
  - Navigate to Hub → Manage Roles (creator only)
  - Verify member list loads
  - Verify role toggles work
  - Check permission restrictions for non-creators

- [ ] **manage_roles_screen.dart**
  - Navigate to Hub → Admin → Manage Roles
  - Verify dropdown role selector
  - Test role updates
  - Verify creator cannot be changed

- [ ] **custom_permissions_screen.dart**
  - Navigate to Hub → Custom Permissions (admin only)
  - Verify permissions UI loads
  - Check access control works

- [ ] **hub_players_list_screen.dart & v2**
  - Navigate to Hub → Players
  - Verify player list displays
  - Check search/filter functionality
  - Test loading states

- [ ] **hub_list_screen.dart**
  - Navigate to Hubs tab
  - Verify all user hubs display
  - Check empty state for new users
  - Test pull-to-refresh

### Game Screens - hubsByMemberStreamProvider

- [ ] **all_events_screen.dart**
  - Navigate to Events screen
  - Verify events from all user hubs load
  - Check loading state
  - Test filtering by hub

- [ ] **create_game_screen.dart**
  - Navigate to Create Game
  - Verify hub selector shows user's hubs
  - Check hub selection works
  - Test game creation flow

- [ ] **game_list_screen.dart**
  - Navigate to Games tab
  - Verify games from all hubs display
  - Check filtering options
  - Test loading/error states

### Memory & Performance Testing

- [ ] **Firebase Listener Reduction**
  - Open Flutter DevTools
  - Navigate through multiple hub screens
  - Check Firebase console → Usage metrics
  - Verify listener count is low (1-2, not 16+)

- [ ] **State Caching**
  - Navigate to Hub screen
  - Navigate away
  - Navigate back to same hub
  - Verify instant load (cached) vs loading spinner

- [ ] **Hot Reload**
  - Make a code change
  - Hot reload
  - Verify hub state persists (keepAlive working)

---

## Phase 2: Domain Model Business Logic

### Hub Model Methods

**Test**: Hub business methods return correct values

- [ ] **Capacity Methods**
  ```dart
  // Test hub.isFull
  // Create hub with maxMembers=10, add 10 members
  // Verify hub.isFull == true
  // Verify hub.hasSpace == false
  // Verify hub.availableSlots == 0
  ```
  - Navigate to Hub Settings
  - Set max members to 10
  - Add members until full
  - Try to join → should show "Hub is full" error

- [ ] **Joining Policies**
  ```dart
  // Test hub.requiresApproval
  // Set joinMode to 'approval'
  // Verify hub.requiresApproval == true
  // Verify hub.allowsAutoJoin == false
  ```
  - Navigate to Hub Settings
  - Toggle join mode between auto/approval
  - Test join flow for each mode
  - Verify approval workflow activates

- [ ] **Role Checks**
  ```dart
  // Test hub.isManager(userId)
  // Test hub.isModerator(userId)
  // Test hub.isActiveMember(userId)
  // Test hub.isCreator(userId)
  ```
  - Check different user roles see correct UI
  - Manager sees admin options
  - Moderator sees moderate options
  - Member sees basic options

- [ ] **Invitation Methods**
  - Verify `hub.inviteCode` returns correct code
  - Test `hub.invitationsEnabled` reflects settings
  - Check invitation links work

### Game Model Methods

**Test**: Game business methods work correctly

- [ ] **Status Predicates**
  - Create game in different states
  - Verify `game.isUpcoming` for new games
  - Verify `game.isActive` for in-progress games
  - Verify `game.isCompleted` for finished games
  - Check `game.isPast` for old games

- [ ] **Participant Management**
  - Add players to game
  - Verify `game.totalParticipants` counts correctly
  - Set max players, fill game
  - Verify `game.isFull` when at capacity
  - Test `game.canAddPlayer(userId)` logic

- [ ] **Time Helpers**
  - Check `game.timeUntilGame` shows correct duration
  - Verify `game.isWithin24Hours` for upcoming games
  - Test `game.timeUntilDisplay` shows Hebrew text

### Value Objects

- [ ] **JoinMode Enum**
  - Set hub to auto join
  - Verify `hub.settings.joinMode == JoinMode.auto`
  - Change to approval
  - Verify `hub.settings.joinMode == JoinMode.approval`
  - Test type safety (no string comparisons in code)

- [ ] **MatchLoggingPolicy Enum**
  - Set different logging policies
  - Verify `policy.canLog()` returns correct permissions
  - Test with different user roles
  - Check Hebrew display names

---

## Phase 3: HubMembershipService Testing

### join_by_invite_screen.dart

**Test**: Service validates business rules and shows typed errors

- [ ] **Normal Join Flow**
  - Get invitation link
  - Open link as new user
  - Join hub
  - Verify success message
  - Verify user added to hub

- [ ] **Hub Full Error**
  - Create hub with maxMembers=2
  - Add 2 members
  - Try to join as 3rd user
  - Verify error: "ה-Hub מלא (2/2 חברים)"
  - Error message should show current/max counts

- [ ] **User Hub Limit Error**
  - Join 10 hubs as one user
  - Try to join 11th hub
  - Verify error: "הגעת למקסימום של 10 Hubs"

- [ ] **Banned User Error**
  - Ban user from hub
  - User tries to join
  - Verify error: "אינך יכול להצטרף ל-Hub זה"

- [ ] **Auto Join vs Approval**
  - Test auto join mode → immediate success
  - Test approval mode → "join request sent" message

### add_manual_player_dialog.dart

**Test**: Manual player addition validates capacity

- [ ] **Normal Flow**
  - Open hub as manager
  - Add manual player
  - Fill in details
  - Submit
  - Verify player added to hub

- [ ] **Hub Full Error**
  - Fill hub to capacity
  - Try to add manual player
  - Verify error: "ה-Hub מלא (X/Y חברים)"

- [ ] **User Hub Limit**
  - Create player with 10 hubs already
  - Try to add to 11th hub
  - Verify error shows

### hub_header.dart

**Test**: Join/Leave button uses service

- [ ] **Join Flow**
  - View hub as non-member
  - Click join button
  - Verify success or proper error
  - Check user added to hub

- [ ] **Capacity Error**
  - View full hub
  - Try to join
  - Verify specific error message

- [ ] **Leave Flow**
  - Join hub
  - Click leave button
  - Verify success message
  - Check user removed

---

## Edge Cases & Error Scenarios

### Network Errors

- [ ] Disconnect network
- [ ] Navigate to hub screen
- [ ] Verify error state shows properly
- [ ] Reconnect network
- [ ] Verify auto-recovery or retry option

### Concurrent Operations

- [ ] Two users try to join full hub simultaneously
- [ ] Verify only one succeeds
- [ ] Other gets "hub full" error

### State Consistency

- [ ] Join hub on one device
- [ ] Verify hub list updates on other device
- [ ] Check member count updates in real-time

---

## Performance Benchmarks

### Before/After Comparison

- [ ] **Firebase Listener Count**
  - Before refactor: ~16 listeners for hub screens
  - After refactor: 1-2 listeners expected
  - Use Firebase console to verify

- [ ] **Memory Usage**
  - Open DevTools → Memory
  - Navigate through 5 different hubs
  - Check memory doesn't grow linearly
  - Verify old listeners are disposed

- [ ] **Screen Load Time**
  - First load: Should see loading spinner
  - Second load (cached): Should be instant
  - Measure with DevTools timeline

---

## Regression Testing

### Existing Functionality

Verify these still work after refactoring:

- [ ] Hub creation
- [ ] Hub settings update
- [ ] Member management (add/remove/ban)
- [ ] Role management
- [ ] Game creation within hub
- [ ] Event management
- [ ] Venue selection
- [ ] Contact hub flow
- [ ] Join request approval

---

## Automated Testing (Future)

### Unit Tests to Write

```dart
// test/models/hub_test.dart
void main() {
  group('Hub business methods', () {
    test('isFull returns true when at capacity', () {
      final hub = Hub(
        maxMembers: 10,
        memberCount: 10,
        // ...
      );
      expect(hub.isFull, true);
    });

    test('isManager returns true for manager', () {
      final hub = Hub(
        managerIds: ['user123'],
        // ...
      );
      expect(hub.isManager('user123'), true);
    });
  });
}

// test/services/hub_membership_service_test.dart
void main() {
  group('HubMembershipService', () {
    test('throws HubCapacityExceededException when hub full', () async {
      // Mock repository to return full hub
      // Call service.addMember()
      // Expect exception thrown
    });
  });
}
```

---

## Sign-Off Checklist

Before deploying to production:

- [ ] All manual tests pass
- [ ] No new errors in Dart analysis
- [ ] Firebase listener count verified
- [ ] Memory usage acceptable
- [ ] User feedback on staging environment
- [ ] Documentation reviewed
- [ ] Team notified of changes

---

## Rollback Plan

If critical issues found:

1. **Immediate Rollback**
   ```bash
   git revert d7ebc8a  # Revert main refactor commit
   git push
   ```

2. **Partial Rollback**
   - Identify specific failing file
   - Revert just that file from d7ebc8a
   - Keep rest of improvements

3. **Forward Fix**
   - Create hotfix branch
   - Fix specific issue
   - Fast-track review/deploy

---

## Notes

- Test on both iOS and Android
- Test with different user roles (creator, manager, moderator, member)
- Test with different hub configurations (auto join, approval, full, empty)
- Monitor Firebase costs for listener reduction
- Collect user feedback on error messages

---

## Related Documentation

- [REFACTORING_PROGRESS.md](../REFACTORING_PROGRESS.md)
- [PHASE_4_IMPLEMENTATION_GUIDE.md](PHASE_4_IMPLEMENTATION_GUIDE.md)
