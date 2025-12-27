# Phase 4 Migration Guide: User Model Value Objects

## Overview

This guide covers the complete migration process for Phase 4, which decomposes the User model into value objects while maintaining 100% backward compatibility.

## Table of Contents

1. [Migration Strategy](#migration-strategy)
2. [Current State](#current-state)
3. [Pre-Migration Checklist](#pre-migration-checklist)
4. [Phase 4.6.1: Dual-Write Pattern (COMPLETE)](#phase-461-dual-write-pattern)
5. [Phase 4.6.2: Background Migration](#phase-462-background-migration)
6. [Phase 4.6.3: Verification](#phase-463-verification)
7. [Phase 4.6.4: Cleanup (Future)](#phase-464-cleanup)
8. [Rollback Procedure](#rollback-procedure)
9. [FAQ](#faq)

---

## Migration Strategy

The migration uses a **staged rollout with dual-write pattern** to ensure zero downtime and zero data loss:

| Phase | Description | Status | Risk |
|-------|-------------|--------|------|
| 4.6.1 | Support both formats (dual-write) | ✅ COMPLETE | LOW |
| 4.6.2 | Background migration via Cloud Function | 📋 READY | LOW |
| 4.6.3 | Verify 100% migration success | 📋 READY | LOW |
| 4.6.4 | Remove old fields (after 2-3 months) | ⏳ FUTURE | MEDIUM |

---

## Current State

### ✅ Completed (Phase 4.6.1)

1. **Value Objects Created:**
   - `PrivacySettings` - Encapsulates privacy preferences
   - `NotificationPreferences` - Encapsulates notification settings
   - `UserLocation` - Encapsulates location data

2. **User Model Updated:**
   - Added new value object fields (`privacy`, `notifications`, `userLocation`)
   - Kept old map fields (`privacySettings`, `notificationPreferences`, `location/geohash/city/region`)
   - Added `UserValueObjects` extension for backward compatibility

3. **Dual-Write Pattern Implemented:**
   - `UsersRepository.setUser()` writes to BOTH old and new formats
   - `_prepareDualWriteUserData()` helper ensures consistency
   - All user updates automatically include both formats

4. **Backward Compatibility:**
   - Existing code using old maps continues to work
   - New code can use `user.effectivePrivacy`, `user.effectiveNotifications`, `user.effectiveLocation`
   - Zero breaking changes

### 📁 Migration Scripts Ready

- `migrate_user_value_objects.js` - Migrates all users to new format
- `verify_user_migration.js` - Verifies 100% migration success
- `rollback_user_migration.js` - Emergency rollback if needed

---

## Pre-Migration Checklist

Before running the migration scripts, ensure:

- [ ] All tests pass
- [ ] App deployed to production with dual-write pattern
- [ ] Database backup created
- [ ] Migration scripts tested on staging environment
- [ ] Team notified of migration schedule
- [ ] Monitoring and alerting configured
- [ ] Rollback procedure reviewed

---

## Phase 4.6.2: Background Migration

### Objective

Migrate all existing user documents to include new value object fields.

### Steps

#### 1. Test on Staging (REQUIRED)

```bash
# Navigate to functions directory
cd functions

# Install dependencies if needed
npm install

# Dry run on staging
node scripts/migrate_user_value_objects.js --dry-run

# Review dry run output

# Execute migration on staging
node scripts/migrate_user_value_objects.js

# Verify staging migration
node scripts/verify_user_migration.js
```

#### 2. Create Production Backup

```bash
# Export all user data
gcloud firestore export gs://your-project-backup/phase4-pre-migration-$(date +%Y%m%d)

# Verify backup exists
gsutil ls gs://your-project-backup/
```

#### 3. Run Production Migration

**Recommended: Off-peak hours**

```bash
# Dry run first (always!)
node scripts/migrate_user_value_objects.js --dry-run

# Review output carefully

# Execute migration
node scripts/migrate_user_value_objects.js

# Monitor progress
# Expected: ~500-1000 users/minute
# For 10,000 users: ~10-20 minutes
```

#### 4. Monitor Application

During migration:
- Monitor error logs
- Check application performance
- Verify user logins work
- Test profile updates

---

## Phase 4.6.3: Verification

### Objective

Verify 100% of users have been successfully migrated with correct data.

### Steps

#### 1. Run Verification Script

```bash
cd functions

# Basic verification
node scripts/verify_user_migration.js

# Verbose mode (shows each user)
node scripts/verify_user_migration.js --verbose

# Auto-fix errors if found
node scripts/verify_user_migration.js --fix-errors
```

#### 2. Interpret Results

**Success Criteria:**
- ✅ `Fully migrated: 100%`
- ✅ `Not migrated: 0`
- ✅ `Data integrity errors: 0`

**If Errors Found:**
1. Review error details
2. Run with `--fix-errors` to auto-fix
3. Re-run verification
4. If errors persist, investigate manually

#### 3. Spot Check Users

Manually verify a few users in Firestore console:

```javascript
// User document should have BOTH formats:

// OLD format (backward compatibility)
{
  "privacySettings": {
    "hideFromSearch": false,
    "hideEmail": true,
    // ...
  },
  "notificationPreferences": {
    "game_reminder": true,
    "message": true,
    // ...
  },
  "location": GeoPoint(32.0, 34.0),
  "geohash": "sv8wrw",
  "city": "Tel Aviv",
  "region": "Center"
}

// NEW format (value objects)
{
  "privacy": {
    "hideFromSearch": false,
    "hideEmail": true,
    // ...
  },
  "notifications": {
    "gameReminder": true,
    "message": true,
    // ...
  },
  "userLocation": {
    "location": GeoPoint(32.0, 34.0),
    "geohash": "sv8wrw",
    "city": "Tel Aviv",
    "region": "Center"
  },
  "_migrationMetadata": {
    "migratedAt": Timestamp,
    "migrationVersion": "phase4.6.2"
  }
}
```

#### 4. Sign-Off

Once verification passes:
- [ ] All users migrated
- [ ] Data integrity verified
- [ ] Application functioning normally
- [ ] No user complaints
- [ ] Wait 1-2 weeks before Phase 4.6.4

---

## Phase 4.6.4: Cleanup (Future)

⚠️ **DO NOT EXECUTE THIS PHASE IMMEDIATELY**

Wait at least **2-3 months** after Phase 4.6.3 completes successfully.

### Objective

Remove old map fields from User model and Firestore documents.

### Prerequisites

- [ ] Phase 4.6.3 completed successfully
- [ ] Monitoring shows no errors for 2-3 months
- [ ] All code migrated to use `effectivePrivacy`, `effectiveNotifications`, `effectiveLocation`
- [ ] Team approval obtained

### Steps

#### 1. Update User Model

Remove deprecated fields:
```dart
// REMOVE these fields from User model:
// - Map<String, bool> privacySettings  (use privacy instead)
// - Map<String, bool> notificationPreferences  (use notifications instead)
// - GeoPoint? location  (use userLocation instead)
// - String? geohash  (use userLocation instead)
// - String? city  (use userLocation instead)
// - String? region  (use userLocation instead)
```

#### 2. Update UsersRepository

Remove dual-write pattern:
```dart
// REMOVE _prepareDualWriteUserData() method
// UPDATE setUser() to use user.toJson() directly
```

#### 3. Create Cleanup Script

```javascript
// Remove old fields from all users
// Keep as reference only - execute with caution
```

#### 4. Gradual Rollout

1. Deploy code changes to staging
2. Test thoroughly
3. Deploy to production
4. Monitor for 1 week
5. If stable, run cleanup script on Firestore

---

## Rollback Procedure

### When to Rollback

Only if:
- Migration caused critical production issues
- Data integrity errors cannot be fixed
- Team decides migration should be reverted

### Steps

#### 1. Immediate Actions

```bash
# Stop migration if running
# Press Ctrl+C in migration terminal

# Deploy previous app version (without dual-write)
# This ensures no new value objects are written
```

#### 2. Run Rollback Script

```bash
cd functions

# Dry run first
node scripts/rollback_user_migration.js --dry-run

# Review output

# Execute rollback (requires confirmation)
node scripts/rollback_user_migration.js --confirm
```

#### 3. Verify Rollback

```bash
# Check that value object fields are removed
# Spot check users in Firestore console

# Verify application works with old map fields
```

#### 4. Post-Rollback

- Remove value object code from User model
- Remove dual-write logic from UsersRepository
- Investigate root cause
- Fix issues before attempting migration again

---

## FAQ

### Q: What happens if migration script fails mid-way?

**A:** The script is idempotent and can be re-run safely. It will:
- Skip users already migrated
- Continue from where it left off
- Not corrupt any existing data

### Q: Can users still update their profiles during migration?

**A:** Yes! The dual-write pattern ensures:
- User updates work normally
- New data is written in both formats
- No user-facing issues

### Q: What if I find a bug after migration?

**A:** You have options:
1. **Minor bug:** Fix in new code, leave migration in place
2. **Critical bug:** Use rollback script to revert
3. **Data issue:** Use verification script with `--fix-errors`

### Q: How long should I wait before Phase 4.6.4?

**A:** Recommended: **2-3 months**
- Allows thorough testing in production
- Ensures no edge cases missed
- Provides confidence for final cleanup

### Q: Can I migrate specific users only?

**A:** Yes, modify the migration script to filter by criteria:
```javascript
// Example: Only migrate users created after a date
const query = db.collection('users')
  .where('createdAt', '>', new Date('2024-01-01'))
  .limit(BATCH_SIZE);
```

### Q: What if a user has no location data?

**A:** The migration handles this gracefully:
- `userLocation` will be `null`
- No error thrown
- User can add location later

### Q: Do I need to update Firebase Security Rules?

**A:** Not immediately. Current rules work with both formats.
After Phase 4.6.4, you can simplify rules to reference only value objects.

---

## Support

If you encounter issues:

1. Check migration script logs for errors
2. Run verification script with `--verbose`
3. Review this guide's troubleshooting section
4. Contact team lead before attempting rollback

---

## Summary

✅ **Phase 4.6.1 (COMPLETE)**: Dual-write pattern ensures backward compatibility
📋 **Phase 4.6.2 (READY)**: Background migration script prepared
📋 **Phase 4.6.3 (READY)**: Verification script prepared
⏳ **Phase 4.6.4 (FUTURE)**: Cleanup after 2-3 months of stable operation

**Zero downtime. Zero data loss. Zero breaking changes.**
