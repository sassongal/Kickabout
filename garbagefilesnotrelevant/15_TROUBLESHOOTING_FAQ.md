# 🆘 Kattrick - Troubleshooting & FAQ
## Common Problems, Solutions & Frequently Asked Questions

> **Last Updated:** January 2025  
> **Version:** 2.0

## Common Problems

### Problem 1: Build_runner fails

**Error:** `Missing part 'user.g.dart'`

**Solution:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Problem 2: Firebase permission denied

**Error:** `permission-denied` in Firestore

**Solution:**
- Check Firestore Security Rules
- Verify user is authenticated
- Check user role/permissions

### Problem 3: Images not loading

**Error:** Images show placeholder

**Solution:**
- Check Storage Rules
- Verify image URL
- Check network connection

### Problem 4: Notifications not working

**Error:** FCM tokens not received

**Solution:**
- Check FCM setup
- Verify token registration
- Check platform-specific config

### Problem 5: App crashes on startup

**Error:** `MissingPluginException`

**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

## Frequently Asked Questions

### Q: How do I add a new Cloud Function?

**A:**
1. Add function to `functions/index.js`
2. Test locally with emulators
3. Deploy: `firebase deploy --only functions`

### Q: How do I add a new Firestore collection?

**A:**
1. Define model with Freezed
2. Add to data model documentation
3. Create Security Rules
4. Create Indexes if needed
5. Update repository

### Q: How do I test locally?

**A:**
1. Start Firebase Emulators
2. Run app with emulator config
3. Use test data

### Q: How do I add a new screen?

**A:**
1. Create screen in `lib/features/{feature}/presentation/screens/`
2. Add route to GoRouter
3. Create providers if needed
4. Write widget tests

### Q: How do I optimize costs?

**A:** See **14_SCALABILITY_COST.md**

## Related Documents
- **12_KNOWN_ISSUES.md**
- **01_CURSOR_COMPLETE_GUIDE.md**
- **13_TESTING_DEPLOYMENT.md**
