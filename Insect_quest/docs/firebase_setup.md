# Firebase Setup for Economy Features

## Overview

The coin economy and trading features use Firebase Firestore for cloud storage and synchronization. However, the app is designed to work in offline mode if Firebase is not configured.

## Quick Start (Offline Mode)

If you don't configure Firebase, the app will:
- Store user ID locally via SharedPreferences
- Show error messages when trying to access Economy or Trading features
- Continue to track coins locally in captured cards
- Work normally for camera, map, and journal features

## Full Setup (Cloud Sync)

### Prerequisites

1. A Google account
2. A Firebase project
3. Android app registered in Firebase Console

### Step-by-Step Setup

#### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: "InsectQuest" (or your preference)
4. Disable Google Analytics (optional for MVP)
5. Click "Create project"

#### 2. Register Android App

1. In Firebase Console, click "Add app" → Android icon
2. Enter package name: `com.example.insect_quest` (must match `android/app/build.gradle`)
3. Download `google-services.json`
4. Place file in: `android/app/google-services.json`

#### 3. Enable Firestore

1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" for development
4. Select location closest to your users
5. Click "Enable"

#### 4. Configure Security Rules (Development)

In Firestore Console → Rules, use these rules for testing:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if true;  // For testing only!
    }
    
    // Anyone can read/write trades
    match /trades/{tradeId} {
      allow read, write: if true;  // For testing only!
    }
  }
}
```

**⚠️ WARNING**: These rules allow anyone to read/write data. For production, implement proper authentication.

#### 5. Update Android Configuration

Ensure `android/app/build.gradle` has:

```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    // ... other dependencies
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-firestore'
}
```

And `android/build.gradle` has:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

#### 6. Test Connection

1. Run the app: `flutter run`
2. Navigate to Economy tab
3. Your coin balance should load from Firestore
4. Capture an insect - coins should sync to cloud

## Production Setup (Recommended)

For production deployment:

### 1. Enable Authentication

Add Firebase Authentication:
```yaml
# pubspec.yaml
dependencies:
  firebase_auth: ^4.16.0
```

Update security rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /trades/{tradeId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.offeredByUserId == request.auth.uid;
      allow update: if request.auth != null && 
        (resource.data.offeredByUserId == request.auth.uid || 
         resource.data.status == 'listed');
    }
  }
}
```

### 2. Add Indexes

For efficient queries, add these indexes in Firestore Console:

**Collection: trades**
- Fields: `status` (Ascending), `createdAt` (Descending)
- Fields: `offeredByUserId` (Ascending), `createdAt` (Descending)

### 3. Enable Offline Persistence

Already enabled by default in Flutter Firestore plugin.

### 4. Monitor Usage

- Firestore Console → Usage tab
- Set up budget alerts
- Monitor read/write operations

## Troubleshooting

### "Firebase not configured" message

**Cause**: `google-services.json` missing or Firebase.initializeApp() failed

**Fix**: 
1. Verify `google-services.json` is in `android/app/`
2. Check package name matches Firebase Console
3. Run `flutter clean && flutter pub get`

### "Insufficient permissions" error

**Cause**: Firestore security rules too restrictive

**Fix**: Check rules in Firebase Console → Firestore → Rules

### Offline mode not working

**Cause**: Firestore offline persistence disabled

**Fix**: Should work by default, but verify:
```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
);
```

### Coins not syncing

**Cause**: Network error or Firestore rules

**Fix**:
1. Check internet connection
2. Check Firestore rules allow write
3. Check logs: `flutter logs | grep Firestore`

## Data Structure

### Users Collection

```
/users/{userId}
  - userId: string
  - coins: number
  - lastUpdated: timestamp
```

### Trades Collection

```
/trades/{tradeId}
  - id: string
  - offeredCaptureId: string
  - offeredByUserId: string
  - requestedCaptureId: string | null
  - coinsOffered: number
  - coinsRequested: number
  - status: enum (listed, pending, accepted, cancelled, completed)
  - createdAt: timestamp
  - acceptedByUserId: string | null
  - acceptedAt: timestamp | null
```

## Costs and Limits

### Free Tier (Spark Plan)

- 1 GB storage
- 10 GB/month network egress
- 50,000 reads/day
- 20,000 writes/day
- 20,000 deletes/day

### Blaze Plan (Pay as you go)

- $0.18 per GB storage
- $0.10 per GB network egress  
- $0.06 per 100,000 reads
- $0.18 per 100,000 writes
- $0.02 per 100,000 deletes

For typical usage:
- 1,000 daily active users
- ~10 captures/user/day
- ~5 trades/user/week
- **Estimated cost**: $5-20/month

## Alternative: Local Storage Only

To disable Firebase completely:

1. Remove from `pubspec.yaml`:
   ```yaml
   # cloud_firestore: ^5.4.4
   # firebase_core: ^3.6.0
   ```

2. Comment out Firebase in `main.dart`:
   ```dart
   // try {
   //   await Firebase.initializeApp();
   // } catch (e) {
   //   debugPrint("Firebase not configured: $e");
   // }
   ```

3. Replace `FirestoreService` with local storage service

This keeps all data on-device using SharedPreferences.

## Next Steps

After setup:
1. Test coin earning by capturing insects
2. Test creating a trade listing
3. Test accepting a trade (from another device)
4. Monitor Firestore usage in console
5. Implement authentication before production

## Resources

- [Firebase Docs](https://firebase.google.com/docs)
- [FlutterFire Docs](https://firebase.flutter.dev/)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Pricing](https://firebase.google.com/pricing)
