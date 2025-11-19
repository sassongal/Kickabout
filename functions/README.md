# Firebase Cloud Functions - Kickadoor

## 📋 Overview

Cloud Functions for secure API integration, caching, and server-side logic.

## 🔧 Setup

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Configure API Keys

**Important:** Cloud Functions use Firebase Secrets (v2) for secure API key storage.

```bash
# Google Maps/Places API Key (used for searchVenues, getPlaceDetails, getHomeDashboardData)
# Set as Firebase Secret (recommended for production)
echo "AIzaSyAtGhXyexqP8bYiH2nqaTxeECtvENWqPPU" | firebase functions:secrets:set GOOGLE_APIS_KEY

# Custom API (optional)
firebase functions:config:set customapi.baseurl="https://your-api.com"
firebase functions:config:set customapi.apikey="YOUR_API_KEY"
```

**Note:** The Google Maps API key is also configured in:
- `lib/config/env.dart` (for client-side use)
- `android/app/src/main/AndroidManifest.xml` (for Android)
- `ios/Runner/AppDelegate.swift` (for iOS)
- `web/index.html` (for Web)

**Security:** Make sure the API key has proper restrictions in Google Cloud Console:
- Application restrictions: Android package name, iOS bundle ID, Web domain
- API restrictions: Maps SDK for Android, Maps SDK for iOS, Maps JavaScript API, Places API

### 3. Deploy

```bash
firebase deploy --only functions
```

## 📦 Functions

### 1. `searchVenues`
Secure venue search using Google Places API.

**Parameters:**
- `latitude` (number) - User latitude
- `longitude` (number) - User longitude
- `radius` (number, optional) - Search radius in meters (default: 5000)
- `query` (string, optional) - Search query
- `includeRentals` (boolean, optional) - Include rental venues

**Returns:**
```json
{
  "results": [...],
  "count": 10
}
```

**Features:**
- ✅ Server-side API key (secure)
- ✅ Caching (5 minutes)
- ✅ Rate limiting (2 seconds per user)
- ✅ Retry logic with exponential backoff

### 2. `getPlaceDetails`
Get detailed information about a place.

**Parameters:**
- `placeId` (string) - Google Places place ID

**Returns:**
```json
{
  "place": {...}
}
```

**Features:**
- ✅ Long-term caching (1 hour)
- ✅ Detailed place information

### 3. `syncVenueToCustomAPI`
Sync venue data to custom API.

**Parameters:**
- `venueId` (string) - Venue ID to sync

**Returns:**
```json
{
  "success": true,
  "data": {...}
}
```

### 4. `onVenueChanged`
Automatic trigger when venue is created/updated.

**Features:**
- ✅ Automatic sync to custom API
- ✅ Firestore trigger

### 5. Existing Functions
- `onGameCreated` - Notify hub members of new game
- `onHubMessageCreated` - Notify hub members of new message
- `onCommentCreated` - Notify post author of new comment
- `onFollowCreated` - Notify user of new follower
- `sendGameReminder` - Send game reminder notifications

## 🔒 Security

- API keys stored in Functions config (not in code)
- Authentication required for all callable functions
- Rate limiting per user
- Input validation

## 📊 Performance

- **Caching**: Reduces API calls and costs
- **Rate Limiting**: Prevents abuse
- **Retry Logic**: Handles transient errors
- **Batch Processing**: Efficient Firestore queries

## 🧪 Testing

### Local Testing

```bash
# Start emulators
firebase emulators:start

# Test function
curl -X POST http://localhost:5001/your-project/us-central1/searchVenues \
  -H "Content-Type: application/json" \
  -d '{"data": {"latitude": 31.7683, "longitude": 35.2137, "radius": 5000}}'
```

## 📈 Monitoring

```bash
# View logs
firebase functions:log

# View specific function logs
firebase functions:log --only searchVenues
```

## 💰 Cost Optimization

1. **Caching** - Reduces Google Places API calls
2. **Rate Limiting** - Prevents excessive usage
3. **Batch Queries** - Efficient Firestore reads
4. **Error Handling** - Prevents unnecessary retries

## 🔄 Updates

When updating functions:

```bash
# Deploy specific function
firebase deploy --only functions:searchVenues

# Deploy all functions
firebase deploy --only functions
```

## 📚 Dependencies

- `firebase-admin` - Admin SDK
- `firebase-functions` - Functions runtime
- `axios` - HTTP client
- `axios-retry` - Retry logic
- `node-cache` - Caching
