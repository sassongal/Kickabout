# תכנית אדריכלות - Kickabout Flutter App

## מבנה Firestore
```
/users/{uid}
  - name: string
  - email: string
  - photoUrl: string?
  - phoneNumber: string?
  - createdAt: timestamp
  - hubIds: string[]
  - currentRankScore: number
  - preferredPosition: string

/games/{gameId}
  - createdBy: string (uid)
  - hubId: string
  - gameDate: timestamp
  - location: string?
  - teamCount: number (2/3/4)
  - status: string (teamSelection|teamsFormed|inProgress|completed|statsInput)
  - createdAt: timestamp
  - updatedAt: timestamp

/games/{gameId}/signups/{uid}
  - playerId: string (uid)
  - signedUpAt: timestamp
  - status: string (confirmed|pending)

/games/{gameId}/teams/{teamId}
  - name: string
  - playerIds: string[]
  - totalScore: number
  - color: string?

/games/{gameId}/events/{eventId}
  - type: string (goal|assist|save|etc)
  - playerId: string
  - timestamp: timestamp
  - metadata: map

/ratings/{uid}/history/{ratingId}
  - gameId: string
  - playerId: string
  - defense: number
  - passing: number
  - shooting: number
  - dribbling: number
  - physical: number
  - leadership: number
  - teamPlay: number
  - consistency: number
  - submittedBy: string
  - submittedAt: timestamp
  - isVerified: boolean

/hubs/{hubId}
  - name: string
  - description: string?
  - createdBy: string
  - createdAt: timestamp
  - memberIds: string[]
  - settings: map
```

## מבנה קבצים מוצע

### 1. Configuration & Setup
```
lib/
├── main.dart (עם Firebase init + RTL)
├── config/
│   └── firebase_options.dart (generate עם flutterfire)
└── core/
    ├── constants.dart
    └── routes.dart
```

### 2. Models (עם תמיכה ב-Firestore)
```
lib/models/
├── user.dart (User model)
├── player.dart (עודכן - משתמש ב-User)
├── game.dart (עודכן - Firestore)
├── player_stats.dart (עודכן - Firestore)
├── hub.dart (חדש)
├── game_signup.dart (חדש)
├── game_event.dart (חדש)
└── rating.dart (חדש - עבור ratings/history)
```

### 3. Services (Firebase)
```
lib/services/
├── auth_service.dart (Firebase Auth)
├── firestore_service.dart (Base Firestore service)
├── user_service.dart (Firestore /users)
├── hub_service.dart (Firestore /hubs)
├── game_service.dart (Firestore /games)
├── signup_service.dart (Firestore /games/{id}/signups)
├── team_service.dart (Firestore /games/{id}/teams)
├── event_service.dart (Firestore /games/{id}/events)
├── rating_service.dart (Firestore /ratings)
├── storage_service.dart (Firebase Storage)
└── whatsapp_service.dart (WhatsApp sharing)
```

### 4. Screens
```
lib/screens/
├── auth/
│   ├── login_screen.dart
│   └── register_screen.dart
├── hub/
│   ├── hub_list_screen.dart
│   ├── hub_detail_screen.dart
│   └── create_hub_screen.dart
├── game/
│   ├── game_list_screen.dart
│   ├── game_detail_screen.dart
│   ├── game_signup_screen.dart
│   ├── team_formation_screen.dart (עודכן)
│   └── stats_input_screen.dart (עודכן)
├── player/
│   ├── player_list_screen.dart
│   └── player_profile_screen.dart (עודכן)
└── home_screen.dart (עודכן - hub selection)
```

### 5. Widgets
```
lib/widgets/
├── player_card.dart (עודכן)
├── team_display.dart (חדש)
├── rating_input.dart (חדש)
├── hub_card.dart (חדש)
├── game_card.dart (חדש)
└── whatsapp_share_button.dart (חדש)
```

### 6. Utils
```
lib/utils/
├── team_algorithm.dart (עודכן - snake draft + swap)
├── localization.dart (חדש - Hebrew strings)
└── validators.dart (חדש)
```

### 7. Localization
```
lib/l10n/
├── app_he.arb (Hebrew)
└── app_en.arb (English - fallback)
```

### 8. Theme (עודכן - RTL support)
```
lib/theme.dart (עודכן)
```

## שלבי יישום (PR-sized steps)

### Step 1: Firebase Setup + Dependencies
- [ ] הוספת dependencies ל-pubspec.yaml
- [ ] יצירת firebase_options.dart
- [ ] עדכון main.dart ל-Firebase init + RTL
- [ ] בדיקה: `flutter run -d chrome`

### Step 2: Authentication (Auth Service + Screens)
- [ ] auth_service.dart
- [ ] login_screen.dart
- [ ] register_screen.dart
- [ ] עדכון main.dart ל-auth flow
- [ ] בדיקה: התחברות/הרשמה

### Step 3: User Model + Service
- [ ] user.dart model
- [ ] user_service.dart
- [ ] עדכון player.dart להשתמש ב-User
- [ ] בדיקה: יצירת/עדכון user

### Step 4: Hub Model + Service + Screens
- [ ] hub.dart model
- [ ] hub_service.dart
- [ ] hub_list_screen.dart
- [ ] create_hub_screen.dart
- [ ] hub_detail_screen.dart
- [ ] בדיקה: יצירת hub, הצטרפות

### Step 5: Game Model Update + Service (Firestore)
- [ ] עדכון game.dart ל-Firestore
- [ ] game_service.dart (Firestore)
- [ ] signup_service.dart
- [ ] game_list_screen.dart
- [ ] game_detail_screen.dart
- [ ] game_signup_screen.dart
- [ ] בדיקה: יצירת game, הרשמה

### Step 6: Team Formation (Snake Draft + Swap)
- [ ] עדכון team_algorithm.dart (snake draft + local swap)
- [ ] team_service.dart
- [ ] team_formation_screen.dart (עודכן)
- [ ] team_display.dart widget
- [ ] בדיקה: יצירת teams, swap

### Step 7: Ratings System
- [ ] rating.dart model
- [ ] rating_service.dart
- [ ] עדכון player_stats.dart
- [ ] stats_input_screen.dart (עודכן)
- [ ] rating_input.dart widget
- [ ] בדיקה: הזנת ratings, חישוב rank

### Step 8: Events System
- [ ] game_event.dart model
- [ ] event_service.dart
- [ ] הוספת events ל-game_detail_screen
- [ ] בדיקה: יצירת events במהלך המשחק

### Step 9: WhatsApp Sharing
- [ ] whatsapp_service.dart
- [ ] whatsapp_share_button.dart
- [ ] הוספת sharing ל-game_detail_screen, team_formation_screen
- [ ] בדיקה: שיתוף game/teams

### Step 10: Localization (Hebrew RTL)
- [ ] הוספת flutter_localizations ל-pubspec.yaml
- [ ] יצירת app_he.arb
- [ ] עדכון main.dart ל-localization
- [ ] עדכון כל ה-screens ל-use localization
- [ ] בדיקה: RTL, Hebrew text

### Step 11: Storage (Profile Photos)
- [ ] storage_service.dart
- [ ] הוספת upload ל-player_profile_screen
- [ ] בדיקה: העלאת תמונות

### Step 12: Polish & UI Improvements
- [ ] עדכון theme.dart ל-RTL
- [ ] שיפורי UI לפי עברית
- [ ] הוספת loading states
- [ ] הוספת error handling
- [ ] בדיקה: חוויית משתמש מלאה

## Dependencies נדרשים
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  firebase_storage: ^12.0.0
  intl: ^0.19.0
  url_launcher: ^6.3.0
  share_plus: ^10.0.0
  image_picker: ^1.0.0
  google_fonts: ^6.1.0
  fl_chart: ^0.68.0
```

## הערות חשובות
1. **RTL Support**: כל ה-screens חייבים לתמוך ב-RTL
2. **Hebrew First**: כל הטקסטים בעברית, עם fallback לאנגלית
3. **Deterministic Teams**: Snake draft בלבד, swap מקומי (לא AI)
4. **Free Tier**: להימנע מ-AI calls ב-runtime (רק suggestions אופציונליים)
5. **WhatsApp Sharing**: שיתוף קישורים ומידע על games/teams
6. **Hub-based**: כל game שייך ל-hub, כל user יכול להיות ב-multiple hubs

