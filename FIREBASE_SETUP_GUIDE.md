# Push Notifications Setup Guide

This application now supports push notifications for:
1. **Mess Off Alerts** - Admins receive notifications when members mark mess off
2. **Unpaid Bill Reminders** - Members receive notifications after 30 days of unpaid bills

## Setup Instructions

### Prerequisites

1. Google/Firebase Account
2. Flutter and backend server running

---

## Step 1: Set Up Firebase Project

### 1.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Create a new project**
3. Enter project name (e.g., "MessApp")
4. Follow the setup wizard

### 1.2 Enable Cloud Messaging

1. In Firebase Console, go to **Project Settings** → **Cloud Messaging**
2. Note down the **Server API Key** (you'll need this for backend)

---

## Step 2: Configure Android

### 2.1 Add Google Services JSON

1. In Firebase Console:
   - Go to Project Settings → **General** tab
   - Click **Add App** → **Android**
   - Package name: `com.example.mess_app_frontend` (or your package name)
   - Download `google-services.json`

2. Move the file to:
   ```
   mess_app_frontend/android/app/google-services.json
   ```

3. Update `mess_app_frontend/android/build.gradle`:
   ```gradle
   buildscript {
     dependencies {
       classpath 'com.google.gms:google-services:4.3.15'
     }
   }
   ```

4. Update `mess_app_frontend/android/app/build.gradle`:
   ```gradle
   plugins {
     id 'com.android.application'
     id 'com.google.gms.google-services'  // Add this line
   }
   ```

---

## Step 3: Configure iOS (Optional)

### 3.1 Download Service Account

1. Go to Firebase → Project Settings → **Service Accounts**
2. Click **Generate New Private Key**
3. Save the JSON file securely

### 3.2 Enable Push Notifications in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** project
3. Go to **Signing & Capabilities**
4. Click **+ Capability** → Add **Push Notifications**

---

## Step 4: Configure Backend

### 4.1 Add Firebase Service Account

1. In Firebase Console → Project Settings → **Service Accounts** tab
2. Click **Generate New Private Key** (download the JSON file)

3. In your `.env` file, add:
   ```env
   FIREBASE_SERVICE_ACCOUNT_KEY='{"type":"service_account","project_id":"...","private_key":"...","client_email":"..."}'
   ```

   Or store the entire JSON as a single line string.

### 4.2 Install Backend Dependencies

```bash
cd backend
npm install
```

---

## Step 5: Update Base URL in Flutter

In `lib/services/auth_service.dart`, update the base URL if needed:

```dart
static const String _baseUrl = 'http://your-backend-url:5000/api';
```

For Android emulator, use your machine's IP address:
```dart
static const String _baseUrl = 'http://10.0.2.2:5000/api';
```

---

## Step 6: Update Flutter Pubspec (Already Done)

The following dependencies have been added:
- `firebase_core`
- `firebase_messaging`

If not already installed, run:
```bash
cd mess_app_frontend
flutter pub get
```

---

## Step 7: Build and Test

### 7.1 Test the Backend

1. Create a Prisma migration:
   ```bash
   cd backend
   npx prisma migrate dev --name add_fcm_token
   ```

2. Start the backend:
   ```bash
   npm run dev
   ```

3. You should see: `"Unpaid bill notification scheduler initialized"`

### 7.2 Test Flutter App

```bash
cd mess_app_frontend
flutter run
```

When you log in, you should see in the console:
```
FCM Token: <long_token_string>
FCM token updated successfully on backend
```

---

## Step 8: Test Notifications

### Test Mess Off Notification (Requires Admin):

1. Log in as **Admin**
2. Have a member mark their mess off
3. **Admin should receive notification**

### Test Unpaid Bill Notification (Automatic):

1. Create an unpaid bill for a member
2. Wait for the scheduled job (runs daily at 8 AM server time)
3. Or trigger manually by restarting the backend
4. **Member should receive notification after 30 days unpaid**

---

## File Structure

### Backend Changes:
- `src/config/firebase.js` - Firebase Admin SDK configuration
- `src/services/notification.service.js` - Notification sending logic
- `src/config/scheduler.js` - Cron job for unpaid bills
- `src/controllers/auth.controller.js` - FCM token update endpoint
- `src/routes/auth.routes.js` - Auth routes with FCM endpoint

### Frontend Changes:
- `lib/services/fcm_service.dart` - Firebase Cloud Messaging service
- `lib/services/auth_service.dart` - FCM token submission
- `lib/main.dart` - Firebase initialization
- `lib/features/auth/providers/auth_provider.dart` - FCM token after login

### Database:
- `User` model now includes `fcmToken` field

---

## Troubleshooting

### Notifications Not Working

1. **Check Firebase credentials**: Ensure `FIREBASE_SERVICE_ACCOUNT_KEY` is correctly set
2. **Check FCM token**: Log in and verify the token is saved in database:
   ```sql
   SELECT id, fullName, fcmToken FROM User WHERE fcmToken IS NOT NULL;
   ```

3. **Check Android permissions**: Verify `AndroidManifest.xml` has:
   ```xml
   <uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />
   ```

4. **Emulator not receiving notifications**: Use a real device or Google Play Services emulator

### Backend Scheduler Not Running

1. Check that `node-cron` is installed: `npm list node-cron`
2. Verify `.env` file is loaded
3. Check backend logs for scheduler initialization message

---

## API Endpoints

### Update FCM Token
```
POST /api/auth/update-fcm-token
Headers: Authorization: Bearer <token>
Body: { "fcmToken": "..." }
```

---

## Next Steps

- Monitor logs for notification delivery
- Test with real devices, not emulators
- Consider implementing retry logic for failed notifications
- Add notification history/logs to your dashboard

---

## Important Notes

⚠️ **Production Deployment:**
- Use environment variables for sensitive data
- Never commit Firebase credentials to version control
- Test notifications thoroughly before release
- Consider rate limiting for bulk notifications
- Monitor Firebase quota usage
