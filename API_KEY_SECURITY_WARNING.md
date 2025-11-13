# ⚠️ אזהרת אבטחה - API Key

## 🚨 חשוב מאוד!

**ה-API key `AIzaSyDhe0LjsJYUlntwSE7ich3Id4lCOJNilcE` כבר נדחף ל-GitHub בפעם אחת!**

## ✅ מה כבר נעשה

1. ✅ **ה-API key הוגדר ב-Firebase Functions Config** - נשמר בצד השרת בלבד
2. ✅ **הוסר מה-DEPLOYMENT_CHECKLIST.md** - לא מופיע יותר בתיעוד
3. ✅ **נוסף ל-.gitignore** - קבצים עם API keys לא יידחפו בעתיד
4. ✅ **נוצר SECURITY_NOTES.md** - מדריך אבטחה

## 🔒 מה לעשות עכשיו

### אופציה 1: Revoke ו-Create חדש (מומלץ)

1. לך ל-[Google Cloud Console](https://console.cloud.google.com/)
2. בחר פרויקט: `kickabout-ddc06`
3. לך ל: **APIs & Services** → **Credentials**
4. מצא את ה-API key: `AIzaSyDhe0LjsJYUlntwSE7ich3Id4lCOJNilcE`
5. לחץ עליו → **Restrict key** או **Delete**
6. צור API key חדש
7. הגדר אותו ב-Firebase Functions:
   ```bash
   firebase functions:config:set googleplaces.apikey="NEW_API_KEY"
   ```

### אופציה 2: Restrict את ה-API key

1. לך ל-[Google Cloud Console](https://console.cloud.google.com/)
2. בחר את ה-API key
3. **Restrict key**:
   - **API restrictions**: רק "Places API"
   - **Application restrictions**: 
     - HTTP referrers: רק הדומיינים שלך
     - או IP addresses: רק ה-IPs של השרתים שלך

## 📊 בדיקת שימוש

1. לך ל-[Google Cloud Console](https://console.cloud.google.com/)
2. **APIs & Services** → **Dashboard**
3. בדוק את השימוש ב-Places API
4. אם יש שימוש חשוד - Revoke מיד!

## 🛡️ הגנה עתידית

### 1. Google Cloud Secret Manager (מומלץ)

```bash
# צור secret
echo -n "YOUR_API_KEY" | gcloud secrets create google-places-api-key \
  --data-file=- \
  --project=kickabout-ddc06

# גש ל-secret ב-Cloud Functions
# (דורש שינוי קוד ל-Cloud Functions v2)
```

### 2. API Key Restrictions

- ✅ Restrict ל-Places API בלבד
- ✅ Restrict ל-IP addresses של Cloud Functions
- ✅ הגדר Quotas (מגבלות שימוש)

### 3. Monitoring

- ✅ בדוק שימוש יומי ב-Google Cloud Console
- ✅ הגדר Alerts לשימוש חריג
- ✅ בדוק Logs של Cloud Functions

## 📝 Checklist

- [ ] Revoke או Restrict את ה-API key הישן
- [ ] צור API key חדש (אם Revoke)
- [ ] הגדר אותו ב-Firebase Functions Config
- [ ] Restrict את ה-API key החדש
- [ ] בדוק שימוש יומי
- [ ] הגדר Alerts

---

**תאריך**: $(date)

**⚠️ זכור**: API keys שנדחפו ל-GitHub נשארים ב-Git history לנצח! 
הדרך היחידה להסיר אותם לחלוטין היא:
1. Revoke את ה-key
2. צור key חדש
3. (אופציונלי) נקה Git history (דורש force push)

