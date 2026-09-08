# DOOYN Web

Next.js admin and customer web app for [DOOYN](https://github.com/JayEs23/errandly).

## Requirements

- Node.js 18+
- npm or yarn
- DOOYN API running (Laravel backend)

## Setup

```bash
npm install
cp .env.example .env.local
```

Edit `.env.local`:

```env
NEXT_PUBLIC_API_URL=http://localhost:8000/api
NEXT_PUBLIC_PUSHER_KEY=
NEXT_PUBLIC_PUSHER_CLUSTER=mt1
NEXT_PUBLIC_GOOGLE_MAPS_KEY=
NEXT_PUBLIC_APP_NAME=DOOYN
```

## Development

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Page layout (12px side inset)

Page shells use a **12px** left/right inset only (`--page-gutter-x`). Do **not** add larger side gutters or centered narrow columns.

- `page-container` / `page-gutter` = full width + 12px horizontal inset
- Internal padding on cards/buttons is fine
- Vertical spacing is fine

## Typography

- **Headlines** (`h1`–`h6`, `font-headline`, `font-display`, display/currency sizes): **Space Grotesk**
- **Body & labels** (`font-sans`, `font-body`, `font-label`, body/label sizes): **Plus Jakarta Sans**
- **Accent** (occasional CTAs / pills): **Poppins** via `font-poppins`

## Branding

User-facing product name: **DOOYN** (`NEXT_PUBLIC_APP_NAME`).

Internal package/repo paths may still say `errandly` (API package name, CSS utility prefixes like `errandly-btn`). Those are technical identifiers and are unchanged unless a full rename is requested.

The app uses **class-based** dark mode via [`next-themes`](https://github.com/pacocoursey/next-themes).

- Default: **system** (follows OS preference)
- Toggle cycles: light → dark → system
- Controls: landing nav/footer, customer/runner/admin headers, login page
- Tokens live in `src/app/globals.css` (`:root` / `.dark`) and map to Tailwind (`bg-background`, `bg-card`, `bg-shell`, `bg-hero`, `bg-band`, etc.)
- Preference is stored in `localStorage` under `theme`

## Production with Docker / Dokploy

### Dokploy Compose (recommended)

Full stack (`api` + `queue` + `scheduler` + `redis` + `web`) from one Compose file:

- Compose: [`../docker-compose.dokploy.yml`](../docker-compose.dokploy.yml)
- Env template: [`../.env.dokploy.example`](../.env.dokploy.example)
- Web image: [`Dockerfile`](./Dockerfile) (`output: 'standalone'`)

In Dokploy: Compose service **`errandlyapp`** → path `./errandly/docker-compose.dokploy.yml` (monorepo) → Domains → **web** port `3000`.

`NEXT_PUBLIC_*` vars are **build-time**. Set them in Dokploy env before the first web build; change → rebuild.

### Local / Vercel

```bash
npm install
cp .env.example .env.local
# edit NEXT_PUBLIC_API_URL to your API
npm run build
npm run start
```

Open [http://localhost:3000](http://localhost:3000).

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Development server |
| `npm run build` | Production build |
| `npm run start` | Run production server |
| `npm run lint` | ESLint |

## Backend

This repo is **frontend only**. Point `NEXT_PUBLIC_API_URL` at your DOOYN Laravel API (not included in this repository).
