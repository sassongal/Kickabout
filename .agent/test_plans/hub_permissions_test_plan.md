# Hub Permissions Testing Plan

## Overview
This document outlines manual test cases to verify the Hub permission system is working correctly across all roles and features.

## Test Environment Setup
1. Have at least 3 test user accounts ready
2. Create a test Hub
3. Assign different roles to test users:
   - User A: Manager (Hub creator)
   - User B: Moderator
   - User C: Veteran
   - User D: Member
   - User E: Guest/Non-member

## Test Cases

### 1. Game Management

#### 1.1 Game Creation
- [ ] **Guest**: Should NOT see "Create Game" button in Speed Dial
- [ ] **Member**: Should see "Create Game" button in Speed Dial
- [ ] **Veteran**: Should see "Create Game" button in Speed Dial
- [ ] **Moderator**: Should see "Create Game" button in Speed Dial
- [ ] **Manager**: Should see "Create Game" button in Speed Dial

**Server-Side Verification:**
- [ ] Guest attempting to create game via API should be denied
- [ ] Member should successfully create game

#### 1.2 Game Editing/Deletion
- [ ] **Game Creator**: Can edit and delete their own game
- [ ] **Moderator**: Can edit and delete ANY game in the hub
- [ ] **Manager**: Can edit and delete ANY game in the hub
- [ ] **Non-Creator Member**: Cannot edit/delete others' games

**Server-Side Verification:**
- [ ] Member attempting to delete another member's game should be denied
- [ ] Moderator should successfully delete any game

### 2. Hub Settings Management

#### 2.1 Settings Access
- [ ] **Manager**: Can see and click Settings button (not grayed out)
- [ ] **Moderator**: Cannot access Settings (button should not appear or be disabled)
- [ ] **Member/Veteran**: Cannot access Settings
- [ ] **Guest**: Cannot access Settings

**Server-Side Verification:**
- [ ] Moderator attempting to update hub settings via API should be denied
- [ ] Manager should successfully update hub settings

#### 2.2 Settings Button Visibility
- [ ] **Manager**: Settings button visible and enabled in Command Center
- [ ] **Moderator**: Settings button not visible in Command Center
- [ ] Other roles should not see Command Center at all

### 3. Member Management

#### 3.1 Add Manual Player
- [ ] **Manager**: Can see "Add Manual Player" button in Members tab
- [ ] **Moderator**: Can see "Add Manual Player" button in Members tab
- [ ] **Member/Veteran**: Cannot see "Add Manual Player" button
- [ ] **Guest**: Cannot see Members tab

#### 3.2 Join Requests
- [ ] **Manager**: Can see "Requests" inbox button with count badge
- [ ] **Moderator**: Can see "Requests" inbox button with count badge
- [ ] **Member/Veteran**: Cannot see "Requests" button
- [ ] **Guest**: Can submit a join request

**Server-Side Verification:**
- [ ] Member attempting to approve join request should be denied
- [ ] Manager should successfully approve/reject requests

#### 3.3 Invite Players (Scouting)
- [ ] **Manager**: Can see "Scout Players" button in Speed Dial
- [ ] **Moderator**: Can see "Scout Players" button in Speed Dial
- [ ] **Veteran**: Can see "Scout Players" button in Speed Dial
- [ ] **Member**: Cannot see "Scout Players" button
- [ ] **Guest**: Cannot see Speed Dial

### 4. Content Moderation

#### 4.1 Post Creation
- [ ] **Member**: Can create posts
- [ ] **Veteran**: Can create posts
- [ ] **Moderator**: Can create posts
- [ ] **Manager**: Can create posts
- [ ] **Guest**: Cannot create posts

#### 4.2 Post/Comment Deletion
- [ ] **Post Creator**: Can delete their own post
- [ ] **Comment Creator**: Can delete their own comment
- [ ] **Moderator**: Can delete ANY post or comment
- [ ] **Manager**: Can delete ANY post or comment
- [ ] **Regular Member**: Cannot delete others' posts/comments

**Server-Side Verification:**
- [ ] Member attempting to delete another member's post should be denied
- [ ] Moderator should successfully delete any post
- [ ] Manager should successfully delete any comment

### 5. Role Management

#### 5.1 Assign/Remove Roles
- [ ] **Manager**: Can assign/remove roles (moderator, veteran, member)
- [ ] **Moderator**: Cannot access role management
- [ ] Other roles cannot access role management

**Note**: Role management UI may not be fully implemented yet. This is for future testing.

### 6. UI Consistency

#### 6.1 Command Center Visibility
- [ ] **Manager**: Sees Command Center with all buttons
- [ ] **Moderator**: Sees Command Center with limited buttons (no Settings)
- [ ] **Member/Veteran/Guest**: Does not see Command Center

#### 6.2 Speed Dial Actions
- [ ] Speed Dial only shows actions the user is permitted to perform
- [ ] Speed Dial is hidden entirely if user cannot perform any action

#### 6.3 Guest View
- [ ] **Guest**: Sees limited Hub information
- [ ] **Guest**: Can submit join request
- [ ] **Guest**: Cannot see members list, games, or internal content
- [ ] **Guest**: Sees "Contact Manager" option if enabled in Hub settings

### 7. Edge Cases

#### 7.1 Role Change During Session
- [ ] If user's role changes (e.g., promoted from Member to Moderator), UI updates appropriately
- [ ] New permissions take effect immediately or after page refresh

#### 7.2 Non-Member Becomes Member
- [ ] Guest user who gets approved sees full Hub content
- [ ] UI transitions from Guest view to Member view

#### 7.3 Hub Deletion/Leave
- [ ] If hub is deleted, user cannot access it
- [ ] If user leaves hub, they see Guest view

## Server-Side Firestore Rules Testing

### Test via Firebase Console or API
1. **Create Game as Non-Member**: Should fail with `PERMISSION_DENIED`
2. **Update Hub Settings as Moderator**: Should fail with `PERMISSION_DENIED`
3. **Delete Other's Post as Member**: Should fail with `PERMISSION_DENIED`
4. **Approve Join Request as Member**: Should fail with `PERMISSION_DENIED`

## Automated Testing Recommendations

Consider implementing integration tests for:
1. `HubPermissions` class methods return correct values for each role
2. Server-side Firestore rules (using Firebase Emulator)
3. UI widget visibility based on permissions (using widget tests)

## Known Issues / Future Enhancements

- [ ] Role management screen UI not yet implemented
- [ ] Some join request handling may need additional rules
- [ ] Analytics access permissions may need review

## Sign-off

After completing all test cases:
- [ ] All critical permissions working as expected
- [ ] Server-side rules enforcing permissions correctly
- [ ] UI consistently reflects user permissions
- [ ] No unauthorized access possible

**Tested by:** _________________  
**Date:** _________________  
**Notes:** _________________
