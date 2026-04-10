# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> A parent `CLAUDE.md` at `/home/robotics1025/projects/CLAUDE.md` covers this app in the context of the full EventBridge workspace (backend + mobile + Natalie AI). This file adds app-specific detail.

## What this app is

EventBridge — a Flutter (mobile/web) client for an AI-driven vendor-matching platform for event planning. A user picks a role (`CUSTOMER` or `VENDOR`) and the app renders two essentially separate product experiences inside the same binary.

Backend is the sibling `eventbridge/` project deployed to AWS Lambda. Base URL is hardcoded at `lib/core/network/api_service.dart:13` → `https://3nqhgc5y2l.execute-api.us-east-1.amazonaws.com/dev`. Product rules and user flow live in `docs/eventbridge_user_flow.md`.

## Commands

```bash
flutter pub get
flutter run                    # device/emulator
flutter run -d chrome          # web
flutter test                   # all tests
flutter test test/widget_test.dart   # single file
flutter analyze                # lints (flutter_lints)

# Codegen — required after touching any Freezed / Riverpod / Retrofit annotated file
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch    # keep running during dev
```

`.g.dart` and `.freezed.dart` files are generated — never hand-edit them.

## Architecture

**Clean architecture is only fully applied in `features/auth` and `features/matching`.** Those features have `data/` (repository impls + Retrofit clients), `domain/` (contracts + usecases), and `presentation/` (screens + Riverpod controllers), with the dependency rule `presentation -> domain <- data`.

The other features are pragmatic / legacy-shaped:
- `features/home/` — role-aware home screens (customer vs vendor landing)
- `features/vendors_screen/` — the entire vendor-side product (leads, bookings, portfolio, packages, availability, subscription, chat, settings). Screens live flat at the feature root; there is no `presentation/` folder here. Several `*_improved.dart` variants exist alongside originals — check `app_router.dart` to see which is actually wired up before editing.
- `features/messaging/` — real-time chat (Socket.IO) used by both roles
- `features/shared/` — cross-role widgets (e.g. customer bottom navbar)

When adding a new feature, prefer the `auth` / `matching` layout. When touching `vendors_screen`, match what's already there rather than forcing clean-architecture onto it.

### Routing & role gating

`lib/core/router/app_router.dart` is the single source of truth for navigation. It defines three mutually-exclusive route groups:

- `_publicRoutes` — reachable without a token
- `_vendorOnlyRoutes` — requires a stored `VENDOR` role
- `_customerOnlyRoutes` — requires a stored `CUSTOMER` role

The redirect guard reads the token and role from `StorageService` (backed by `flutter_secure_storage` + Hive). Any new screen must be added to the correct group or it will silently redirect to `/login`. Role is decided at signup and drives which home screen, bottom nav, and feature set the user ever sees.

### Networking layers (know which to use)

There are three overlapping HTTP surfaces — this is intentional but easy to misuse:

1. **`lib/core/network/network_service.dart`** — configures the shared `Dio` instance (interceptors, logging, auth header injection). Start here if you're changing headers/interceptors.
2. **`lib/core/network/api_service.dart`** — a hand-written singleton with methods like `login()`, `signup()`, etc. Hardcodes the Lambda base URL. Used by the older/legacy features.
3. **`features/<feature>/data/*_api.dart`** — Retrofit-generated clients (`*_api.g.dart`). Used by the clean-architecture features. Add new endpoints here when working inside `auth` or `matching`.

Also: `lib/core/network/websocket_service.dart` for the API Gateway WebSocket channel, and `socket_io_client` for the Socket.IO chat in `features/messaging/`.

### State, storage, and real-time

- **State:** Riverpod 3 with code generation (`@riverpod`). Providers live next to the screens that use them in `presentation/`.
- **Storage:** `StorageService` wraps both `flutter_secure_storage` (tokens, credentials) and Hive (general cache). It's initialized in `main.dart` before `runApp` — do not read storage before `StorageService().init()` has completed.
- **Firebase:** Core + Auth + Firestore + Messaging + Analytics + Storage, all initialized in `main.dart`. FCM background handler is registered before `runApp` but skipped on web (`kIsWeb` guard). Firebase config lives in `lib/firebase_options.dart` (generated) and `firebase.json`.
- **Google Sign-In** is initialized early in `main.dart` with a hardcoded web client ID so `renderButton()` works on the web build.

### Navigation within the app

Use `go_router` (`context.go(...)` / `context.push(...)`). Do not introduce `Navigator.push` with `MaterialPageRoute` for new screens — it bypasses the auth/role guard in `app_router.dart`.

## Gotchas

- **Two home screens, two navbars.** Customer and vendor have separate entry points (`/customer-home` vs `/vendor-home`) and separate bottom navigation. Changes to "the home screen" usually need to be made in both places.
- **Duplicate `*_improved.dart` screens** in `features/vendors_screen/` are real code, not backups. The router picks one; grep `app_router.dart` before assuming which is live.
- **Root-level scripts** (`check_db.js`, `check_leads_db.js`, `migrate_leads.sql`, `restructure_db.*`, `test_api.js`) are one-off dev tools that talk to the backend's Postgres directly. They are not part of the Flutter build and are not wired to anything — treat them as scratch scripts.
- **`functions/`** is a Firebase Cloud Functions project (separate `package.json`) — unrelated to the Flutter `flutter/` tooling. Deploy via the Firebase CLI, not via Flutter.
- **iOS CI is fragile around CocoaPods.** Recent commits (`fix(ios-ci): ...`) pin pods and force CDN. If iOS build fails in CI with pod resolution errors, check those commits before improvising.
- When a Retrofit or Riverpod change doesn't seem to take effect, you almost certainly forgot to re-run `build_runner`.
