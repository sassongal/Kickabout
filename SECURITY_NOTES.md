# 🔒 Security Notes - API Keys

## ⚠️ חשוב!

**API Keys רגישים** - לעולם אל תדחוף אותם ל-GitHub!

## ✅ מה כבר נעשה

1. **Google Places API Key** - הוגדר ב-Firebase Functions Config
   ```bash
   firebase functions:config:set googleplaces.apikey="YOUR_KEY"
   ```
   - ה-API key נשמר בצד השרת בלבד
   - לא מופיע בקוד
   - לא נדחף ל-GitHub

2. **Custom API Keys** - גם דרך Functions Config
   ```bash
   firebase functions:config:set customapi.baseurl="YOUR_URL"
   firebase functions:config:set customapi.apikey="YOUR_KEY"
   ```

## 🔐 Best Practices

### ✅ מה לעשות:
- ✅ שמור API keys ב-Firebase Functions Config
- ✅ השתמש ב-Environment Variables
- ✅ הוסף `.env` ל-`.gitignore`
- ✅ השתמש ב-Secret Manager (Google Cloud) ל-production

### ❌ מה לא לעשות:
- ❌ אל תדחוף API keys ל-Git
- ❌ אל תכתוב API keys בקוד
- ❌ אל תשתף API keys בקבצי config ב-GitHub
- ❌ אל תכלול API keys ב-commits

## 🔄 אם API Key נדחף בטעות ל-GitHub

1. **מיד** - Revoke את ה-API key ב-Google Cloud Console
2. **צור** API key חדש
3. **הגדר** אותו ב-Firebase Functions Config
4. **נקה** את ה-Git history (אם צריך)

## 📝 בדיקה

```bash
# בדוק אם יש API keys בקוד
grep -r "AIza" lib/ functions/ --exclude-dir=node_modules

# בדוק את ה-config (לא מציג את הערכים)
firebase functions:config:get
```

## 🛡️ הגנה נוספת

### Google Cloud Secret Manager (מומלץ ל-Production)

```bash
# צור secret
echo -n "YOUR_API_KEY" | gcloud secrets create google-places-api-key --data-file=-

# גש ל-secret ב-Cloud Functions
# (דורש שינוי קוד)
```

---

**תאריך**: $(date)

