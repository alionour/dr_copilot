# Dr AI (dr_copilot) — Agent Guide

## Project

Cross-platform (Android/iOS/Web/Windows/macOS/Linux) Flutter clinic management app with AI copilot.  
Version 1.0.7+1 — SDK `>=3.5.0 <5.0.0`.

## Key commands

| Action | Command |
|---|---|
| Run (all platforms) | `doppler run -- flutter run -d <platform>` |
| Analyze | `flutter analyze` |
| Test all | `flutter test` |
| Test unit/widget/integration | `dart test_runner.dart unit|widget|integration` |
| Test single feature | `dart test_runner.dart feature <name>` |
| Coverage | `flutter test --coverage` |
| Codegen (freezed, json_serializable) | `dart run build_runner build` |
| App icons | `dart run flutter_launcher_icons` |
| MSIX package (Windows) | `dart run msix` |
| Backend deploy | `cd backend && doppler run -- npx sls deploy` |
| Firestore rules deploy | `firebase deploy --only firestore:rules` |
| Firebase hosting deploy | triggered by tag `v*` or `web-v*` CI |

**CI order**: `flutter pub get` → `flutter analyze` → `flutter test` → `flutter build <platform>`  
CI uses Flutter **3.24.5** (stable), defined in `.github/workflows/flutter_ci.yaml`.

## Secrets & env

- **Always** `doppler run -- <command>` — secrets come from Doppler, never from `.env`.
- Doppler config: project `drcopilot`, config `prd` (see `doppler.yaml`).
- Firebase `google-services.json` / `GoogleService-Info.plist` are local-only, gitignored.
- Backend needs `FIREBASE_SERVICE_ACCOUNT` as a single-line JSON string env var.

## Architecture

- **Clean Architecture** per feature: `domain/`, `data/`, `presentation/` under `lib/src/features/<name>/`.
- **31 features** in `lib/src/features/` — appointments, auth, booking, calendar, charts, clinical_reports, copilot_chat, departments, doctors, financials, home, inventory, invitations, kiosk, medical_files, medications, navigation_side, notifications, patients, presentation, recycle_bin, settings, staff, subscription, support_chat, tasks, team_chat, teams, telemedicine.
- **DI**: GetIt singleton (`sl`). Each feature has `<name>_injections.dart` wired via `lib/src/core/injections.dart`.
- **State**: BLoC + Provider.
- **Routing**: go_router in `lib/src/core/router/routing_config.dart`.
- **Localization**: `easy_localization` with JSON files in `assets/translations/` (en, ar, de, es, fr). Add new lang: create JSON + update `pubspec.yaml`.
- **Fonts**: Poppins by default, Tajawal for Arabic (switched in `app.dart`).

## Notable quirks

- **Local package patches**: `speech_to_text_windows` and `flutter_tts` are overridden via `dependency_overrides` to local `packages/` paths.
- **Windows Firestore**: `persistenceEnabled: false` is required (`lib/main.dart:69`) to avoid platform channel threading crash.
- **Multi-window**: `desktop_multi_window` support — entry mode `main.dart` with `args.firstOrNull == 'multi_window'`.
- **Freezed + json_serializable** codegen via `build.yaml`; generated files are committed (no `.g.dart` in gitignore).
- **Shorebird** OTA updates on startup (`lib/main.dart:112`).
- **ClinicalReports** migration from Quill Delta to HTML runs on every startup (`lib/main.dart:117`).
- **MSIX config** in `pubspec.yaml` for Windows Store deployment.

## Backend

- Express.js serverless app in `backend/`, deployed as AWS Lambda via Serverless Framework v3.
- Routes: `POST /invitations` (SES email), `POST /notifications` (FCM push), `POST /errors`, `POST /subscriptions`.
- Cron: `cron/reminders.js` runs daily via CloudWatch Events.
- Deploy: `cd backend && doppler run -- npx sls deploy` (esbuild bundling).

## Tests

- Unit tests in `test/unit/`, widget tests in `test/widget/`.
- Integration (screenshot) tests in `integration_test/`.
- Custom runner `test_runner.dart` wraps `flutter test` with scoped paths.
- Tests that require Firebase services use `fake_cloud_firestore` and `firebase_auth_mocks`.
- `--tags=smoke` and `--tags=regression` supported by the runner.

## Docs of interest

- `docs/FIRESTORE_SCHEMA.md` — auto-generated schema reference.
- `docs/CHANGELOG.md` — release notes.
- `backend/DEPLOYMENT.md` — API endpoint and deployment details.
- `backend/README.md` — local dev setup for backend.
- `firestore.rules` — comprehensive security rules with role-based permissions.
