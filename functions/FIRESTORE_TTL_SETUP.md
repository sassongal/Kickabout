# Firestore TTL Index Setup

## Overview
To automatically clean up processed events after 7 days, you need to set up a TTL (Time To Live) policy in Firestore.

## Steps to Configure TTL

### Option 1: Using Firebase Console (Recommended)
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Firestore Database** → **Indexes**
4. Click **Single Field** tab
5. Click **Add Exemption**
6. Configure:
   - Collection: `processed_events`
   - Field: `expiresAt`
   - Enable **TTL**
7. Save

### Option 2: Using gcloud CLI
```bash
gcloud firestore fields ttls update expiresAt \
  --collection-group=processed_events \
  --enable-ttl
```

## Verification
After setting up the TTL policy:
- Documents in `processed_events` will be automatically deleted when `expiresAt` timestamp is reached
- This happens approximately 24-72 hours after the expiration time
- No manual cleanup needed

## Notes
- TTL policies may take up to 24 hours to activate after creation
- Deletion typically occurs within 24-72 hours after expiration
- This is a cost-effective way to manage event deduplication without manual cleanup
