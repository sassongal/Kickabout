# PATCH 1 — Models (freezed + converters) - Checklist

## 📦 קבצים שנוצרו (13 קבצים)

### Models (7 קבצים)
1. ✅ `lib/models/user.dart` - User model
2. ✅ `lib/models/hub.dart` - Hub model
3. ✅ `lib/models/game.dart` - Game model
4. ✅ `lib/models/game_signup.dart` - GameSignup model
5. ✅ `lib/models/team.dart` - Team model
6. ✅ `lib/models/game_event.dart` - GameEvent model
7. ✅ `lib/models/rating_snapshot.dart` - RatingSnapshot model

### Enums (3 קבצים)
8. ✅ `lib/models/enums/game_status.dart` - GameStatus enum
9. ✅ `lib/models/enums/signup_status.dart` - SignupStatus enum
10. ✅ `lib/models/enums/event_type.dart` - EventType enum

### Converters (1 קובץ)
11. ✅ `lib/models/converters/timestamp_converter.dart` - TimestampConverter

### Barrel File (1 קובץ)
12. ✅ `lib/models/models.dart` - Export all models

### Tests (4 קבצים)
13. ✅ `test/models/user_test.dart` - User tests skeleton
14. ✅ `test/models/hub_test.dart` - Hub tests skeleton
15. ✅ `test/models/game_test.dart` - Game tests skeleton
16. ✅ `test/models/team_test.dart` - Team tests skeleton

### Updated Files (1 קובץ)
17. ✅ `pubspec.yaml` - Added freezed, json_serializable, build_runner

## 🔧 Shell Commands

### 1. התקנת Dependencies
```bash
flutter pub get
```

### 2. יצירת Generated Files (build_runner)
```bash
dart run build_runner build --delete-conflicting-outputs
```

או עם watch mode (לפיתוח):
```bash
dart run build_runner watch --delete-conflicting-outputs
```

### 3. בדיקת קומפילציה
```bash
flutter analyze
```

### 4. הרצת Tests
```bash
flutter test
```

## ✅ Manual Test Checklist

### בדיקה 1: Build Runner Success
- [ ] `dart run build_runner build --delete-conflicting-outputs` רץ בהצלחה
- [ ] נוצרו קבצי `.freezed.dart` ו-`.g.dart` לכל model
- [ ] אין שגיאות build

### בדיקה 2: Models Compilation
- [ ] `flutter analyze` עובר ללא שגיאות
- [ ] כל ה-models מקומפלים בהצלחה
- [ ] אין שגיאות import

### בדיקה 3: JSON Serialization
- [ ] User.fromJson() עובד
- [ ] User.toJson() עובד
- [ ] Hub.fromJson() עובד
- [ ] Game.fromJson() עובד
- [ ] כל ה-models תומכים ב-JSON serialization

### בדיקה 4: Enums
- [ ] GameStatus.fromFirestore() עובד
- [ ] SignupStatus.fromFirestore() עובד
- [ ] EventType.fromFirestore() עובד
- [ ] כל ה-enums תומכים ב-Firestore conversion

### בדיקה 5: Firestore Converters
- [ ] TimestampConverter עובד עם Timestamp
- [ ] TimestampConverter עובד עם String
- [ ] TimestampConverter עובד עם int
- [ ] כל ה-converters מוגדרים נכון

## 🐛 Expected Issues & Solutions

### Issue 1: Build Runner Fails
**Solution**: ודא ש-freezed ו-json_serializable מותקנים:
```bash
flutter pub get
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Issue 2: Missing Generated Files
**Solution**: ודא שה-part directives נכונים:
- `part 'model.freezed.dart';`
- `part 'model.g.dart';`

### Issue 3: TimestampConverter Not Found
**Solution**: ודא ש-TimestampConverter מיובא:
```dart
import 'package:kickabout/models/converters/timestamp_converter.dart';
```

### Issue 4: Enum Conversion Errors
**Solution**: ודא שה-enums מיישמים `toFirestore()` ו-`fromFirestore()`

## 📝 Notes

1. **Build Runner**: צריך להריץ `build_runner` אחרי כל שינוי ב-models
2. **Freezed**: כל ה-models משתמשים ב-freezed ל-immutability
3. **JSON Serialization**: כל ה-models תומכים ב-JSON עם `json_serializable`
4. **Firestore Converters**: כל ה-models כוללים converters ל-Firestore
5. **Enums**: כל ה-enums תומכים ב-Firestore string conversion

## ✅ Success Criteria

- [x] כל ה-models נוצרו
- [x] כל ה-enums נוצרו
- [x] כל ה-converters נוצרו
- [x] Dependencies נוספו ל-pubspec.yaml
- [x] Test skeletons נוצרו
- [ ] Build runner רץ בהצלחה (לבדוק)
- [ ] כל ה-models מקומפלים (לבדוק)
- [ ] JSON serialization עובד (לבדוק)

## 🚀 Next Steps

אחרי ש-PATCH 1 עובד:
- PATCH 2: Firestore paths + repositories
- PATCH 3: Routing + shell + nav
- PATCH 4: Auth UI
- PATCH 5: Hubs screens

## 📚 Generated Files

לאחר הרצת build_runner, הקבצים הבאים ייווצרו:
- `lib/models/user.freezed.dart`
- `lib/models/user.g.dart`
- `lib/models/hub.freezed.dart`
- `lib/models/hub.g.dart`
- `lib/models/game.freezed.dart`
- `lib/models/game.g.dart`
- `lib/models/game_signup.freezed.dart`
- `lib/models/game_signup.g.dart`
- `lib/models/team.freezed.dart`
- `lib/models/team.g.dart`
- `lib/models/game_event.freezed.dart`
- `lib/models/game_event.g.dart`
- `lib/models/rating_snapshot.freezed.dart`
- `lib/models/rating_snapshot.g.dart`
