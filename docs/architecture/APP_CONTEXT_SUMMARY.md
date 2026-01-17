## Doppler Task Usage in VS Code

To run your Flutter app or scripts with Doppler secrets injected using VS Code tasks, ensure your `.vscode/tasks.json` includes a task like this:

```json
{
  "label": "doppler-run",
  "type": "shell",
  "command": "doppler run -- flutter run -d windows",
  "problemMatcher": []
}
```

**How it works:**
- This task will run `flutter run -d windows` with Doppler secrets injected into the environment.
- You can change the command after `--` to run any script or tool, for example:
  - `doppler run -- dart lib/scripts/onboarding_multi_clinic_migration.dart`
  - `doppler run -- flutter test`

**Note:** Doppler requires a command after `--`. If you omit the command, you will get an error like:
> Error: requires at least 1 arg(s), received 0

Update your `tasks.json` as needed for your workflow.
# App Context Feature Summary (as of 2025-05-16)

> This document provides a comprehensive overview of the features available in the Dr Copilot app, as well as a clear summary of any missing or incomplete features. Last reviewed: **2025-05-16**

---

## 🌟 Features Overview

| Category                | Details                                                                                       |
|------------------------ |---------------------------------------------------------------------------------------------|
| **Authentication**      | Google Sign-In, Supabase integration, secure token storage                                   |
| **Navigation**          | Side menu, keyboard navigation, deep linking, go_router                                      |
| **Calendar**            | Google Calendar sync, event creation/editing, reminders                                      |
| **Patients**            | CRUD for patient records, search, medical history                                            |
| **Appointments/Sessions/Evaluations** | Scheduling, reminders, status tracking, session/evaluation management         |
| **Financials**          | Billing, transactions, and financial management (fully implemented)                          |
| **Charts & Reports**    | Visual reports, analytics dashboards, and charting (fully implemented)                       |
| **Copilot Chat**        | AI-powered chat (Vertex AI, GPT, Gemini), file/image upload, multi-model selection           |
| **Notifications**       | In-app notifications                                                                         |
| **Settings**            | Theme, language, privacy, account settings                                                   |
| **Security**            | Secure storage, Doppler, flutter_secure_storage                                              |
| **Localization**        | English & Arabic, RTL support, easy_localization                                             |
| **OTA Updates**         | Seamless over-the-air updates via Shorebird                                                  |
| **Accessibility**       | Some mention in docs, but not fully detailed                                                 |
| **Testing**             | Unit, widget, and integration test support                                                   |
| **Account Page**        | User account/profile management (fully implemented)                                           |

---

## 🚩 Missing or Incomplete Features

| Feature                | Status/Notes                                                                                  |
|------------------------|----------------------------------------------------------------------------------------------|
| **Push Notifications** | In-app notifications present, but push notification (e.g., FCM) setup is not confirmed        |
| **Analytics**          | No implementation of Firebase Analytics or similar usage tracking found                       |
| **Error Reporting**    | No integration with Sentry, Crashlytics, or similar error reporting tools                     |
| **Accessibility**      | Mentioned in docs, but no explicit code for screen reader support, ARIA roles, etc.           |
| **Help/Support Page**  | Route exists, but actual implementation or content is not shown                               |
| **Admin/Role Management** | No evidence of user roles, permissions, or admin features                                 |
| **Backup/Export**      | No features for data backup, export, or import are found                                      |

---

## 📋 Feature Matrix

| Feature Group         | Present | Notes/Details |
|----------------------|:-------:|---------------|
| Authentication       |   ✅    | Google, Supabase, secure storage |
| Navigation           |   ✅    | Side menu, keyboard, deep linking |
| Calendar             |   ✅    | Google Calendar sync, CRUD |
| Patients             |   ✅    | CRUD, search, history |
| Appointments         |   ✅    | Sessions, evaluations, reminders |
| Financials           |   ✅    | Billing, transactions |
| Charts & Reports     |   ✅    | Visual analytics, dashboards |
| Copilot Chat         |   ✅    | AI chat, file/image upload |
| Notifications        |   ⚠️    | In-app only, push not confirmed |
| Settings             |   ✅    | Theme, language, privacy |
| Security             |   ✅    | Secure storage, Doppler |
| Localization         |   ✅    | English, Arabic, RTL |
| OTA Updates          |   ✅    | Shorebird |
| Accessibility        |   ⚠️    | Docs mention, code incomplete |
| Testing              |   ✅    | Unit, widget, integration |
| Account Page         |   ✅    | User profile present |
| Analytics            |   ❌    | Not implemented |
| Error Reporting      |   ❌    | Not implemented |
| Help/Support         |   ⚠️    | Route exists, content unclear |
| Admin/Roles          |   ❌    | Not implemented |
| Backup/Export        |   ❌    | Not implemented |

---

> **Legend:**
> - ✅ Fully implemented
> - ⚠️ Partially implemented or unclear
> - ❌ Not implemented

---

_Last updated: 2025-05-16  (Windows, pwsh)_
