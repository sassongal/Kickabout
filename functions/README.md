# Firebase Cloud Functions - Kickadoor

## 📋 סקירה

Cloud Functions לשליחת Push Notifications אוטומטיות ב-Kickadoor.

## 🚀 Functions זמינים

### 1. `onGameCreated`
**Trigger**: כאשר משחק חדש נוצר  
**פעולה**: שולח התראות לכל חברי ההוב (חוץ מיוצר המשחק)

### 2. `onHubMessageCreated`
**Trigger**: כאשר הודעה חדשה נשלחת בצ'אט ההוב  
**פעולה**: שולח התראות לכל חברי ההוב (חוץ מהשולח)

### 3. `onCommentCreated`
**Trigger**: כאשר תגובה חדשה נוספת לפוסט  
**פעולה**: שולח התראה למחבר הפוסט

### 4. `onFollowCreated`
**Trigger**: כאשר משתמש מתחיל לעקוב אחרי משתמש אחר  
**פעולה**: שולח התראה למשתמש שנעקב אחריו

### 5. `sendGameReminder`
**Trigger**: Callable function (נקרא מהאפליקציה)  
**פעולה**: שולח תזכורות למשחק

## 📦 התקנה

```bash
cd functions
npm install
```

## 🧪 בדיקה מקומית

```bash
npm run serve
```

זה יריץ את ה-Functions locally עם Firebase Emulators.

## 🚀 Deploy

```bash
# Deploy כל ה-Functions
firebase deploy --only functions

# Deploy function ספציפי
firebase deploy --only functions:onGameCreated
```

## 📝 הערות חשובות

1. **FCM Tokens**: המשתמשים צריכים לשמור את ה-FCM token שלהם ב-`users/{userId}/fcmToken`
2. **Permissions**: ה-Functions דורשות Firebase Admin SDK (אוטומטי)
3. **Error Handling**: כל ה-Functions כוללות error handling מלא

## 🔧 Configuration

ה-Functions משתמשות ב-Firebase Admin SDK שמתחבר אוטומטית ל-Firebase Project.

## 📊 Logs

```bash
# צפה ב-logs
firebase functions:log

# צפה ב-logs של function ספציפי
firebase functions:log --only onGameCreated
```

