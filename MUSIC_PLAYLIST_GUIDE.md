# 🎵 מדריך Kattrick Music Playlist

## סקירה כללית

מערכת פלייליסט מוזיקה מתקדמת עם 5 רצועות מוזיקה (k1.mp3 - k5.mp3) שמנוגנות באקראי ברקע האפליקציה.

---

## ✨ תכונות

### 🎲 Shuffle אוטומטי
- הרצועות מנוגנות בסדר אקראי
- עם סיום הפלייליסט - ערבוב מחדש אוטומטי
- אין חזרות על רצועה אותה עד שכל הרצועות נוגנו

### 🎚️ בקרת עוצמת קול
- סליידר עוצמת קול (0% - 100%)
- הגדרות נשמרות אוטומטית ל-SharedPreferences
- עוצמת הקול נשמרת בין הפעלות של האפליקציה

### 🔇 מצב השתקה
- כפתור mute/unmute
- ההגדרה נשמרת בין הפעלות
- ניתן להשתיק בלי לאבד את הגדרת עוצמת הקול

### ⏭️ דילוג לשיר הבא
- כפתור "Next" עם תצוגה מקדימה של 2 השירים הבאים
- בחירה ידנית של השיר הבא מתוך 2 אופציות
- דילוג מהיר בין רצועות

### 🎮 נגינה אוטומטית
- המוזיקה מתחילה לנגן אוטומטית בהפעלת האפליקציה
- מעבר אוטומטי לשיר הבא בסיום רצועה
- Play/Pause controls

---

## 📂 מבנה הקבצים

```
lib/features/audio/
├── infrastructure/
│   └── services/
│       └── playlist_service.dart       # שירות ניהול הפלייליסט (Singleton)
└── presentation/
    ├── screens/
    │   └── audio_settings_screen.dart  # מסך הגדרות שמע מלא
    └── widgets/
        └── floating_music_player.dart  # נגן צף קטן (Floating Widget)

assets/sound/
├── k1.mp3  # Track 1
├── k2.mp3  # Track 2
├── k3.mp3  # Track 3
├── k4.mp3  # Track 4
└── k5.mp3  # Track 5
```

---

## 🚀 איך זה עובד?

### 1. אתחול אוטומטי (main.dart)

```dart
// In _initializeBackgroundServices()
final playlist = PlaylistService();
await playlist.initialize();
await playlist.play(); // Auto-start music
```

המוזיקה מתחילה לנגן **אוטומטית** בהפעלת האפליקציה.

---

### 2. שימוש ב-FloatingMusicPlayer

הוסף את הנגן הצף לכל מסך:

```dart
Stack(
  children: [
    // Your main content
    MyHomeScreen(),

    // Floating music player at bottom
    Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: FloatingMusicPlayer(),
    ),
  ],
)
```

**תכונות הנגן הצף:**
- ▶️ Play/Pause
- ⏭️ Next (עם בחירת שיר מתוך 2 אופציות)
- 🔇 Mute/Unmute
- תצוגת השיר הנוכחי

---

### 3. מסך הגדרות מלא

ניווט למסך ההגדרות:

```dart
context.push('/settings/audio');
```

**מה יש במסך ההגדרות:**
- 📊 תצוגת רצועה נוכחית
- ▶️ בקרי נגינה (Play/Pause, Next)
- 🎚️ סליידר עוצמת קול עם אחוזים
- 🔇 מתג השתקה
- ℹ️ מידע על הפלייליסט

---

## 🛠️ API של PlaylistService

### Singleton Pattern

```dart
final playlist = PlaylistService(); // Always returns same instance
```

### Methods

#### `initialize()`
אתחול הפלייליסט (נקרא פעם אחת ב-main.dart)
```dart
await playlist.initialize();
```

#### `play()`
התחל/המשך נגינה
```dart
await playlist.play();
```

#### `pause()`
עצור נגינה
```dart
await playlist.pause();
```

#### `nextTrack()`
דלג לרצועה הבאה
```dart
await playlist.nextTrack();
```

#### `setVolume(double volume)`
קבע עוצמת קול (0.0 - 1.0)
```dart
await playlist.setVolume(0.5); // 50%
```

#### `toggleMute()`
החלף מצב השתקה
```dart
await playlist.toggleMute();
```

#### `getNextTrackOptions()`
קבל 2 רצועות הבאות בתור
```dart
List<String> nextTracks = playlist.getNextTrackOptions();
// Returns: ["Track 2", "Track 4"]
```

### Getters

```dart
bool isPlaying = playlist.isPlaying;
bool isMuted = playlist.isMuted;
double volume = playlist.volume; // 0.0 - 1.0
String currentTrack = playlist.currentTrackName; // "Track 3"
int trackNumber = playlist.currentTrackNumber; // 3
int total = playlist.totalTracks; // 5
```

---

## 💾 שמירת הגדרות

הגדרות נשמרות אוטומטית ב-`SharedPreferences`:

| מפתח | ערך | ברירת מחדל |
|------|-----|-----------|
| `kattrick_music_volume` | 0.0 - 1.0 | 0.7 (70%) |
| `kattrick_music_muted` | true/false | false |

---

## 🎨 עיצוב UI

### FloatingMusicPlayer
- 🌟 Glassmorphic design עם blur effect
- 🎨 Gradient background (Primary → Accent)
- 💫 Shadow effects
- 🎯 Compact size (מתאים לכל מסך)

### AudioSettingsScreen
- 📱 PremiumScaffold עם KineticBackground
- 🎨 Cards עם gradients
- 📊 Slider מעוצב עם אחוזים
- ℹ️ מידע מפורט על הפלייליסט

---

## 🔧 Troubleshooting

### המוזיקה לא מתנגנת
1. בדוק שקבצי ה-MP3 נמצאים ב-`assets/sound/`
2. בדוק ש-`pubspec.yaml` מכיל את כל הקבצים
3. הרץ `flutter pub get` ו-`flutter clean`
4. בדוק את היומן: `🎵 [PlaylistService] ...`

### שגיאת טעינה
```
❌ [PlaylistService] Failed to play: ...
```
- בדוק שהקובץ קיים בנתיב: `assets/sound/k1.mp3`
- ודא שה-asset path נכון ב-`pubspec.yaml`

### עוצמת הקול לא נשמרת
- בדוק הרשאות ל-SharedPreferences
- בדוק את היומן: `📥 [PlaylistService] Loaded preferences`

---

## 📱 דוגמאות שימוש

### דוגמה 1: הוסף נגן צף למסך הבית
```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        Scaffold(
          body: YourContent(),
        ),

        // Music player
        Positioned(
          bottom: 80,
          left: 16,
          right: 16,
          child: FloatingMusicPlayer(),
        ),
      ],
    );
  }
}
```

### דוגמה 2: כפתור הגדרות שמע
```dart
IconButton(
  icon: Icon(Icons.music_note),
  onPressed: () => context.push('/settings/audio'),
  tooltip: 'הגדרות שמע',
)
```

### דוגמה 3: בקרת עוצמה מותאמת אישית
```dart
class CustomVolumeControl extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    final playlist = PlaylistService();

    return Slider(
      value: playlist.volume,
      onChanged: (value) async {
        await playlist.setVolume(value);
        setState(() {});
      },
    );
  }
}
```

---

## 🎯 Best Practices

1. **אל תיצור מופעים חדשים** - השתמש ב-Singleton:
   ```dart
   final playlist = PlaylistService(); // ✅ Good
   final playlist = PlaylistService._internal(); // ❌ Bad
   ```

2. **בדוק אתחול** לפני שימוש:
   ```dart
   if (!playlist.isInitialized) {
     await playlist.initialize();
   }
   ```

3. **עדכן UI** לאחר שינויים:
   ```dart
   await playlist.setVolume(0.8);
   setState(() {}); // Update UI
   ```

4. **טפל בשגיאות** בצורה graceful:
   ```dart
   try {
     await playlist.play();
   } catch (e) {
     debugPrint('Failed to play: $e');
     // Show user-friendly error
   }
   ```

---

## 🎉 סיכום

מערכת הפלייליסט מספקת:
- ✅ נגינה אוטומטית של 5 רצועות מוזיקה
- ✅ Shuffle אקראי עם reshuffle אוטומטי
- ✅ בקרת עוצמת קול מלאה
- ✅ השתקה ודילוג לשיר הבא
- ✅ שמירת הגדרות בין הפעלות
- ✅ UI מעוצב וידידותי למשתמש
- ✅ Integration מלא באפליקציה

**נתיב למסך הגדרות:** `/settings/audio`

**שימוש בנגן צף:** `FloatingMusicPlayer()`

**שירות מרכזי:** `PlaylistService()`

---

**נוצר על ידי Claude Code 🤖**
