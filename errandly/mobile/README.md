# Errandly Mobile

Flutter app for customers and runners.

## Push notifications (FCM)

The app uses **Firebase Cloud Messaging** with the backend FCM HTTP v1 API (see `errandly/backend` `.env`).

### 1. Firebase project (same as backend)

Use the same Firebase project as the API (`FIREBASE_PROJECT_ID`).

### 2. Android

1. Firebase Console → **Project settings** → **Your apps** → **Add app** → **Android**.
2. Package name: `com.example.errandly` (must match `android/app/build.gradle.kts` `applicationId`).
3. Download **`google-services.json`**.
4. Place it at:

   `android/app/google-services.json`

5. Do **not** commit this file if your repo is public (add to `.gitignore` if needed).

### 3. iOS (when building for iPhone)

1. Add an **iOS** app in Firebase (bundle ID from Xcode).
2. Download **`GoogleService-Info.plist`** → `ios/Runner/GoogleService-Info.plist`.
3. In Xcode: enable **Push Notifications** and **Background Modes → Remote notifications**.
4. Upload your APNs key in Firebase → **Project settings** → **Cloud Messaging**.

### 4. Run the app

```bash
cd errandly/mobile
flutter pub get
flutter run
```

After login, the app registers the FCM token via `POST /api/auth/device-token` and on token refresh.

### 5. Test end-to-end

1. Backend: `FIREBASE_ENABLED=true` and service account JSON configured.
2. Log in on a device/emulator with Google Play services (Android).
3. Backend: `php artisan fcm:test customer@test.com`

### Behaviour

| State | Behaviour |
|--------|-----------|
| Foreground | System banner via `flutter_local_notifications` |
| Background / killed | FCM system tray; tap opens errand or notifications list |
| `errand_offer` (runner) | Opens runner home (available errands) |
| Other errand types | Opens errand detail when `public_id` is in payload |

### Preferences & multi-device (Phase 4)

- Each install registers a **device_id** + FCM token (`user_device_tokens` table).
- **Profile → Notification settings** toggles push categories (errand, payments, marketing, etc.).
- Admin broadcasts use batched FCM sends (25 concurrent requests per chunk).
- API: `GET/PUT /api/notification-preferences`, `POST /api/auth/device-token` requires `device_id`.

### Inbox (Phase 3)

- Bell icon on customer/runner home with unread badge
- **Profile → Notifications** and inbox list: tap a row to open the related errand/KYC screen
- Unread count refreshes on app start, foreground push, and when leaving the inbox
