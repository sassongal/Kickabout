# 🚀 Polls System - Deployment Instructions

## מה נדרש לפריסה

### 1. Backend (Firebase Functions) ✅
- `votePoll` - הצבעה בסקר
- `closePoll` - סגירת סקר ידנית
- `onPollCreated` - התראות על סקרים חדשים
- `scheduledPollAutoClose` - סגירה אוטומטית

### 2. Firestore Rules ✅
- Security rules לcollection `polls`
- Permissions בהתאם לroles

### 3. Firestore Indexes ✅
- Index על `hubId + status + createdAt`
- Index על `status + endsAt`

---

## 🔧 Steps לפריסה

### Step 1: Deploy Functions

```bash
cd /Users/galsasson/Projects/kickabout

# Deploy all poll functions
firebase deploy --only functions:votePoll,functions:closePoll,functions:onPollCreated,functions:scheduledPollAutoClose --project kickabout-ddc06
```

**Expected output:**
```
✔  functions[us-central1-votePoll]: Successful create operation.
✔  functions[us-central1-closePoll]: Successful create operation.
✔  functions[us-central1-onPollCreated]: Successful create operation.
✔  functions[us-central1-scheduledPollAutoClose]: Successful create operation.

✔  Deploy complete!
```

---

### Step 2: Deploy Firestore Rules

```bash
# Deploy updated rules
firebase deploy --only firestore:rules --project kickabout-ddc06
```

**Expected output:**
```
✔  firestore: released rules firestore.rules to cloud.firestore

✔  Deploy complete!
```

---

### Step 3: Create Firestore Indexes

```bash
# Deploy indexes
firebase deploy --only firestore:indexes --project kickabout-ddc06
```

**Expected output:**
```
✔  firestore: indexes deployed successfully

✔  Deploy complete!
```

**או בצורה ידנית:**
1. פתח [Firebase Console](https://console.firebase.google.com/project/kickabout-ddc06/firestore/indexes)
2. לחץ על "Create Index"
3. צור 2 indexes:

#### Index 1:
- Collection: `polls`
- Fields:
  - `hubId` (Ascending)
  - `status` (Ascending)
  - `createdAt` (Descending)
- Query scope: Collection

#### Index 2:
- Collection: `polls`
- Fields:
  - `status` (Ascending)
  - `endsAt` (Ascending)
- Query scope: Collection

---

### Step 4: Verify Deployment

#### 4.1 Check Functions

```bash
firebase functions:list --project kickabout-ddc06 | grep poll
```

**Expected output:**
```
votePoll(us-central1)
closePoll(us-central1)
onPollCreated(us-central1)
scheduledPollAutoClose(us-central1)
```

#### 4.2 Check Rules

1. פתח [Firestore Rules](https://console.firebase.google.com/project/kickabout-ddc06/firestore/rules)
2. וודא שיש rule ל-`polls/{pollId}`

#### 4.3 Check Indexes

1. פתח [Firestore Indexes](https://console.firebase.google.com/project/kickabout-ddc06/firestore/indexes)
2. וודא ש-2 indexes נוצרו (status יכול להיות "Building...")

---

## 🧪 Manual Testing Checklist

### Test 1: Create Poll (Manager)
1. פתח Hub כManager
2. לך ל-Polls Tab
3. לחץ "סקר חדש"
4. מלא שאלה ו-2+ אפשרויות
5. צור סקר
6. ✅ צריך להצליח ולהיות בTab

### Test 2: Vote on Poll (Member)
1. פתח Hub כMember רגיל
2. לך ל-Polls Tab
3. לחץ על סקר
4. בחר אפשרות
5. לחץ "הצבע"
6. ✅ צריך להצליח ולהציג תוצאות

### Test 3: View Results
1. אחרי הצבעה, התוצאות צריכות להיות:
   - גרף עם אחוזים
   - כוכב זהב לאפשרות המנצחת
   - וי ירוק לאפשרות שבחרת
   - ✅ Real-time updates

### Test 4: Close Poll (Manager)
1. כManager, פתח סקר
2. לחץ "⋮" → "סגור סקר"
3. אשר
4. ✅ הסקר צריך להיסגר ולהציג תוצאות סופיות

### Test 5: Notifications
1. צור סקר חדש כManager
2. חברים אחרים צריכים לקבל התראה
3. ✅ התראה: "סקר חדש: [שאלה]"

### Test 6: Auto-Close
1. צור סקר עם תאריך סיום בעבר (או המתן 10 דקות)
2. ✅ הסקר צריך להיסגר אוטומטית
3. ✅ התראה עם תוצאות צריכה להישלח

### Test 7: Rate Limiting
1. נסה להצביע 11 פעמים תוך דקה
2. ✅ ה-11 צריכה להיכשל עם: "יותר מדי הצבעות"

---

## ❌ Common Issues & Solutions

### Issue 1: "Function not found"
**Error:** `Failed to create function: NOT_FOUND`

**Solution:**
```bash
# Re-deploy the specific function
firebase deploy --only functions:votePoll --project kickabout-ddc06
```

### Issue 2: "Index required"
**Error:** `FAILED_PRECONDITION: The query requires an index`

**Solution:**
1. לחץ על הלינק בerror message
2. Firebase ייצור את ה-index אוטומטית
3. המתן 5-10 דקות

### Issue 3: "Permission denied"
**Error:** `Insufficient permissions`

**Solution:**
1. וודא שה-Rules נפרסו:
   ```bash
   firebase deploy --only firestore:rules
   ```
2. בדוק שהמשתמש חבר ב-Hub

### Issue 4: Functions timeout
**Error:** `Deadline exceeded`

**Solution:**
- וודא שה-indexes נוצרו
- בדוק שאין queries ללא limit
- העלה את ה-timeout:
  ```javascript
  exports.votePoll = onCall({ timeoutSeconds: 60, ... })
  ```

---

## 📊 Monitoring

### View Function Logs

```bash
# Real-time logs
firebase functions:log --project kickabout-ddc06

# Specific function
firebase functions:log --only votePoll --project kickabout-ddc06
```

### Firebase Console Monitoring

1. **Functions Dashboard:**
   https://console.firebase.google.com/project/kickabout-ddc06/functions

2. **Logs:**
   https://console.firebase.google.com/project/kickabout-ddc06/logs

3. **Firestore Usage:**
   https://console.firebase.google.com/project/kickabout-ddc06/firestore/usage

---

## 🎯 Success Criteria

✅ All 4 functions deployed  
✅ Firestore rules updated  
✅ 2 indexes created (or building)  
✅ Can create poll as Manager  
✅ Can vote as Member  
✅ Results update in real-time  
✅ Notifications sent  
✅ Auto-close works (check logs after 10 min)  
✅ Rate limiting works  

---

## 🚨 Rollback Plan

אם משהו לא עובד:

### Rollback Functions:
```bash
# List versions
firebase functions:log --project kickabout-ddc06

# Rollback specific function
firebase functions:delete votePoll --region us-central1 --project kickabout-ddc06
firebase deploy --only functions:votePoll --project kickabout-ddc06
```

### Rollback Rules:
1. Git checkout לגרסה קודמת
2. Deploy שוב:
   ```bash
   git checkout HEAD~1 firestore.rules
   firebase deploy --only firestore:rules
   ```

---

## 📝 Post-Deployment Checklist

- [ ] כל ה-Functions נפרסו בהצלחה
- [ ] Firestore Rules עודכנו
- [ ] Indexes נוצרו (או building)
- [ ] בדיקות ידניות עברו
- [ ] Notifications עובדות
- [ ] Logs נקיים (ללא errors)
- [ ] עדכון ב-DEPLOY_SUCCESS_SUMMARY.md
- [ ] עדכון ב-Agent steps

---

**Good luck with deployment!** 🚀

