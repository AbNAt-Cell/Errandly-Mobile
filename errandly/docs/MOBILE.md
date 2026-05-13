# Errandly — Flutter Mobile App Documentation

Flutter mobile application (SDK ≥3.3) for customers and runners on iOS and Android.

---

## Table of Contents

1. [Project Structure](#project-structure)
2. [Dependencies](#dependencies)
3. [Navigation](#navigation)
4. [Screens — Auth Flow](#screens--auth-flow)
5. [Screens — Customer](#screens--customer)
6. [Screens — Runner](#screens--runner)
7. [Core Services](#core-services)
8. [Theme & Branding](#theme--branding)
9. [Platform Configuration](#platform-configuration)

---

## Project Structure

```
errandly/mobile/
├── lib/
│   ├── main.dart                              # App entry point
│   ├── core/
│   │   ├── constants/app_constants.dart       # API URLs, app config
│   │   ├── network/api_client.dart            # Dio HTTP client
│   │   ├── services/
│   │   │   ├── auth_service.dart              # Token management (secure storage)
│   │   │   └── location_service.dart          # GPS location service
│   │   └── theme/app_theme.dart               # ThemeData, colours, typography
│   └── features/
│       ├── auth/presentation/screens/
│       │   ├── splash_screen.dart             # Animated splash + auto-login
│       │   ├── role_select_screen.dart        # Customer vs Runner selection
│       │   ├── customer_login_screen.dart
│       │   ├── customer_register_screen.dart
│       │   ├── runner_login_screen.dart
│       │   └── runner_register_screen.dart
│       ├── customer/presentation/screens/
│       │   ├── customer_main_screen.dart      # Bottom nav shell
│       │   ├── customer_home_screen.dart      # Home tab
│       │   ├── customer_errands_screen.dart   # Errands list tab
│       │   ├── create_errand_screen.dart      # Multi-step errand creation
│       │   ├── errand_detail_screen.dart      # Errand detail + map tracking
│       │   ├── customer_wallet_screen.dart    # Wallet tab
│       │   ├── customer_messages_screen.dart  # Messages tab
│       │   └── customer_profile_screen.dart   # Profile tab
│       └── runner/presentation/screens/
│           ├── runner_main_screen.dart        # Bottom nav shell
│           ├── runner_home_screen.dart        # Available errands + online toggle
│           ├── runner_errand_detail_screen.dart # Full errand flow + OTP
│           ├── runner_earnings_screen.dart    # Earnings tab
│           ├── runner_messages_screen.dart    # Messages tab
│           ├── runner_activity_screen.dart    # Activity history tab
│           └── runner_profile_screen.dart     # Profile tab
├── android/app/src/main/AndroidManifest.xml
├── ios/Runner/Info.plist
└── pubspec.yaml
```

---

## Dependencies

### State Management
| Package | Usage |
|---------|-------|
| `flutter_bloc` 8.1 | BLoC pattern for feature-level state |
| `equatable` | Value equality for Bloc states/events |
| `get_it` | Service locator / dependency injection |

### Networking
| Package | Usage |
|---------|-------|
| `dio` 5.4 | HTTP client with interceptors |
| `retrofit` 4.1 | Type-safe REST client generation |
| `json_annotation` | JSON serialization annotations |

### Storage
| Package | Usage |
|---------|-------|
| `flutter_secure_storage` | Auth token storage (Keychain/Keystore) |
| `shared_preferences` | Non-sensitive settings |
| `hive_flutter` | Local cache for offline data |

### Maps & Location
| Package | Usage |
|---------|-------|
| `flutter_map` 7.0 | OpenStreetMap-based map widget |
| `latlong2` | Coordinate data types |
| `geolocator` 12.0 | GPS positioning |
| `geocoding` 3.0 | Address ↔ coordinate conversion |

### UI
| Package | Usage |
|---------|-------|
| `flutter_screenutil` | Responsive sizing (dp scaling) |
| `cached_network_image` | Image caching |
| `shimmer` | Loading skeleton animations |
| `lottie` | Lottie JSON animations |
| `smooth_page_indicator` | Page dots (onboarding, wizard) |
| `dotted_border` | Dashed border for file upload zones |
| `fl_chart` | Charts for runner earnings |
| `pin_code_fields` | OTP PIN entry widget |
| `image_picker` | Camera/gallery photo selection |
| `file_picker` | Document file picker |
| `signature` | Signature capture widget |

### Real-time
| Package | Usage |
|---------|-------|
| `pusher_channels_flutter` | Pusher Channels client for live updates |

### Media
| Package | Usage |
|---------|-------|
| `record` | Voice note recording |
| `audioplayers` | Voice note playback |

### Utilities & Platform
| Package | Usage |
|---------|-------|
| `intl` | Date/number formatting (₦ currency) |
| `timeago` | Relative time ("2 min ago") |
| `url_launcher` | Open phone dialer, links |
| `permission_handler` | Runtime permissions (location, camera, mic) |
| `local_auth` | Biometric authentication (Face ID / fingerprint) |
| `flutter_local_notifications` | Local push notifications |
| `firebase_messaging` 15 | FCM push notifications |
| `firebase_core` 3 | Firebase initialization |
| `connectivity_plus` | Network connectivity detection |

---

## Navigation

Navigation is handled by `go_router` with role-based initial route selection.

**Route tree:**
```
/splash                 → SplashScreen
/role-select            → RoleSelectScreen
/customer/login         → CustomerLoginScreen
/customer/register      → CustomerRegisterScreen
/runner/login           → RunnerLoginScreen
/runner/register        → RunnerRegisterScreen

/customer               → CustomerMainScreen (bottom nav shell)
  /customer/home        → CustomerHomeScreen
  /customer/errands     → CustomerErrandsScreen
  /customer/errands/new → CreateErrandScreen
  /customer/errands/:id → ErrandDetailScreen
  /customer/wallet      → CustomerWalletScreen
  /customer/messages    → CustomerMessagesScreen
  /customer/profile     → CustomerProfileScreen

/runner                 → RunnerMainScreen (bottom nav shell)
  /runner/home          → RunnerHomeScreen
  /runner/errands/:id   → RunnerErrandDetailScreen
  /runner/earnings      → RunnerEarningsScreen
  /runner/messages      → RunnerMessagesScreen
  /runner/activity      → RunnerActivityScreen
  /runner/profile       → RunnerProfileScreen
```

On launch, `SplashScreen` checks secure storage for an auth token. If found, it calls `/api/auth/me` to validate it and routes to either `/customer` or `/runner` based on role. If no token, it routes to `/role-select`.

---

## Screens — Auth Flow

### `SplashScreen`
- Animated Errandly logo with orange fade-in.
- Auto-checks stored token and role, then navigates to appropriate dashboard or login.

### `RoleSelectScreen`
- Two illustrated cards: "I need something done" (Customer) and "I run errands" (Runner).
- Navigates to the appropriate login/register flow.

### `CustomerLoginScreen` / `RunnerLoginScreen`
- Email + password fields.
- "Forgot password?" link.
- On success: stores JWT in `flutter_secure_storage`, navigates to role dashboard.

### `CustomerRegisterScreen`
- Fields: first name, last name, email, phone, password, confirm password.
- Calls `POST /api/auth/register/customer`.
- After registration, shows phone OTP verification screen.

### `RunnerRegisterScreen`
- Additional fields: NIN, transport type, guarantor details.
- Calls `POST /api/auth/register/runner`.
- After registration, prompts for KYC document submission.

---

## Screens — Customer

### `CustomerMainScreen`
Bottom navigation bar with 5 tabs: Home, Errands, _(FAB: Create Errand)_, Wallet, Messages, Profile.

### `CustomerHomeScreen`
- Welcome banner with user name.
- Active errand summary card (if one is in progress): status badge, runner name, live progress.
- Quick action buttons: "Post Errand", "Track Errand", "My Wallet".
- Recent errands list (last 3).

### `CustomerErrandsScreen`
- Filterable list: All / Active / Completed / Cancelled / Disputed.
- Each card shows: category icon, title, status chip (colour-coded), runner name (if assigned), date/time.
- Pull-to-refresh.

### `CreateErrandScreen` — Multi-step Wizard

**Step 1 — Category & Urgency**
- Grid of 10 category tiles with icons.
- Urgency selector: Standard / Urgent / Scheduled (with date-time picker for scheduled).

**Step 2 — Locations**
- Pickup address text field with autocomplete.
- Destination address text field.
- Interactive `flutter_map` to drag-pin both locations.
- "Use saved address" shortcut.

**Step 3 — Details**
- Item description, recipient name & phone (optional).
- Special instructions text area.
- Attachment upload (camera or gallery).

**Step 4 — Budget & Review**
- Budget input with live platform fee calculation (15%).
- Total shown as: Budget + Fee = Total Deducted.
- Wallet balance check — warns if insufficient.
- Full errand summary review card.

**Step 5 — Confirmation**
- Success animation (Lottie).
- Errand ID and "Track Errand" button.

### `ErrandDetailScreen`
- Full errand information.
- Status timeline stepper.
- Live `flutter_map` with runner location marker (updated via Pusher `RunnerLocationUpdated` events).
- In-progress chat shortcut.
- OTP entry card (appears at `awaiting_confirmation` status): `pin_code_fields` widget for 6-digit delivery OTP.
- Proof photo viewer (when runner submits proof).
- **Panic button** (red, visible during active errand): triggers `POST /api/customer/errands/{id}/panic`.
- Cancel button (visible when cancellable).

### `CustomerWalletScreen`
- Balance card (large, styled in navy/orange).
- "Fund Wallet" button → opens Paystack/Stripe web view.
- Transaction history list with direction indicators (↑ debit, ↓ credit), type badge, amount, date.

### `CustomerMessagesScreen`
- Conversation list grouped by errand.
- Unread badge per conversation.
- Opens chat view with text, voice note, and image message support.

### `CustomerProfileScreen`
- Profile photo with upload.
- Editable: name, email, phone.
- Emergency contact fields.
- Saved addresses management.
- App settings (notifications, biometric login toggle).
- Logout button.

---

## Screens — Runner

### `RunnerMainScreen`
Bottom navigation: Home, Earnings, Messages, Activity, Profile.

### `RunnerHomeScreen`
- **Online/Offline toggle** (prominent switch at top) — calls `PUT /api/runner/availability`.
- Trust Score ring chart (fl_chart).
- Available errands nearby (list or map view toggle).
- Each errand card: category, title, distance, budget, urgency badge.
- "Accept" button on each errand card.

### `RunnerErrandDetailScreen`
Full errand execution screen with action buttons that change based on current status:

| Status | Available actions |
|--------|------------------|
| `accepted` | "I've Arrived at Pickup" button |
| `runner_en_route` | OTP entry field (pickup OTP from customer) → "Confirm Pickup" |
| `item_picked` | "Start Errand" button |
| `in_progress` | "Submit Proof & Mark Complete" button |
| `awaiting_confirmation` | Waiting indicator (customer must enter delivery OTP) |

**Map section:** Real-time flutter_map with:
- Current runner position (blue dot).
- Pickup marker (green pin).
- Destination marker (red pin).
- Route polyline.

**Proof submission sheet:**
- Photo capture (camera).
- Receipt photo upload.
- Signature capture (`signature` widget).
- Text note.

**Panic button** (red, always visible during active errand).

**Chat FAB** opens conversation with customer.

### `RunnerEarningsScreen`
- Available balance + pending withdrawal.
- Total earned lifetime.
- Earnings chart by week/month (fl_chart bar chart).
- Withdrawal form: amount input + bank account display.
- Transaction list.
- "Update Bank Account" bottom sheet.

### `RunnerMessagesScreen`
Same as customer messages — all conversations for the runner's errands.

### `RunnerActivityScreen`
- Completed errand history.
- Per-errand: date, earnings, customer rating received.
- Filters: This Week / This Month / All Time.

### `RunnerProfileScreen`
- Profile photo upload.
- Personal details (view + edit).
- KYC status badge and "Resubmit" button if rejected.
- Transport type display.
- Trust score breakdown card.
- Availability schedule (days + hours).
- Skills tags.
- Logout button.

---

## Core Services

### `core/network/api_client.dart`

Built on `Dio` with:
- `BaseOptions.baseUrl` from `AppConstants.apiBaseUrl`.
- `AuthInterceptor`: attaches `Authorization: Bearer {token}` from secure storage to every request.
- `LogInterceptor`: in debug mode, logs requests/responses.
- `ErrorInterceptor`: on 401, clears stored token and navigates to role select screen.

### `core/services/auth_service.dart`

| Method | Description |
|--------|-------------|
| `login(email, password)` | Posts to `/api/auth/login`, stores token + user in secure storage |
| `logout()` | Calls `/api/auth/logout`, clears secure storage |
| `getStoredUser()` | Returns cached user from secure storage |
| `getStoredToken()` | Returns raw JWT from secure storage |
| `isAuthenticated()` | Returns true if valid token exists |
| `getRole()` | Returns `customer` or `runner` from stored user |

### `core/services/location_service.dart`

| Method | Description |
|--------|-------------|
| `requestPermission()` | Requests `LocationPermission` at runtime |
| `getCurrentLocation()` | Returns `Position` via geolocator |
| `startTracking(onUpdate)` | Starts stream; for runners, each update is POSTed to `/api/runner/errands/{id}/location` |
| `stopTracking()` | Cancels the position stream subscription |
| `getAddressFromCoordinates(lat, lng)` | Reverse geocoding via `geocoding` package |

### `core/constants/app_constants.dart`

```dart
class AppConstants {
  static const String apiBaseUrl = 'http://YOUR_API_URL/api';
  static const String pusherKey = 'YOUR_PUSHER_KEY';
  static const String pusherCluster = 'mt1';
  static const String currency = '₦';
  static const int otpLength = 6;
  static const double defaultMapZoom = 14.0;
}
```

---

## Theme & Branding

### `core/theme/app_theme.dart`

```dart
// Primary colours
Color primaryOrange = Color(0xFFFF6B00);
Color primaryNavy  = Color(0xFF0A1628);

// Typography
// Inter font family loaded from assets/fonts/
// Weights: Regular (400), Medium (500), SemiBold (600), Bold (700)
```

The `ThemeData` sets:
- `colorScheme.primary` = orange
- `colorScheme.background` = white / light grey
- `AppBarTheme` with navy background
- `ElevatedButton` with orange fill, rounded corners (12 dp)
- `InputDecoration` with subtle grey borders
- All sizes scaled via `flutter_screenutil`

---

## Platform Configuration

### Android — `AndroidManifest.xml`

Permissions declared:
- `INTERNET`
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`
- `CAMERA`
- `READ_EXTERNAL_STORAGE`
- `WRITE_EXTERNAL_STORAGE`
- `RECORD_AUDIO`
- `USE_BIOMETRIC`
- `USE_FINGERPRINT`
- `RECEIVE_BOOT_COMPLETED` (for local notification scheduling)

Firebase config: `google-services.json` placed in `android/app/`.

### iOS — `Info.plist`

Usage description keys:
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription`
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSMicrophoneUsageDescription`
- `NSFaceIDUsageDescription`

Firebase config: `GoogleService-Info.plist` placed in `ios/Runner/`.

### Assets

```
assets/
├── images/          # App illustrations, logo PNG
├── icons/           # Custom SVG icons
├── animations/      # Lottie JSON files (splash, success, loading)
└── fonts/
    ├── Inter-Regular.ttf
    ├── Inter-Medium.ttf
    ├── Inter-SemiBold.ttf
    └── Inter-Bold.ttf
```
