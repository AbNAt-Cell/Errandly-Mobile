# Errandly Web

Next.js admin and customer web app for [Errandly](https://github.com/JayEs23/errandly).

## Requirements

- Node.js 18+
- npm or yarn
- Errandly API running (Laravel backend)

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
NEXT_PUBLIC_APP_NAME=Errandly
```

## Development

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Production build

```bash
npm run build
npm run start
```

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Development server |
| `npm run build` | Production build |
| `npm run start` | Run production server |
| `npm run lint` | ESLint |

## Backend

This repo is **frontend only**. Point `NEXT_PUBLIC_API_URL` at your Errandly Laravel API (not included in this repository).
