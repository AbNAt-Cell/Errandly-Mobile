# Errandly Mobile

Flutter app for customers and runners.

## Production / Play Store setup

See **`env.example`** for the full checklist. Summary:

| Item | Location |
|------|----------|
| Release signing | `android/key.properties` (copy from `key.properties.example`) |
| Firebase push | `android/app/google-services.json` |
| Legal URLs | `lib/core/constants/app_constants.dart` |
| API URL | `lib/core/constants/app_constants.dart` |

### Build release AAB (Play Store)

```bash
cd errandly/mobile
flutter pub get
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Release signing

1. Generate keystore (once):
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Copy `android/key.properties.example` → `android/key.properties`
3. Place `upload-keystore.jks` in `android/` folder
4. Build — release uses your keystore automatically when `key.properties` exists

## Push notifications (FCM)

The app uses **Firebase Cloud Messaging** with the backend FCM HTTP v1 API.

### 1. Firebase project (same as backend)

Use the same Firebase project as the API (`FIREBASE_PROJECT_ID`).

### 2. Android

1. Firebase Console → **Project settings** → **Your apps** → **Add app** → **Android**
2. Package name: `com.example.errandly` (must match `android/app/build.gradle.kts` `applicationId`)
3. Download **`google-services.json`**
4. Place it at: `android/app/google-services.json`
5. Do **not** commit this file (already in `.gitignore`)

### 3. Run the app

```bash
flutter pub get
flutter run
```

After login, the app registers the FCM token via `POST /api/auth/device-token`.

## Account deletion

Profile → **Security & Privacy** → **Delete Account**

Requires backend endpoint `DELETE /api/auth/account` (deploy latest API).

## Legal pages

Before Play Store submission, host and link:

- Privacy policy: `AppConstants.privacyPolicyUrl`
- Terms of service: `AppConstants.termsOfServiceUrl`
- Support: `AppConstants.supportUrl`

Enter the privacy policy URL in Play Console → App content.
