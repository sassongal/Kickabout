# Migration Scripts Setup & Usage

## Prerequisites

Before running any migration scripts, ensure you're authenticated with Firebase.

### Option 1: Firebase CLI (Recommended for local development)

```bash
# Login to Firebase
firebase login

# Set your project
firebase use kickabout-ddc06

# Verify project is set
firebase use
```

### Option 2: Service Account Key (Recommended for CI/CD)

1. Download service account key from Firebase Console
2. Save as `functions/service-account-key.json`
3. **IMPORTANT**: Never commit this file to git (already in .gitignore)

### Option 3: Environment Variable

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
```

---

## Available Scripts

### 1. migrate_user_value_objects.js

Migrates all user documents to include new value object fields.

**Dry Run (Preview):**
```bash
cd functions
node scripts/migrate_user_value_objects.js --dry-run
```

**Execute Migration:**
```bash
node scripts/migrate_user_value_objects.js
```

**Custom Batch Size:**
```bash
node scripts/migrate_user_value_objects.js --batch-size=1000
```

---

### 2. verify_user_migration.js

Verifies that all users have been migrated correctly.

**Basic Verification:**
```bash
cd functions
node scripts/verify_user_migration.js
```

**Verbose Mode:**
```bash
node scripts/verify_user_migration.js --verbose
```

**Auto-Fix Errors:**
```bash
node scripts/verify_user_migration.js --fix-errors
```

---

### 3. rollback_user_migration.js

Emergency rollback to remove value object fields.

**Dry Run (Preview):**
```bash
cd functions
node scripts/rollback_user_migration.js --dry-run
```

**Execute Rollback (requires confirmation):**
```bash
node scripts/rollback_user_migration.js --confirm
```

---

## Troubleshooting

### Error: "Unable to detect a Project Id"

**Solution**: Ensure you're authenticated (see Prerequisites above)

```bash
# Check if logged in
firebase projects:list

# If not logged in
firebase login

# Set project
firebase use kickabout-ddc06
```

### Error: "PERMISSION_DENIED"

**Solution**: Ensure your Firebase user has sufficient permissions

```bash
# Check your permissions in Firebase Console:
# Project Settings > Users and Permissions
```

### Error: "Module not found"

**Solution**: Install dependencies

```bash
cd functions
npm install
```

---

## Testing on Staging

**Before running on production**, always test on staging:

1. **Switch to staging project:**
   ```bash
   firebase use staging-project-id
   ```

2. **Run dry run:**
   ```bash
   node scripts/migrate_user_value_objects.js --dry-run
   ```

3. **Execute migration:**
   ```bash
   node scripts/migrate_user_value_objects.js
   ```

4. **Verify migration:**
   ```bash
   node scripts/verify_user_migration.js
   ```

5. **Test application:**
   - User login/logout
   - Profile updates
   - Privacy settings changes
   - Notification preferences

6. **Switch back to production:**
   ```bash
   firebase use kickabout-ddc06
   ```

---

## Production Checklist

Before running on production:

- [ ] Successfully tested on staging
- [ ] Database backup created
- [ ] Team notified
- [ ] Running during off-peak hours
- [ ] Monitoring dashboard open
- [ ] Rollback script tested on staging

---

## Quick Reference

| Script | Purpose | Dry Run | Confirmation |
|--------|---------|---------|--------------|
| migrate_user_value_objects.js | Migrate users | `--dry-run` | Not required |
| verify_user_migration.js | Check migration | N/A | Not required |
| rollback_user_migration.js | Emergency rollback | `--dry-run` | `--confirm` required |

---

## Support

If you encounter issues:

1. Check script logs for detailed error messages
2. Run with `--dry-run` first to preview changes
3. Review [PHASE4_MIGRATION_GUIDE.md](../../docs/PHASE4_MIGRATION_GUIDE.md)
4. Check Firebase Console for data integrity

---

## Notes

- All scripts are **idempotent** - safe to run multiple times
- Migration uses **batches of 500 users** by default
- Progress is logged to console in real-time
- No data is lost - dual-write pattern ensures backward compatibility
