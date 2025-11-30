# 🧪 Kattrick - Testing & Deployment Guide
## Complete Testing Strategy & Deployment Procedures

> **Last Updated:** January 2025  
> **Version:** 2.0

## Overview

Complete guide for testing and deploying Kattrick.

## Testing Strategy

### 1. Unit Tests
- Model tests (age calculation, etc.)
- Service tests (repository, auth)
- Util tests (helpers)

**Target Coverage:** 70%

### 2. Widget Tests
- Screen tests
- Component tests
- Navigation tests

**Target Coverage:** 60%

### 3. Integration Tests
- User flows (onboarding, create game)
- Firebase integration
- API integration

**Target Coverage:** 50%

### 4. Manual Testing
- Usability testing
- Cross-platform testing
- Performance testing

## Firebase Emulators Setup

```bash
# Install
firebase init emulators

# Select: Auth, Firestore, Functions, Storage

# Start
firebase emulators:start
```

## Deployment

### Backend (Firebase)

```bash
# Deploy all
firebase deploy

# Deploy Functions only
firebase deploy --only functions

# Deploy Rules only
firebase deploy --only firestore:rules

# Deploy Indexes
firebase deploy --only firestore:indexes
```

### Frontend (Flutter)

```bash
# Web
flutter build web
firebase deploy --only hosting

# iOS
flutter build ios --release
# Upload to App Store Connect

# Android
flutter build appbundle --release
# Upload to Play Console
```

## CI/CD Pipeline

**GitHub Actions:**
- Lint & analyze on PR
- Run tests on PR
- Auto-deploy on merge to main

## Monitoring

- Firebase Performance Monitoring
- Firebase Crashlytics
- Firebase Analytics
- Cost alerts (₪50/₪100/₪200)

## Related Documents
- **12_KNOWN_ISSUES.md**
- **14_SCALABILITY_COST.md**
