# הוראות פרסום - Deployment Instructions

## 🚀 לפני בדיקות ידניות - חובה לפרסם!

לפני ביצוע בדיקות ידניות, **חובה לפרסם את ה-Functions המתוקנות**:

### 1. פרסום onGameCreated (תוקן!)

```bash
firebase deploy --only functions:onGameCreated
```

**מה תוקן:**
- ה-Function עכשיו יוצרת פוסטים במבנה הנכון: `/hubs/{hubId}/feed/posts/items/{postId}`
- זה מתאים למבנה שהאפליקציה מצפה לו

### 2. פרסום onHubMessageCreated (תוקן!)

```bash
firebase deploy --only functions:onHubMessageCreated
```

**מה תוקן:**
- ה-Function עכשיו קוראת FCM tokens מ-`/users/{userId}/fcm_tokens/tokens`
- זה מתאים למקום שהאפליקציה שומרת את ה-tokens

### 3. פרסום searchVenues (אם לא מפורסם)

```bash
firebase deploy --only functions:searchVenues
```

**חשוב:** ודא ש-`PLACES_API_KEY` מוגדר:
```bash
firebase functions:config:set places.api_key="YOUR_GOOGLE_PLACES_API_KEY"
```

### 4. פרסום כל ה-Functions (אופציה)

אם אתה רוצה לפרסם הכל בבת אחת:

```bash
firebase deploy --only functions
```

---

## ✅ אחרי הפרסום

לאחר הפרסום, בצע את הבדיקות הידניות לפי `MANUAL_TESTING_GUIDE.md` או `TESTING_CHECKLIST.md`.

---

## 🔍 בדיקת סטטוס הפרסום

לבדוק אם ה-Functions מפורסמות:

```bash
firebase functions:list
```

או ב-Firebase Console:
- לך ל-Firebase Console → Functions
- ודא שהפונקציות מופיעות שם

