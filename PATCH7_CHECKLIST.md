# PATCH 7 — Team Maker V1 (Algorithm + UI) - Checklist

## 📦 קבצים שנוצרו/עודכנו (4 קבצים)

### Logic (1 קובץ)
1. ✅ `lib/logic/team_maker.dart` - TeamMaker algorithm עם snake draft + local swap

### UI (1 קובץ)
2. ✅ `lib/ui/team_builder/team_builder_page.dart` - TeamBuilderPage עם balance meter + UI

### Screens (1 קובץ)
3. ✅ `lib/screens/game/team_maker_screen.dart` - TeamMakerScreen עודכן להשתמש ב-TeamBuilderPage

### Tests (1 קובץ)
4. ✅ `test/logic/team_maker_test.dart` - Unit tests skeleton

## 🔧 Shell Commands

### 1. בדיקת קומפילציה
```bash
flutter analyze
```

### 2. הרצת Tests
```bash
flutter test test/logic/team_maker_test.dart
```

### 3. הרצת האפליקציה
```bash
flutter run -d chrome
```

## ✅ Manual Test Checklist

### בדיקה 1: TeamMaker Algorithm
- [ ] createBalancedTeams() יוצר teams עם snake draft
- [ ] createBalancedTeams() עובד עם 2/3/4 teams
- [ ] createBalancedTeams() מקבץ players לפי role
- [ ] localSwap() מפחית stddev
- [ ] calculateBalanceMetrics() מחשב metrics נכון
- [ ] Unit tests עוברים

### בדיקה 2: TeamBuilderPage UI
- [ ] TeamBuilderPage מציג balance meter (stddev)
- [ ] TeamBuilderPage מציג 2-4 columns (לפי teamCount)
- [ ] כל column מציג שם קבוצה + מספר שחקנים
- [ ] כל column מציג רשימת שחקנים עם rating
- [ ] כל column מציג ממוצע rating
- [ ] כפתור "איזון אוטומטי" רץ את האלגוריתם
- [ ] כפתור "שמור קבוצות" שומר teams
- [ ] אחרי שמירה, game status → teamsFormed
- [ ] Loading states מוצגים

### בדיקה 3: TeamMakerScreen
- [ ] TeamMakerScreen בודק שיש מספיק נרשמים
- [ ] TeamMakerScreen מציג warning אם אין מספיק נרשמים
- [ ] TeamMakerScreen מציג TeamBuilderPage אם יש מספיק נרשמים
- [ ] רק confirmed signups נכללים

### בדיקה 4: Algorithm Steps
- [ ] Step 1: Bucket by role עובד (GK/DEF/MID/ATT)
- [ ] Step 2: Snake draft מחלק players נכון
- [ ] Step 3: Local swap מפחית stddev
- [ ] Output: List<Team> עם balance metrics

### בדיקה 5: Balance Metrics
- [ ] Balance meter מציג stddev
- [ ] Balance meter מציג status (מאוזן/לא מאוזן)
- [ ] Balance meter משנה צבע לפי stddev
- [ ] Metrics נכונים (avg, stddev, min, max)

### בדיקה 6: RTL Support
- [ ] כל הטקסט מיושר לימין
- [ ] כל ה-icons מיושרים נכון
- [ ] ה-UI נראה תקין ב-RTL

## 🐛 Expected Issues & Solutions

### Issue 1: Not Enough Players
**Solution**: TeamMakerScreen בודק שיש מספיק נרשמים לפני הצגת TeamBuilderPage

### Issue 2: Algorithm Not Balanced
**Solution**: האלגוריתם משתמש ב-snake draft + local swap כדי לאזן

### Issue 3: Save Teams Fails
**Solution**: ודא ש-Firestore rules מאפשרים write ל-teams subcollection

## 📝 Notes

1. **Algorithm**: Deterministic snake draft + local swap (לא AI)
2. **Role Bucketing**: Players מקובצים לפי preferredPosition
3. **Local Swap**: מנסה pairwise swaps כדי להפחית stddev
4. **Balance Metrics**: מציג avg, stddev, min, max
5. **UI**: 2-4 columns עם balance meter

## ✅ Success Criteria

- [x] TeamMaker algorithm נוצר
- [x] TeamBuilderPage נוצר
- [x] TeamMakerScreen עודכן
- [x] Unit tests skeleton נוצר
- [x] אין שגיאות קומפילציה
- [ ] Unit tests עוברים (לבדוק)
- [ ] האלגוריתם עובד (לבדוק)
- [ ] ה-UI עובד (לבדוק)

## 🚀 Next Steps

אחרי ש-PATCH 7 עובד:
- PATCH 8: Gameday Stats Logger + Recap
- PATCH 9: l10n/RTL polish
- PATCH 10: Developer scripts & checks

## 📚 Features

### TeamMaker Algorithm
- ✅ Bucket players by role (GK/DEF/MID/ATT)
- ✅ Snake draft distributing strongest players first
- ✅ Local swap to reduce stddev
- ✅ Calculate balance metrics
- ✅ Support 2/3/4 teams

### TeamBuilderPage
- ✅ Balance meter (stddev visualization)
- ✅ 2-4 columns display
- ✅ Player list with ratings
- ✅ Average rating per team
- ✅ "איזון אוטומטי" button
- ✅ "שמור קבוצות" button
- ✅ Loading states
- ✅ Error handling

### TeamMakerScreen
- ✅ Check minimum players requirement
- ✅ Display warning if not enough players
- ✅ Display TeamBuilderPage if enough players
- ✅ Only confirmed signups included

