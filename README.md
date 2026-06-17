# The Nest — *Come Home to Yourself*

A personal sanctuary for nervous system care and emotional well-being, built in
Flutter for **iOS, Android, and web** from a single codebase.

> Live demo: **https://nestwithin.mrrado.com**

The Nest is not a yoga or meditation library. It asks one question —
*What do you need right now?* — and meets you there in a few minutes. See
[`docs/nest_within_app_vision.md`](docs/nest_within_app_vision.md) for the full
vision.

## Features

- **What do you need right now?** — eight feeling-led needs (Calm, Sleep, Stress,
  Mood, Focus, Reconnect, Energy, Supported), each opening a short set of
  recommended practices.
- **Guided practices** — paced breath, meditation, sound, movement, and
  reflection experiences (2/5/10 min) with an animated breathing orb.
- **Hold Me For Five Minutes** — the emotional heart: an immersive, soothing
  sanctuary for moments of overwhelm.
- **Daily check-in** — *How are you arriving today?* — feeds the **Nest
  Prescription**, gentle pattern-based insights ("You've been arriving anxious…").
- **Together** — anonymous community reflections. No likes, no followers, just
  a quiet *"Me too."*
- **Monthly theme** — *Santosha · Contentment* with teaching, journal prompt,
  and themed practices.
- **The Nest (studio)** — class schedules, workshops, livestreams, membership.

Everything is **local-first** (via `shared_preferences`) and works fully
offline. No accounts, no backend, no secrets.

## Brand

- Palette and logo derived from *the nest collaborative* (`images/logo.png`).
- The wellness iconography in-app is sliced from `images/icons.jpg` into 24
  transparent, brand-blue PNGs under `assets/wellness_icons/`
  (regenerate with the PIL snippet in the project history if the sheet changes).

## Develop

```bash
flutter pub get
flutter run                 # phone / emulator
flutter run -d chrome       # web
dart run flutter_launcher_icons   # regenerate app/web icons from the logo
flutter analyze && flutter test
```

## Versioning

Single source of truth is [`version.json`](version.json). Run
`tool/gen-version.sh` to regenerate `lib/version.dart` and sync `pubspec.yaml`.

## Deploy (web → VPS)

```bash
./deploy/deploy-web.sh
```

Builds the web release, ships it to the VPS, installs the nginx vhost
([`deploy/nginx/nestwithin.conf`](deploy/nginx/nestwithin.conf)), and obtains a
Let's Encrypt cert for `nestwithin.mrrado.com`. Override `HOST` / `DOMAIN` /
`WEBROOT` via environment variables. Idempotent — safe to re-run.

## Backend (`server/`)

A small **Node + Express + SQLite** API ([`server/`](server/)) provides accounts
(bcrypt + JWT), email confirmation & password reset via **Mailgun**, activity
sync, and the cross-user community stats (most-loved activities + most-active
leaderboard, honoring the Anonymous opt-out). It's served same-origin at
`https://nestwithin.mrrado.com/api` (the web vhost proxies `/api` → the Node
service on `127.0.0.1:8091`), so there's no extra domain, cert, or CORS.

The Flutter client ([`lib/data/api_client.dart`](lib/data/api_client.dart)) talks
to it **best-effort**: signup/login/stats use the API when reachable and fall
back to local-only/seeded data when offline, so the app always works.

```bash
./deploy/deploy-api.sh     # installs Node, ships server/, runs it under systemd
./deploy/deploy-web.sh     # (re)installs the nginx /api route
```

`deploy-api.sh` writes a starter `/etc/nest-api.env` on first run. **Email runs
in STUB mode (logged, not sent) until Mailgun is configured** — set
`MAILGUN_API_KEY`, `MAILGUN_DOMAIN`, `MAILGUN_REGION`, and `MAIL_FROM` in that
file (see [`server/.env.example`](server/.env.example)) and restart:
`systemctl restart nest-api`.
