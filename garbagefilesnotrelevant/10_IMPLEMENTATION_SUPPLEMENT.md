# 💻 Kattrick - Implementation Supplement
## Detailed Implementation Guide with Code Examples & Flows

> **Last Updated:** January 2025  
> **Version:** 2.0

## Overview

Complete implementation guide with code examples, flow diagrams, and edge cases for all Kattrick features.

## Table of Contents

1. User & Auth
2. Hub Management  
3. Game Logic
4. Social Features
5. Venues & Search
6. Business & Monetization

---

## 1. User & Auth

### 1.1 Date of Birth + Age Groups

**Decision:** All users must provide date of birth (min 13 years old)

**Implementation:**

```dart
// Model
@freezed
class User with _$User {
  const User._();
  
  const factory User({
    required String id,
    required DateTime dateOfBirth, // NEW
    // ... other fields
  }) = _User;
  
  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }
  
  String get ageGroup {
    final currentAge = age;
    if (currentAge >= 13 && currentAge <= 15) return '13-15';
    if (currentAge >= 16 && currentAge <= 18) return '16-18';
    if (currentAge >= 18 && currentAge <= 21) return '18-21';
    if (currentAge >= 21 && currentAge <= 24) return '21-24';
    if (currentAge >= 25 && currentAge <= 27) return '25-27';
    if (currentAge >= 28 && currentAge <= 30) return '28-30';
    if (currentAge >= 31 && currentAge <= 35) return '31-35';
    if (currentAge >= 36 && currentAge <= 40) return '36-40';
    if (currentAge >= 41 && currentAge <= 45) return '41-45';
    if (currentAge >= 46 && currentAge <= 50) return '46-50';
    return '50+';
  }
}
```

**Firestore Schema:**
```javascript
users/{userId}
  └─ dateOfBirth: Timestamp  // Required field
```

**Validation:**
```dart
// In onboarding
if (selectedDate == null) {
  showError('Date of birth is required');
  return;
}

final age = calculateAge(selectedDate);
if (age < 13) {
  showError('You must be at least 13 years old');
  return;
}
```

---

## 2. Hub Management

### 2.1 3 Hub Tiers (Veteran Role)

**Decision:** Introduce "Veteran" role between Manager and Player

**Roles:**
- Owner: Full control
- Manager: Create games, manage members, promote veterans
- Veteran: Can start game recording ONLY
- Player: Basic participation

**Implementation:**

```dart
enum HubMemberRole {
  owner,
  manager,
  veteran,  // NEW
  player,
}
```

**Permissions:**
```dart
bool canRecordGame(HubMemberRole role) {
  return role == HubMemberRole.owner ||
         role == HubMemberRole.manager ||
         role == HubMemberRole.veteran;  // NEW
}

bool canPromoteToVeteran(HubMemberRole role) {
  return role == HubMemberRole.owner ||
         role == HubMemberRole.manager;
}
```

---

## 3. Game Logic

### 3.1 Attendance Confirmation (2 Hours Before)

**Decision:** Send reminder 2h before game, users confirm attendance

**Cloud Function:**
```typescript
export const sendAttendanceReminders = functions.pubsub
  .schedule('every 10 minutes')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const twoHoursLater = new Date(now.toMillis() + 2 * 60 * 60 * 1000);
    
    const games = await admin.firestore()
      .collection('games')
      .where('status', '==', 'pending')
      .where('scheduledAt', '>=', now)
      .where('scheduledAt', '<=', admin.firestore.Timestamp.fromDate(twoHoursLater))
      .where('reminderSent', '==', false)
      .get();
    
    for (const gameDoc of games.docs) {
      const game = gameDoc.data();
      
      // Send FCM to participants
      await admin.messaging().sendMulticast({
        tokens: await getPlayerTokens(game.participants),
        notification: {
          title: 'Game in 2 hours!',
          body: `Confirm your attendance for ${game.venueName}`,
        },
        data: {
          gameId: gameDoc.id,
          action: 'confirm_attendance',
        },
      });
      
      // Mark reminder sent
      await gameDoc.ref.update({ reminderSent: true });
    }
  });
```

**Flutter UI:**
```dart
class AttendanceConfirmationDialog extends ConsumerWidget {
  final String gameId;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text('Confirm Attendance'),
      content: Text('Will you attend this game?'),
      actions: [
        TextButton(
          onPressed: () => _confirmAttendance(ref, 'confirmed'),
          child: Text('Yes, I\'ll be there'),
        ),
        TextButton(
          onPressed: () => _confirmAttendance(ref, 'declined'),
          child: Text('Can\'t make it'),
        ),
      ],
    );
  }
  
  Future<void> _confirmAttendance(WidgetRef ref, String status) async {
    final userId = ref.read(currentUserProvider).value!.id;
    
    await FirebaseFirestore.instance
      .collection('games')
      .doc(gameId)
      .update({
        'attendanceConfirmations.$userId': status,
      });
    
    Navigator.of(context).pop();
  }
}
```

---

## 4. Start Event + Auto-Close

### 4.1 Start Event Button

**Decision:** Allow starting game 30 min before scheduled time, lock teams

**Flutter:**
```dart
class StartEventButton extends ConsumerWidget {
  final Game game;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final scheduledAt = game.scheduledAt;
    final canStartEarly = now.isAfter(scheduledAt.subtract(Duration(minutes: 30)));
    
    if (!canStartEarly) {
      return Text('Can start 30 min before scheduled time');
    }
    
    return ElevatedButton(
      onPressed: () => _startEvent(ref),
      child: Text('Start Event'),
    );
  }
  
  Future<void> _startEvent(WidgetRef ref) async {
    await FirebaseFirestore.instance
      .collection('games')
      .doc(game.id)
      .update({
        'status': 'active',
        'startedAt': FieldValue.serverTimestamp(),
        'teamsLocked': true,  // Lock teams
      });
  }
}
```

### 4.2 Auto-Close Logic

**Cloud Function:**
```typescript
export const autoCloseGames = functions.pubsub
  .schedule('every 1 hour')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    
    // Close pending games (not started within 3h)
    const threeHoursAgo = new Date(now.toMillis() - 3 * 60 * 60 * 1000);
    const pendingGames = await admin.firestore()
      .collection('games')
      .where('status', '==', 'pending')
      .where('scheduledAt', '<=', admin.firestore.Timestamp.fromDate(threeHoursAgo))
      .get();
    
    for (const game of pendingGames.docs) {
      await game.ref.update({
        status: 'archived_not_played',
        archivedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    
    // Close active games (not ended within 5h)
    const fiveHoursAgo = new Date(now.toMillis() - 5 * 60 * 60 * 1000);
    const activeGames = await admin.firestore()
      .collection('games')
      .where('status', '==', 'active')
      .where('startedAt', '<=', admin.firestore.Timestamp.fromDate(fiveHoursAgo))
      .get();
    
    for (const game of activeGames.docs) {
      await game.ref.update({
        status: 'completed',
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        autoCompleted: true,
      });
    }
  });
```

---

## Edge Cases & Solutions

### Edge Case 1: User Changes Time Zone

**Problem:** Age calculation could be wrong if user travels

**Solution:** Store timezone info, recalculate on demand

### Edge Case 2: Game Starts Early But Some Players Not There

**Problem:** Teams locked, but missing players

**Solution:** Allow manager to unlock teams before game starts

---

## Complete code examples for all 24 decisions are available in the original Implementation Supplement document provided.

## Related Documents
- **08_GAP_ANALYSIS.md** - Decisions
- **09_PROFESSIONAL_ROADMAP.md** - Timeline
- **01_CURSOR_COMPLETE_GUIDE.md** - Code patterns
