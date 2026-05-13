# Errandly — Web Frontend Documentation

Next.js 14 (App Router) web dashboard for customers, runners, and admins.

---

## Table of Contents

1. [Project Structure](#project-structure)
2. [Tech Stack & Dependencies](#tech-stack--dependencies)
3. [Routing & Pages](#routing--pages)
4. [Layouts](#layouts)
5. [State Management](#state-management)
6. [API Client](#api-client)
7. [Components](#components)
8. [Styling](#styling)
9. [Real-time (WebSockets)](#real-time-websockets)
10. [Environment Variables](#environment-variables)

---

## Project Structure

```
errandly/web/
├── src/
│   ├── app/
│   │   ├── layout.tsx               # Root layout (Providers wrapper)
│   │   ├── page.tsx                 # Landing page
│   │   ├── globals.css              # Tailwind base styles
│   │   ├── providers.tsx            # ReactQuery + toast providers
│   │   ├── auth/
│   │   │   ├── login/page.tsx       # Login page
│   │   │   └── register/page.tsx    # Registration page (role select)
│   │   ├── customer/
│   │   │   ├── layout.tsx           # Customer layout + sidebar
│   │   │   ├── dashboard/page.tsx   # Customer dashboard
│   │   │   ├── errands/
│   │   │   │   ├── page.tsx         # Errands list
│   │   │   │   └── new/page.tsx     # Multi-step errand creation
│   │   │   ├── wallet/page.tsx      # Wallet management
│   │   │   ├── messages/page.tsx    # Conversations
│   │   │   └── profile/page.tsx     # Profile settings
│   │   ├── runner/
│   │   │   ├── layout.tsx           # Runner layout + sidebar
│   │   │   ├── dashboard/page.tsx   # Runner dashboard (online toggle)
│   │   │   └── earnings/page.tsx    # Earnings & withdrawals
│   │   └── admin/
│   │       ├── layout.tsx           # Admin layout + sidebar
│   │       ├── dashboard/page.tsx   # Admin dashboard (charts)
│   │       ├── users/page.tsx       # User management
│   │       ├── runners/page.tsx     # Runner management
│   │       ├── kyc/page.tsx         # KYC review queue
│   │       ├── errands/page.tsx     # All errands
│   │       ├── disputes/page.tsx    # Dispute resolution
│   │       ├── finance/page.tsx     # Financial overview
│   │       ├── reports/page.tsx     # Analytics & reports
│   │       ├── live-map/page.tsx    # Real-time runner map
│   │       ├── notifications/page.tsx # Notification management
│   │       └── settings/page.tsx    # Platform settings
│   ├── components/
│   │   └── admin/
│   │       └── LiveMap.tsx          # Leaflet map for admin live view
│   ├── lib/
│   │   └── api.ts                   # Axios API client
│   └── store/
│       └── authStore.ts             # Zustand auth state
├── tailwind.config.ts               # Tailwind + Errandly brand colors
├── next.config.ts
├── tsconfig.json
├── postcss.config.js
└── .env.example
```

---

## Tech Stack & Dependencies

| Package | Purpose |
|---------|---------|
| `next` 14.2 | App Router, SSR/SSG, API routes |
| `react` 18 | UI framework |
| `@tanstack/react-query` 5 | Server state, caching, loading states |
| `zustand` 4 | Client-side auth state |
| `axios` | HTTP client |
| `react-hook-form` + `zod` | Form management + validation |
| `@hookform/resolvers` | Zod resolver for react-hook-form |
| `tailwindcss` 3.4 | Utility-first CSS |
| `lucide-react` | Icon library |
| `recharts` | Charts on admin dashboard |
| `leaflet` + `react-leaflet` | Interactive map |
| `pusher-js` | Pusher Channels client for real-time |
| `react-hot-toast` | Toast notifications |
| `date-fns` | Date formatting |
| `@radix-ui/*` | Accessible headless UI primitives |
| `clsx` + `tailwind-merge` | Conditional class merging |
| `class-variance-authority` | Component variant management |
| `next-auth` | Session management helper |

---

## Routing & Pages

### Public Pages

| Route | Page | Description |
|-------|------|-------------|
| `/` | `app/page.tsx` | Marketing landing page with hero, features, how it works, CTAs |
| `/auth/login` | `app/auth/login/page.tsx` | Unified login form; redirects by role after auth |
| `/auth/register` | `app/auth/register/page.tsx` | Role selection (customer / runner) then registration form |

---

### Customer Pages (`/customer/*`)

Protected by auth check; redirects to login if unauthenticated.

| Route | Description |
|-------|-------------|
| `/customer/dashboard` | Welcome card, active errand count, wallet balance snapshot, recent errand list |
| `/customer/errands` | Paginated errands list with status filter chips |
| `/customer/errands/new` | **Multi-step errand creation wizard:** Step 1: Category & urgency → Step 2: Pickup & destination addresses with map → Step 3: Item details & instructions → Step 4: Budget & review → Step 5: Confirmation |
| `/customer/wallet` | Balance display, fund wallet button, transaction history table |
| `/customer/messages` | Conversations list; opens chat window per errand |
| `/customer/profile` | Name, email, phone, address, emergency contact, saved addresses |

---

### Runner Pages (`/runner/*`)

| Route | Description |
|-------|-------------|
| `/runner/dashboard` | Online/offline toggle, available errands near them, active errand card |
| `/runner/earnings` | Wallet balance, total earned, withdrawal form, transaction history |

---

### Admin Pages (`/admin/*`)

Requires `admin` or `verification_officer` role.

| Route | Description |
|-------|-------------|
| `/admin/dashboard` | KPI cards (users, runners, errands, revenue), line/bar charts via Recharts |
| `/admin/users` | User table with search, filters, suspend/blacklist actions |
| `/admin/runners` | Runner table with trust score, KYC status, approve/suspend actions |
| `/admin/kyc` | KYC queue: document preview, approve/reject/request-resubmission buttons |
| `/admin/errands` | All errands with status timeline, reassign & cancel actions |
| `/admin/disputes` | Open dispute list, evidence viewer, resolution form |
| `/admin/finance` | Escrow overview, all wallet transactions, force refund/release |
| `/admin/reports` | Revenue, errand, user, incident, fraud reports + CSV/PDF export |
| `/admin/live-map` | Leaflet map showing all active runners + their current errand |
| `/admin/notifications` | Broadcast notifications to all users or a specific role |
| `/admin/settings` | Platform configuration (commission rate, min amount, service areas) |

---

## Layouts

### `app/layout.tsx` — Root Layout
- Wraps the entire app with `<Providers>`.
- Applies global Tailwind styles.
- Sets meta tags and font (Inter).

### `app/providers.tsx`
- `QueryClientProvider` (TanStack React Query)
- `Toaster` (react-hot-toast)

### `app/customer/layout.tsx` — Customer Layout
- Left sidebar with navigation: Dashboard, Errands, Wallet, Messages, Profile.
- Top bar showing wallet balance and notification bell.
- Auth guard: redirects to `/auth/login` if not authenticated.

### `app/runner/layout.tsx` — Runner Layout
- Left sidebar: Dashboard, Earnings.
- Top bar with online status indicator.
- Auth guard + role guard.

### `app/admin/layout.tsx` — Admin Layout
- Wider sidebar: Dashboard, Users, Runners, KYC, Errands, Disputes, Finance, Reports, Live Map, Notifications, Settings.
- Role guard: `admin` or `verification_officer`.

---

## State Management

### `src/store/authStore.ts` — Zustand

```ts
interface AuthStore {
  user: User | null
  token: string | null
  isAuthenticated: boolean
  role: 'customer' | 'runner' | 'admin' | 'verification_officer' | null
  login: (user: User, token: string) => void
  logout: () => void
  updateUser: (updates: Partial<User>) => void
}
```

- Token is persisted to `localStorage`.
- `role` is derived from the user's Spatie role returned by `/api/auth/me`.
- All API calls inject the token via Axios interceptor.
- On app load, the auth store re-hydrates from localStorage and validates the token with `/api/auth/me`.

---

## API Client

### `src/lib/api.ts`

Built on Axios with:
- Base URL: `NEXT_PUBLIC_API_URL` env variable.
- Request interceptor: automatically attaches `Authorization: Bearer {token}`.
- Response interceptor: on 401, clears auth state and redirects to login.

**Exported API namespaces:**

| Namespace | Methods |
|-----------|---------|
| `auth` | `login`, `register`, `logout`, `me`, `updateProfile`, `changePassword` |
| `errands` | `list`, `create`, `get`, `update`, `cancel`, `confirmCompletion`, `available`, `accept`, `reject`, `submitProof`, `panic` |
| `wallet` | `get`, `transactions`, `fund`, `verifyPayment` |
| `messages` | `conversations`, `get`, `send`, `markRead` |
| `ratings` | `submit`, `myRatings` |
| `disputes` | `list`, `create`, `get`, `addEvidence` |
| `notifications` | `list`, `markRead`, `markAllRead`, `delete` |
| `kyc` | `status`, `submit`, `resubmit` |
| `tracking` | `get`, `updateLocation` |
| `admin.users` | `list`, `get`, `suspend`, `restore`, `blacklist`, `delete` |
| `admin.runners` | `list`, `get`, `approve`, `suspend`, `adjustScore` |
| `admin.kyc` | `list`, `pending`, `get`, `approve`, `reject`, `requestResubmission` |
| `admin.errands` | `list`, `get`, `reassign`, `cancel`, `timeline` |
| `admin.finance` | `overview`, `escrow`, `transactions`, `refund`, `release`, `freeze`, `unfreeze` |
| `admin.disputes` | `list`, `get`, `assign`, `resolve`, `close` |
| `admin.reports` | `revenue`, `errands`, `users`, `incidents`, `fraud`, `export` |
| `admin.settings` | `get`, `update`, `serviceAreas`, `storeArea`, `updateArea`, `deleteArea` |

---

## Components

### `components/admin/LiveMap.tsx`

A `react-leaflet` map that:
- Fetches runner positions from `/api/admin/live-map`.
- Renders a marker per active runner with a popup showing their name, errand title, and trust score.
- Uses the Errandly orange accent for active runner markers.
- Refreshes every 30 seconds.

---

## Styling

### Tailwind Configuration (`tailwind.config.ts`)

**Brand colour palette:**

```ts
colors: {
  primary: {
    DEFAULT: '#FF6B00',   // Errandly orange
    dark:    '#E05A00',
    light:   '#FF8C33',
  },
  navy: {
    DEFAULT: '#0A1628',   // Errandly navy
    light:   '#1a2d4d',
    dark:    '#060e1a',
  },
}
```

Font family: `Inter` (via Google Fonts + next/font).

---

## Real-time (WebSockets)

The web client subscribes to Pusher Channels using `pusher-js`.

**Channels subscribed:**

| Page | Channel | Events listened |
|------|---------|----------------|
| Errand detail | `errand.{id}` | `ErrandStatusUpdated`, `RunnerLocationUpdated`, `NewMessage` |
| Messages | `errand.{id}` | `NewMessage` |
| Admin dashboard | `admin` | `PanicTriggered`, `ErrandStatusUpdated` |
| Admin live map | `admin` | `RunnerLocationUpdated` |

Pusher credentials are configured via `NEXT_PUBLIC_PUSHER_*` environment variables.

---

## Environment Variables

```env
NEXT_PUBLIC_API_URL=http://localhost:8000/api
NEXT_PUBLIC_PUSHER_APP_KEY=
NEXT_PUBLIC_PUSHER_CLUSTER=mt1
NEXT_PUBLIC_PUSHER_HOST=
NEXT_PUBLIC_PUSHER_PORT=443
NEXT_PUBLIC_PUSHER_SCHEME=https
NEXT_PUBLIC_APP_NAME=Errandly
```
