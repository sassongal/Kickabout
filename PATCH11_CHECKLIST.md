# PATCH 11: Storage (Profile Photos) - Checklist

## סיכום
הוספנו מערכת העלאת תמונות פרופיל עם Firebase Storage, מסך עריכת פרופיל, ו-widget לבחירת תמונות.

## קבצים שנוצרו/עודכנו

### קבצים חדשים:
1. `lib/services/storage_service.dart` - Service לניהול Firebase Storage
2. `lib/widgets/image_picker_button.dart` - Widget לבחירת תמונה (גלריה/מצלמה)
3. `lib/screens/profile/edit_profile_screen.dart` - מסך עריכת פרופיל עם העלאת תמונה

### קבצים שעודכנו:
1. `lib/data/repositories_providers.dart` - הוספת `storageServiceProvider`
2. `lib/routing/app_router.dart` - הוספת route `/profile/:uid/edit`
3. `lib/screens/profile/player_profile_screen.dart` - הוספת כפתור עריכה (רק לפרופיל עצמי)

## תכונות שהוספו:

### Storage Service:
- ✅ `uploadProfilePhoto(uid, imageFile)` - העלאת תמונת פרופיל
- ✅ `uploadProfilePhotoFromBytes(uid, imageBytes)` - העלאת תמונת פרופיל מ-bytes (למקרה של Web)
- ✅ `deleteProfilePhoto(uid)` - מחיקת תמונת פרופיל
- ✅ `uploadGamePhoto(gameId, imageFile)` - העלאת תמונת משחק (לעתיד)
- ✅ `getDownloadUrl(path)` - קבלת URL להורדה

### Image Picker Button:
- ✅ בחירת תמונה מגלריה
- ✅ צילום תמונה במצלמה
- ✅ תצוגת תמונה נוכחית (אם קיימת)
- ✅ Icon עריכה
- ✅ גודל מותאם

### Edit Profile Screen:
- ✅ עריכת שם, אימייל, טלפון, עמדה מועדפת
- ✅ העלאת תמונת פרופיל
- ✅ validation של שדות
- ✅ loading states (טעינה, העלאה)
- ✅ עדכון אוטומטי של פרופיל ב-Firestore

### Player Profile Screen:
- ✅ כפתור עריכה (רק אם זה הפרופיל של המשתמש הנוכחי)
- ✅ Navigation למסך עריכה

## בדיקות:

### 1. קומפילציה:
```bash
flutter pub get
flutter analyze lib/services/storage_service.dart lib/widgets/image_picker_button.dart lib/screens/profile/edit_profile_screen.dart
```

### 2. הרצה:
```bash
flutter run -d chrome
```

### 3. בדיקות ידניות:

#### בדיקת Storage Service:
- [ ] ודא ש-`uploadProfilePhoto` מעלה תמונה ל-Firebase Storage
- [ ] ודא שהתמונה נשמרת ב-`profile_photos/{uid}.jpg`
- [ ] ודא שהפונקציה מחזירה download URL
- [ ] בדוק ש-`deleteProfilePhoto` מוחקת תמונה

#### בדיקת Image Picker Button:
- [ ] ודא שלחיצה על ה-button פותחת bottom sheet
- [ ] בדוק בחירת תמונה מגלריה
- [ ] בדוק צילום תמונה במצלמה
- [ ] ודא שהתמונה הנוכחית מוצגת (אם קיימת)
- [ ] בדוק שה-icon עריכה מוצג

#### בדיקת Edit Profile Screen:
- [ ] נווט ל-`/profile/{uid}/edit` (החלף uid ב-ID של המשתמש הנוכחי)
- [ ] ודא שכל השדות נטענים נכון
- [ ] בדוק validation (שם ריק, אימייל לא תקין)
- [ ] בחר תמונה חדשה
- [ ] ודא שה-loading overlay מוצג בזמן העלאה
- [ ] שמור שינויים
- [ ] ודא שהתמונה מתעדכנת ב-Firestore
- [ ] ודא שהתמונה מוצגת בפרופיל

#### בדיקת Player Profile Screen:
- [ ] ודא שכפתור עריכה מופיע רק בפרופיל עצמי
- [ ] בדוק נווט למסך עריכה
- [ ] ודא שהתמונה מתעדכנת אוטומטית אחרי עריכה

## הערות:
- התמונות נשמרות ב-Firebase Storage ב-`profile_photos/{uid}.jpg`
- התמונות מועלות עם quality 85% ו-max size 800x800
- ה-URL של התמונה נשמר ב-`User.photoUrl` ב-Firestore
- ה-Storage Service תומך גם ב-Web (bytes) וגם ב-Mobile (File)

## שיפורים עתידיים:
- [ ] הוספת אפשרות למחוק תמונה
- [ ] הוספת crop/resize לתמונה לפני העלאה
- [ ] הוספת progress indicator להעלאה
- [ ] הוספת תמיכה ב-game photos
- [ ] הוספת caching לתמונות

## בעיות ידועות:
- אין בעיות ידועות כרגע

## השלב הבא:
האפליקציה מוכנה ל-MVP! ניתן להמשיך עם:
- PATCH 12: Email/Password Auth - הוספת התחברות עם מייל/סיסמה
- או שיפורים נוספים לפי הצורך

