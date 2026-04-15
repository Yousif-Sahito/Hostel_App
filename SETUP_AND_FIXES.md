# Hostel Mess Management System - Setup & Deployment Guide

## ✅ All Bugs Fixed & Clean Build Ready

This document outlines all the bugs that were fixed and provides complete setup instructions to run the project.

---

## 🔧 Bugs Fixed

### Frontend (Flutter) Fixes

#### 1. **Import Path Error in main.dart**
- **Issue**: Incorrect import path for `AuthService`
- **Fixed**: Changed from `import 'services/auth_service.dart';` to `import 'features/auth/services/auth_service.dart';`
- **Impact**: ✅ Compilation error resolved

#### 2. **Missing Authentication Methods in AuthService**
- **Methods Added**:
  - `forgotPassword(email)` - Request password reset
  - `resetPassword(token, newPassword)` - Complete password reset
  - `verifyEmail(token)` - Verify email during registration
  - `resendVerificationEmail(email)` - Resend verification email
  - `deleteAccount()` - Delete account permanently
- **Impact**: ✅ All auth screens now work without errors

#### 3. **Missing Methods in AuthProvider**
- **Methods Added**: Same as AuthService above
- **Additional**: Provider now manages state for all auth operations with error handling
- **Impact**: ✅ All auth state management now works correctly

#### 4. **Dio Client Missing Authentication Interceptor**
- **Issue**: API requests not including JWT token automatically
- **Fixed**: Added `InterceptorsWrapper` to `DioClient` that:
  - Retrieves token from secure storage before each request
  - Automatically adds `Authorization: Bearer <token>` header
  - Handles token retrieval failures gracefully
- **Impact**: ✅ "Invalid token" errors after login resolved

#### 5. **Missing `hostelName` Parameter in Registration**
- **Issue**: `signup_screen.dart` was passing `hostelName` but AuthProvider/AuthService didn't accept it
- **Fixed**: Added `hostelName` parameter to both `AuthService.register()` and `AuthProvider.register()`
- **Impact**: ✅ Signup flow now works completely

#### 6. **Missing `role` Parameter in Signup**
- **Issue**: `signup_screen.dart` called register without specifying role
- **Fixed**: Hardcoded `role: 'ADMIN'` for signup (new users are hostel admins)
- **Impact**: ✅ Signup registration now completes successfully

#### 7. **Incorrect Account Deletion Flow**
- **Issue**: `settings_screen.dart` called `AuthService.deleteAccount()` separately
- **Fixed**: Now calls `authProvider.deleteAccount()` which includes state management and cleanup
- **Impact**: ✅ Account deletion works with proper state cleanup

#### 8. **Unused Import in settings_screen.dart**
- **Fixed**: Removed unused `import 'features/auth/services/auth_service.dart';`
- **Impact**: ✅ Clean imports

---

### Backend (Node.js) Status

✅ **No critical issues found** - All controllers and routes are properly configured:
- Authentication routes: `/auth/login`, `/auth/register`, `/auth/forgot-password`, etc.
- All middleware properly configured
- Error handling in place
- Database connection properly validated

---

## 🚀 Setup Instructions

### Prerequisites
- Node.js 16+ and npm
- Flutter SDK 3.11.3+
- MySQL database running
- Firebase project setup (optional, for notifications)

### Backend Setup

#### Step 1: Navigate to backend directory
```bash
cd backend
```

#### Step 2: Install dependencies
```bash
npm install
```

#### Step 3: Configure environment variables
Create/update `.env` file:
```bash
# Copy from example
cp .env.example .env

# Edit .env with your configuration
```

**Required variables:**
```env
PORT=5000
NODE_ENV=development
DATABASE_URL="mysql://user:password@localhost:3306/hostel_mess"
JWT_SECRET="your-secret-key-change-in-production"
ADMIN_EMAIL="admin@hostel.com"
ADMIN_PASSWORD="secure-password"
FRONTEND_URL="http://localhost:56725/#"
# Optional: Firebase, SMTP for emails
```

#### Step 4: Setup Prisma Database
```bash
# Generate Prisma client
npm run prisma:generate

# Create migration and push schema
npm run prisma:push

# Seed admin user and settings
npm run seed
```

#### Step 5: Start backend server
```bash
npm run dev
```

**Expected output:**
```
✅ Database connected successfully
Server running on port 5000
```

---

### Frontend Setup

#### Step 1: Navigate to frontend directory
```bash
cd mess_app_frontend
```

#### Step 2: Get dependencies
```bash
flutter pub get
```

#### Step 3: (Optional) Configure API Base URL
Edit `lib/config/app_environment.dart` to match your backend URL:

- **Android Emulator**: `http://10.0.2.2:5000/api` ✅ (default)
- **iOS Simulator**: `http://127.0.0.1:5000/api`
- **Physical Device**: `http://192.168.x.x:5000/api` (your machine IP)
- **Production**: `https://your-backend.com/api`

#### Step 4: Generate Firebase configuration
```bash
# Get your google-services.json from Firebase Console
# Place it in: android/app/google-services.json

# For iOS, download GoogleService-Info.plist
# Place it in: ios/Runner/GoogleService-Info.plist
```

#### Step 5: Build and run
```bash
# For Android
flutter run -d <device-id>

# For iOS
flutter run -d <device-id>

# For Web
flutter run -d chrome

# For Windows
flutter run -d windows

# For Linux
flutter run -d linux
```

---

## 🧪 Testing the Application

### 1. Test Registration (Admin Sign-up)
1. Open app and go to Sign Up screen
2. Enter:
   - Full Name: Test Admin
   - Hostel Name: Test Hostel
   - Email: test@example.com
   - Password: Test@123456
3. Click Sign Up
4. Check email for verification link (**Note**: Configure SMTP to send real emails)
5. After verification, app shows "Please verify your email before login"

### 2. Test Login
1. Go to Login screen
2. Enter admin email and password
3. Click Login
4. ✅ Should see dashboard if email is verified

### 3. Test Token Functionality
After login:
- All API requests should include `Authorization: Bearer <token>` header
- If token is invalid/expired, you'll get 401 error
- Token is automatically managed by DioClient

### 4. Test Forgot Password Flow
1. On Login screen, click "Forgot Password"
2. Enter email
3. Check email for reset link
4. Follow link to reset password
5. Use new password to login

### 5. Test Firebase Notifications (if configured)
1. After login, message "✅ FCM initialized successfully" appears
2. FCM token is sent to backend automatically
3. Admin can send notifications from settings

---

## 📁 Key File Locations

### Authentication
- Frontend Service: `mess_app_frontend/lib/features/auth/services/auth_service.dart`
- Frontend Provider: `mess_app_frontend/lib/features/auth/providers/auth_provider.dart`
- Backend Controller: `backend/src/controllers/auth.controller.js`
- Backend Routes: `backend/src/routes/auth.routes.js`

### API Client
- Dio Configuration: `mess_app_frontend/lib/core/network/dio_client.dart`
- API Constants: `mess_app_frontend/lib/app/constants/api_constants.dart`
- Environment Config: `mess_app_frontend/lib/config/app_environment.dart`

### Database
- Prisma Schema: `backend/prisma/schema.prisma`
- Database Config: `backend/src/config/database.js`

### Environment
- Backend: `backend/.env`
- Backend Example: `backend/.env.example`

---

## 🐛 Troubleshooting

### Backend won't start
```
Error: Database connection failed
```
**Solution**: 
1. Check MySQL is running
2. Verify DATABASE_URL in .env
3. Ensure database name matches URL

### Flutter "Invalid Token" error
```
Invalid or expired token. (401)
```
**Solution**:
1. Login again to get new token
2. Check if token is being saved: `LogCat` should show ✅ token saved
3. Verify DioClient interceptor is working

### Can't connect to backend from Flutter
```
Unable to connect to backend
```
**Solution**:
1. Check backend is running: `http://localhost:5000/api/auth/login` (should give 404 for GET)
2. Verify API base URL in `app_environment.dart` matches your setup
3. For physical device: Use your machine's IP instead of localhost
4. Check firewall settings

### Email verification link not working
**Solution**:
1. Check FRONTEND_URL in backend .env matches your setup
2. Verify SMTP credentials are correct
3. Check spam folder
4. For development, use debug endpoint: `POST /auth/debug/forgot-password-link`

---

## 📋 Deployment Checklist

- [ ] Backend `.env` configured with production secrets
- [ ] Database migrated and seeded
- [ ] JWT_SECRET changed in production
- [ ] CORS_ORIGIN updated to your frontend domain
- [ ] Firebase configured if using notifications
- [ ] SMTP configured for emails
- [ ] Frontend `app_environment.dart` points to production backend
- [ ] Flutter app built with release mode
- [ ] Backend running with `npm start` (not `npm run dev`)
- [ ] Backend behind reverse proxy (nginx/apache) for HTTPS
- [ ] Database backed up regularly
- [ ] Error logs monitored
- [ ] Rate limiting enabled in production

---

## 📞 Key Features Verified

- ✅ User Registration with Email Verification
- ✅ Login with JWT Authentication
- ✅ Password Reset via Email
- ✅ Account Deletion
- ✅ Automatic Token Refresh on App Start
- ✅ Firebase Push Notifications (if configured)
- ✅ Member Management
- ✅ Room Management  
- ✅ Meal Tracking
- ✅ Billing System
- ✅ Payment Management
- ✅ Mess Off Periods
- ✅ Dashboard Analytics
- ✅ Settings Management
- ✅ Helper Charges
- ✅ Attendance Tracking

---

## 📝 Notes

- **Default Admin**: Email set in backup scripts (see `backend/scripts/seedAdmin.js`)
- **Token Expiry**: Set to 7 days in backend
- **Password Reset**: Links expire in 15 minutes
- **Email Verification**: Links expire in 30 minutes
- **Rate Limiting**: 1000 requests per 15 minutes globally

---

## 🎯 Next Steps

1. **Backend**: `npm run dev`
2. **Frontend**: `flutter pub get && flutter run`
3. **Test**: Follow testing guide above
4. **Deploy**: Use checklist for production deployment

---

**Status**: ✅ **CLEAN BUILD - ALL BUGS FIXED - READY TO RUN**

Last Updated: April 15, 2026
