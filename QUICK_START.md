# Quick Start Checklist - Push Notifications

Complete these steps in order to enable push notifications in your app.

---

## ✅ Phase 1: Firebase Setup (5-10 minutes)

### Step 1: Create Firebase Project
- [ ] Go to https://console.firebase.google.com/
- [ ] Click "Create a project"
- [ ] Name: "MessApp" (or your preferred name)
- [ ] Choose your region
- [ ] Create project

### Step 2: Get Service Account Key
- [ ] In Firebase, go to **Project Settings** (gear icon)
- [ ] Go to **Service Accounts** tab
- [ ] Click **Generate New Private Key**
- [ ] Save the JSON file securely

### Step 3: Add to Backend .env
In `backend/.env`, add this line (copy entire JSON as one line):
```
FIREBASE_SERVICE_ACCOUNT_KEY='{"type":"service_account","project_id":"..."}'
```

### Step 4: Configure Android
- [ ] In Firebase, click **+ Add App**
- [ ] Select **Android**
- [ ] Package name: `com.example.mess_app_frontend`
- [ ] Download `google-services.json`
- [ ] Place at: `mess_app_frontend/android/app/google-services.json`
- [ ] Click Next, then **Skip** GooglePlay connection

---

## ✅ Phase 2: Install Dependencies (2-3 minutes)

### Step 5: Backend Dependencies
```bash
cd backend
npm install
```

### Step 6: Frontend Dependencies
```bash
cd mess_app_frontend
flutter pub get
```

---

## ✅ Phase 3: Database Setup (1 minute)

### Step 7: Run Migration
```bash
cd backend
npx prisma migrate dev --name add_fcm_token
```

When prompted:
- Enter migration name: `add_fcm_token`
- Select "Create migration"

---

## ✅ Phase 4: Update Configuration (2 minutes)

### Step 8: Update Backend API URL (if needed)
In `mess_app_frontend/lib/services/auth_service.dart`:

**For Android Emulator:**
```dart
static const String _baseUrl = 'http://10.0.2.2:5000/api';
```

**For Real Device (replace with your IP):**
```dart
static const String _baseUrl = 'http://192.168.x.x:5000/api';
```

**For Web/Desktop:**
```dart
static const String _baseUrl = 'http://localhost:5000/api';
```

---

## ✅ Phase 5: Start Services (1 minute)

### Step 9: Start Backend
```bash
cd backend
npm run dev
```

Expected output:
```
Server running on port 5000
Unpaid bill notification scheduler initialized (runs daily at 8 AM)
```

### Step 10: Start Frontend
In a new terminal:
```bash
cd mess_app_frontend
flutter run
```

Expected output in console:
```
FCM Token: ABC123DEF456...
FCM Service initialized successfully
```

---

## ✅ Phase 6: Test Notifications (5 minutes)

### Step 11: Test Mess Off Notification

1. **On Admin Device:**
   - Log in as Admin
   - Note the FCM Token in console

2. **On Member Device (or same device, new login):**
   - Log in as Member
   - Go to Mess Off section
   - Click "Mark Mess Off"
   - Enter dates and reason
   - "Submit

3. **Check Admin Device:**
   - Should see notification: "Mess Off Alert"
   - Message: "[MemberName] has marked their mess off"

### Step 12: Test Unpaid Bill Notification

1. **Create Unpaid Bill:**
   - Admin creates a bill dated 30+ days ago
   - Or wait for next day at 8 AM

2. **Trigger Scheduler (optional - or wait for 8 AM):**
   - Restart backend
   - Check member device for notification
   - Should see: "Your bill of PKR [amount] is [days] days overdue"

---

## 🔍 Verification Checklist

After setup, verify everything works:

- [ ] Backend starts without errors
- [ ] Frontend builds and runs
- [ ] FCM token appears in console when logging in
- [ ] Message "FCM token updated successfully" appears
- [ ] Notification received on admin device for mess off
- [ ] Notification received on member device for unpaid bill (next day at 8 AM)

---

## ⚠️ Common Issues & Fixes

### Issue: "FIREBASE_SERVICE_ACCOUNT_KEY not found"
**Fix:** Check `.env` file has the Firebase JSON key

### Issue: "Cannot GET /api/auth/update-fcm-token"
**Fix:** Make sure backend is running (`npm run dev`)

### Issue: "No issues found! Exit code 1"
**Fix:** This is normal - Flutter analyze warns about info-level issues, not errors

### Issue: "Notifications not received on real device"
**Fix:** 
- Check notifications are enabled in device settings
- Verify device has Google Play Services (Android)
- Check FCM token is saved in database

### Issue: "Unpaid bill notification not sent"
**Fix:**
- Check scheduler message in backend logs
- Verify bill is actually 30+ days old in database
- Check member has FCM token saved

---

## 📞 Need Help?

1. **Read Full Guides:**
   - `FIREBASE_SETUP_GUIDE.md` - Detailed setup steps
   - `NOTIFICATION_SCENARIOS.md` - How notifications work
   - `IMPLEMENTATION_SUMMARY.md` - Technical overview

2. **Check Logs:**
   ```bash
   # Backend logs
   npm run dev    # Shows all logs

   # Frontend console
   flutter run    # Shows all output
   ```

3. **Verify Database:**
   ```bash
   # Check if fcmToken column exists and is populated
   npx prisma studio
   # Look at User table -> fcmToken field
   ```

---

## 📋 Time Estimate

- Phase 1 (Firebase): ~5-10 minutes
- Phase 2 (Dependencies): ~3 minutes
- Phase 3 (Database): ~1 minute
- Phase 4 (Config): ~2 minutes
- Phase 5 (Services): ~1 minute
- Phase 6 (Testing): ~5 minutes

**Total: ~20 minutes** for complete setup

---

## ✨ What Works Now

Once completed, your app has:

✅ Admin receives instant notification when member marks mess off
✅ Member receives automatic reminder for unpaid bills (30+ days)
✅ Notifications work on Android and iOS
✅ Notifications work in foreground, background, and closed states
✅ Automated daily scheduler for bill notifications
✅ Extensible notification system for future features

---

**Last Updated:** April 6, 2026

**Ready to start?** Begin with **Step 1** above! 🚀
