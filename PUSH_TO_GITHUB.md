# 🚀 הוראות העלאה ל-GitHub - kick2

## שלב 1: יצירת Repository ב-GitHub

1. לך ל: **https://github.com/new**
2. **Repository name**: `kick2`
3. **Description** (אופציונלי): "Israeli Pickup Soccer App - Flutter MVP"
4. בחר **Private** או **Public** (לפי העדפתך)
5. **אל תוסיף**:
   - ❌ README
   - ❌ .gitignore
   - ❌ License
   
   (כבר יש לנו את כל זה!)
6. לחץ על **"Create repository"**

## שלב 2: העלאה ל-GitHub

לאחר יצירת ה-repository, הרץ:

```bash
git push -u origin main
```

## אם יש שגיאה

אם יש שגיאת authentication, נסה:

```bash
# עם SSH (אם יש לך SSH key מוגדר)
git remote set-url origin git@github.com:sassongal/kick2.git
git push -u origin main

# או עם HTTPS (יתבקש username/password או token)
git remote set-url origin https://github.com/sassongal/kick2.git
git push -u origin main
```

## בדיקת מצב

```bash
# בדוק את ה-remote
git remote -v

# בדוק את ה-status
git status

# בדוק את ה-commits
git log --oneline -5
```

## ✅ לאחר העלאה מוצלחת

ה-repository יהיה זמין ב:
**https://github.com/sassongal/kick2**

