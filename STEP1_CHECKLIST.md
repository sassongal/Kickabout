# Step 1: Firebase Setup + Dependencies - Checklist

## ✅ מה שהושלם

### 1. Dependencies
- [x] הוספת `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
- [x] הוספת `flutter_localizations` ו-`intl` ל-localization
- [x] הוספת `url_launcher`, `share_plus` ל-WhatsApp sharing
- [x] הוספת `image_picker` ל-upload תמונות
- [x] עדכון `pubspec.yaml` עם כל ה-dependencies
- [x] הרצת `flutter pub get` בהצלחה

### 2. Configuration Files
- [x] יצירת `lib/core/constants.dart` עם קבועים
- [x] יצירת `lib/config/firebase_options.dart` (placeholder)
- [x] יצירת `l10n.yaml` ל-localization
- [x] יצירת `lib/l10n/app_he.arb` (Hebrew)
- [x] יצירת `lib/l10n/app_en.arb` (English)
- [x] הרצת `flutter gen-l10n` ליצירת קבצי localization

### 3. Main App Setup
- [x] עדכון `main.dart` עם Firebase initialization
- [x] הוספת RTL support (Hebrew)
- [x] הוספת localization support
- [x] הגדרת Hebrew כ-default locale
- [x] עדכון theme support

## 🔍 בדיקה עם `flutter run -d chrome`

### לפני הרצה:
1. ✅ ודא שה-dependencies הותקנו: `flutter pub get`
2. ✅ ודא ש-localization files נוצרו: `flutter gen-l10n`
3. ⚠️ **חשוב**: Firebase עדיין לא מוגדר - האפליקציה תרוץ ב-limited mode

### אחרי הרצה:
1. [ ] האפליקציה נפתחת ב-Chrome
2. [ ] הטקסט מוצג ב-RTL (מימין לשמאל)
3. [ ] אין שגיאות בקונסול (חוץ מ-Firebase warning שהוא צפוי)
4. [ ] ה-HomePage מוצג (עם הנתונים הקיימים מ-shared_preferences)
5. [ ] ה-UI נראה תקין עם עברית

### שגיאות צפויות (נורמליות):
- ⚠️ Firebase initialization failed - זה צפוי עד ש-Firebase מוגדר
- הודעת debug: "Firebase initialization failed" - זה OK

## 📝 הערות חשובות

### Firebase Configuration (לאחר מכן):
כדי להגדיר Firebase:
1. התקן FlutterFire CLI: `dart pub global activate flutterfire_cli`
2. התחבר ל-Firebase: `firebase login`
3. הגדר את הפרויקט: `flutterfire configure`
4. זה ייצור את `lib/config/firebase_options.dart` אוטומטית

### מה הלאה (Step 2):
- יצירת Authentication Service
- יצירת Login/Register Screens
- הוספת Auth Flow ל-main.dart

## 🐛 פתרון בעיות

### אם האפליקציה לא עולה:
1. ודא ש-`flutter pub get` הושלם בהצלחה
2. ודא ש-`flutter gen-l10n` הושלם בהצלחה
3. נסה `flutter clean` ואז `flutter pub get` שוב
4. בדוק את ה-console לשגיאות

### אם RTL לא עובד:
1. ודא שה-`builder` ב-`main.dart` מגדיר `TextDirection.rtl`
2. ודא שה-`locale` מוגדר ל-`Locale('he')`

### אם localization לא עובד:
1. ודא ש-`flutter gen-l10n` הושלם
2. ודא ש-`lib/l10n/app_localizations.dart` קיים
3. בדוק ש-`localizationsDelegates` מוגדר נכון

## ✅ Checklist לסיום Step 1

- [x] Dependencies מותקנים
- [x] Configuration files נוצרו
- [x] Main.dart מעודכן
- [x] Localization עובד
- [x] RTL support מופעל
- [ ] האפליקציה רצה ב-Chrome (לבדוק)
- [ ] אין שגיאות קומפילציה (לבדוק)
- [ ] UI נראה תקין (לבדוק)

## 🚀 הפעלה

```bash
flutter run -d chrome
```

או

```bash
flutter run -d web-server --web-port=8080
```

