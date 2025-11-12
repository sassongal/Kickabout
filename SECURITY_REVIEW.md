# 🔒 Security Review - Kickabout

## Firestore Security Rules

### Current Status
הכללים הנוכחיים נמצאים במסמכים (`DEPLOYMENT.md`, `ANALYSIS_AND_ROADMAP.md`) אבל לא מוגדרים בפועל בפרויקט.

### Recommended Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isHubMember(hubId) {
      return isAuthenticated() && 
        request.auth.uid in resource.data.memberIds;
    }
    
    function isHubManager(hubId) {
      return isAuthenticated() && (
        resource.data.createdBy == request.auth.uid ||
        resource.data.roles[request.auth.uid] == 'manager'
      );
    }
    
    function isHubModerator(hubId) {
      return isAuthenticated() && (
        resource.data.createdBy == request.auth.uid ||
        resource.data.roles[request.auth.uid] == 'manager' ||
        resource.data.roles[request.auth.uid] == 'moderator'
      );
    }

    // Users
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && isOwner(userId);
      allow update: if isAuthenticated() && isOwner(userId);
      allow delete: if isAuthenticated() && isOwner(userId);
      
      // FCM Tokens
      match /fcm_tokens/{tokenId} {
        allow read, write: if isOwner(userId);
      }
      
      // Following/Followers
      match /following/{followingId} {
        allow read: if isAuthenticated();
        allow write: if isOwner(userId);
      }
      
      match /followers/{followerId} {
        allow read: if isAuthenticated();
        allow write: if isOwner(userId);
      }
      
      // Gamification
      match /gamification/{doc} {
        allow read: if isAuthenticated();
        allow write: if false; // Only server-side updates
      }
    }

    // Hubs
    match /hubs/{hubId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (
        isHubManager(hubId) ||
        (request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['memberIds', 'roles']) && isHubModerator(hubId))
      );
      allow delete: if isAuthenticated() && isHubManager(hubId);
      
      // Feed
      match /feed/posts/items/{postId} {
        allow read: if isAuthenticated() && isHubMember(hubId);
        allow create: if isAuthenticated() && isHubMember(hubId);
        allow update, delete: if isAuthenticated() && (
          resource.data.authorId == request.auth.uid ||
          isHubModerator(hubId)
        );
        
        // Comments
        match /comments/{commentId} {
          allow read: if isAuthenticated() && isHubMember(hubId);
          allow create: if isAuthenticated() && isHubMember(hubId);
          allow update, delete: if isAuthenticated() && (
            resource.data.authorId == request.auth.uid ||
            isHubModerator(hubId)
          );
        }
      }
      
      // Chat
      match /chat/messages/{messageId} {
        allow read: if isAuthenticated() && isHubMember(hubId);
        allow create: if isAuthenticated() && isHubMember(hubId);
        allow update, delete: if isAuthenticated() && (
          resource.data.authorId == request.auth.uid ||
          isHubModerator(hubId)
        );
      }
    }

    // Games
    match /games/{gameId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (
        resource.data.createdBy == request.auth.uid ||
        isHubManager(resource.data.hubId)
      );
      allow delete: if isAuthenticated() && (
        resource.data.createdBy == request.auth.uid ||
        isHubManager(resource.data.hubId)
      );
      
      // Signups
      match /signups/{userId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated() && isOwner(userId);
        allow update: if isAuthenticated() && (
          isOwner(userId) ||
          isHubManager(resource.data.hubId)
        );
        allow delete: if isAuthenticated() && (
          isOwner(userId) ||
          isHubManager(resource.data.hubId)
        );
      }
      
      // Teams
      match /teams/{teamId} {
        allow read: if isAuthenticated();
        allow write: if isAuthenticated() && (
          get(/databases/$(database)/documents/games/$(gameId)).data.createdBy == request.auth.uid ||
          isHubManager(get(/databases/$(database)/documents/games/$(gameId)).data.hubId)
        );
      }
      
      // Events
      match /events/{eventId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated();
        allow update, delete: if isAuthenticated() && (
          resource.data.playerId == request.auth.uid ||
          isHubManager(get(/databases/$(database)/documents/games/$(gameId)).data.hubId)
        );
      }
    }

    // Ratings
    match /ratings/{userId}/history/{ratingId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if false; // Ratings are immutable
    }

    // Notifications
    match /notifications/{notificationId} {
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow create: if false; // Only server-side
      allow update: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
    }

    // Private Messages
    match /private_messages/{conversationId} {
      allow read: if isAuthenticated() && 
        request.auth.uid in resource.data.participantIds;
      allow create: if isAuthenticated() && 
        request.auth.uid in request.resource.data.participantIds;
      allow update: if isAuthenticated() && 
        request.auth.uid in resource.data.participantIds;
      allow delete: if isAuthenticated() && 
        request.auth.uid in resource.data.participantIds;
      
      // Messages
      match /messages/{messageId} {
        allow read: if isAuthenticated() && 
          request.auth.uid in get(/databases/$(database)/documents/private_messages/$(conversationId)).data.participantIds;
        allow create: if isAuthenticated() && 
          request.resource.data.senderId == request.auth.uid &&
          request.auth.uid in get(/databases/$(database)/documents/private_messages/$(conversationId)).data.participantIds;
        allow update, delete: if false; // Messages are immutable
      }
    }
  }
}
```

## Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile photos
    match /profile_photos/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Game photos
    match /game_photos/{gameId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Security Best Practices

### 1. Input Validation
- ✅ Validate all user inputs on client side
- ⚠️ Add server-side validation (Firebase Functions)
- ⚠️ Sanitize user-generated content

### 2. Rate Limiting
- ❌ Not implemented
- 💡 Consider implementing with Firebase Functions

### 3. Data Encryption
- ✅ Firebase Auth handles password encryption
- ⚠️ Consider encrypting sensitive data (phone numbers, etc.)

### 4. Privacy
- ✅ Users can only see their own data
- ✅ Hub members can only see hub data
- ✅ Proper access control with roles

### 5. Authentication
- ✅ Firebase Auth integration
- ✅ Anonymous auth support
- ✅ Email/Password auth

## Recommendations

1. **Deploy Security Rules** - העלה את הכללים ל-Firebase Console
2. **Test Rules** - בדוק את הכללים עם Firebase Emulator
3. **Monitor Access** - השתמש ב-Firebase Monitoring
4. **Regular Review** - בדוק את הכללים באופן קבוע
5. **Server-Side Validation** - הוסף Firebase Functions לבדיקות נוספות

## Known Issues

1. **Roles Check** - הפונקציה `isHubManager` ו-`isHubModerator` דורשות קריאה ל-`resource.data` אבל זה לא תמיד זמין ב-create
2. **Nested Queries** - חלק מהכללים דורשים קריאות נוספות ל-Firestore (עלות)
3. **Performance** - כללים מורכבים יכולים להאט את הביצועים

## Next Steps

1. ✅ Create security rules file
2. ⚠️ Deploy to Firebase
3. ⚠️ Test with Firebase Emulator
4. ⚠️ Monitor and adjust

