

<div align="center">
  <img src="assets/svg/logo.svg" alt="Dr Copilot Logo" width="120"/>
  <h1>🩺 Dr Copilot</h1>
  <p><b>Your all-in-one clinic management & AI assistant app</b><br/>
  <em>Empowering doctors to manage clinics, appointments, finances, and more — with AI at your side!</em></p>

  <!-- Badges -->
  <p>
    <a href="https://github.com/alionour22/dr_copilot/actions/workflows/flutter_ci.yaml">
      <img src="https://github.com/alionour22/dr_copilot/actions/workflows/flutter_ci.yaml/badge.svg" alt="CI Status"/>
    </a>
    <a href="https://github.com/alionour22/dr_copilot/blob/main/LICENSE">
      <img src="https://img.shields.io/github/license/alionour22/dr_copilot?style=flat" alt="License"/>
    </a>
    <a href="https://flutter.dev/">
      <img src="https://img.shields.io/badge/Flutter-3.19-blue?logo=flutter&logoColor=white" alt="Flutter"/>
    </a>
    <img src="https://img.shields.io/badge/Platform-Android%20|%20iOS%20|%20Web%20|%20Desktop-blueviolet" alt="Platforms"/>
    <a href="https://shorebird.dev/">
      <img src="https://img.shields.io/badge/OTA-Shorebird-orange?logo=bird" alt="OTA"/>
    </a>
  </p>
</div>

---




## 🚀 Quick Start

```pwsh
# 1. Clone the repo
git clone https://github.com/alionour22/dr_copilot.git
cd dr_copilot

# 2. Install dependencies
flutter pub get

# 3. Set up Firebase and Doppler (see Setup Instructions below)

# 4. Run the app
doppler run -- flutter run
```

---

## ✨ Features

<div align="center">
  <img src="docs/screenshots/dashboard.gif" alt="Dr Copilot Dashboard Demo" width="600"/>
  <br/>
  <em>✨ See your clinic at a glance! (Replace with your own GIFs/screenshots)</em>
</div>
---

## ❓ FAQ

<details>
<summary><strong>Expand for common questions</strong></summary>

**Q: The app won't build or run!**
A: Make sure you have Flutter, Doppler, and Firebase set up as described. Check your secrets and that you have the correct `google-services.json` and `GoogleService-Info.plist` files.

**Q: How do I add a new language?**
A: Add a new JSON file in `assets/translations/` and update `pubspec.yaml`.

**Q: How do I reset my theme or language?**
A: Go to the Settings page and choose your preferred theme or language.

**Q: Where are my secrets stored?**
A: All secrets are managed securely via Doppler and never stored in source code.

**Q: How do I get support?**
A: See the Contact & Support section below.

</details>

---

## ♿ Accessibility Statement

Dr Copilot is designed with accessibility in mind:
- Uses semantic widgets and proper labeling for screen readers.
- Supports high-contrast themes and large fonts.
- Keyboard navigation is available throughout the app (including side menu).
- RTL support for Arabic.

If you encounter any accessibility issues, please [contact support](#contact--support) or open an issue.

---

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for release notes and version history.

---

## 📬 Contact & Support

- **Email:** alionour22@gmail.com
- **GitHub Issues:** [Open an issue](https://github.com/alionour22/dr_copilot/issues)
- **Docs:** See this README and the `/docs` folder for more help.

---

## 🙏 Credits & Acknowledgements

- Built by Ali Nour and contributors.
- Thanks to the Flutter, Firebase, and open source communities.
- Major packages: Flutter, Bloc, Provider, Easy Localization, GetIt, go_router, Shorebird, Doppler, Syncfusion Charts, Google Fonts, and more.
- Special thanks to all testers, translators, and users who provided feedback.

---

---

## 🏗️ Architecture & Core Concepts

Dr Copilot is built with a modular, scalable architecture using best practices from modern Flutter development:

- **Clean Architecture**: Each feature (e.g., Patients, Financials, Copilot) is organized into domain, data, and presentation layers for maintainability and testability.
- **State Management**: Uses BLoC (Business Logic Component) and Provider for robust, reactive state management across the app.
- **Dependency Injection**: All services, repositories, and blocs are injected using [GetIt](https://pub.dev/packages/get_it) for loose coupling and easy testing. See `lib/src/core/injections.dart` and each feature's `*_injections.dart`.
- **Navigation**: Declarative, type-safe navigation is handled by [go_router](https://pub.dev/packages/go_router), with a side menu and keyboard navigation support for desktop/web.
- **Localization**: Multi-language support (English & Arabic) via [easy_localization](https://pub.dev/packages/easy_localization). All UI strings use translation keys. Add new languages by editing `assets/translations/`.
- **Theming**: Dynamic light/dark themes, with user preference stored securely. Uses [flex_color_scheme](https://pub.dev/packages/flex_color_scheme) and Google Fonts for a modern look.
- **Error Handling**: User-friendly error messages, snackbars, and error boundaries throughout the app. (Integrate Sentry/Crashlytics for production error reporting.)
- **Testing**: Unit, widget, and integration tests are supported. See `test/` for examples. Run tests with `flutter test`.
- **Security**: All secrets and tokens are managed via Doppler and [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage). No sensitive data is stored in plain text or in source code.
- **Analytics**: (Optional) Integrate Firebase Analytics or similar for usage tracking and insights.
- **Accessibility**: Designed with accessibility in mind. Test with screen readers and high-contrast themes.

---



### 🔐 Authentication <img src="https://img.icons8.com/color/32/google-logo.png" height="20"/> <img src="https://img.icons8.com/ios-filled/32/supabase.png" height="20"/>
- <strong>Google Sign-In</strong>: Sign in with your Google account.
- <strong>Supabase Integration</strong>: Secure, scalable user management.

### 🧭 Navigation <img src="https://img.icons8.com/ios-filled/32/compass.png" height="20"/>
- <strong>Side Menu</strong>: Effortless navigation between all app sections.
- <strong>Routing</strong>: Powered by <code>go_router</code> for seamless transitions.

### 📅 Calendar <img src="https://img.icons8.com/ios-filled/32/calendar.png" height="20"/>
- <strong>Calendar Page</strong>: Intuitive interface to view & manage all clinic appointments.

### 🔔 Notifications <img src="https://img.icons8.com/ios-filled/32/appointment-reminders.png" height="20"/>
- <strong>Notifications Page</strong>: Stay updated on important events and reminders.

### ⚙️ Settings <img src="https://img.icons8.com/ios-filled/32/settings.png" height="20"/>
- <strong>Settings Page</strong>: Personalize your experience — themes, language, and more.

### 🤖 Copilot <img src="https://img.icons8.com/ios-filled/32/robot-2.png" height="20"/>
- <strong>Copilot Page</strong>: Chat with Dr Copilot, your AI assistant for patient cases & clinic tasks.

### 🧑‍⚕️ Patients <img src="https://img.icons8.com/ios-filled/32/doctor-male.png" height="20"/>
- <strong>Patients Page</strong>: Manage patient info, medical history, and contacts.
- <strong>Patient Search</strong>: Fast search with smart suggestions.






### 💸 Financials <img src="https://img.icons8.com/ios-filled/32/money-bag.png" height="20"/>

<details>
<summary><strong>Click to expand full Financials feature details</strong> <span>💰📊</span></summary>

<br/>

<details>
<summary><strong>📦 Module Structure Map</strong> (click to expand)</summary>

<pre>
lib/src/features/financials/
├── data/
│   ├── remote/
│   │   ├── financials_firebase_api.dart      # Firestore CRUD for all financial data
│   │   └── abstract_financial_api.dart       # Abstract data source
│   └── ...
├── domain/
│   ├── models/
│   │   ├── transaction_model.dart            # Transaction entity
│   │   ├── goal_model.dart                   # Financial goal entity
│   │   ├── currency_profile_model.dart       # Currency profile entity
│   │   └── ...
│   └── usecases/
│       └── financials_usecase.dart           # Business logic for financials
├── presentation/
│   ├── bloc/
│   │   └── financials_bloc.dart              # BLoC for state/events
│   ├── pages/
│   │   ├── financials_page.dart              # Main entry for financials
│   │   ├── charts_page.dart                  # Charts UI
│   │   ├── reports_page.dart                 # Reports UI
│   │   ├── bills_and_payments_page.dart      # Bills management UI
│   │   └── goals_page.dart                   # Goals UI
│   └── widgets/
│       └── ...                               # Reusable UI components
</pre>
</details>

Dr Copilot provides a comprehensive <strong>Financials</strong> module to help clinics track, analyze, and manage all aspects of their finances. The module is structured into <strong>data</strong>, <strong>domain</strong>, and <strong>presentation</strong> layers for maintainability and testability.

#### Main Features
- <strong>📊 Financials Dashboard:</strong> At-a-glance summary of total revenue, expenses, session/evaluation counts, and recent transactions. Visual summary cards and charts.
- <strong>💵 Transactions Management:</strong> Add, edit, delete, and filter transactions by category (income, expenses, etc). Each transaction includes date, amount, category, and notes.
- <strong>📈 Charts & Analytics:</strong>
  - <strong>Year Selector:</strong> Instantly switch years with a stylish dropdown in the AppBar (just like the reports page).
  - <strong>Revenue vs. Expenses Chart:</strong> Interactive bar/line chart for monthly revenue and expenses. Toggle between bar and line views.
  - <strong>Revenue by Month:</strong> Toggleable bar/line chart for monthly revenue trends.
  - <strong>Expenses by Month:</strong> Toggleable bar/line chart for monthly expenses.
  - <strong>Sessions Revenue & Total Revenue:</strong> Dedicated charts for session revenue and total revenue, each with bar/line toggle.
  - <strong>Pie Chart:</strong> Instantly visualize the ratio of total revenue to expenses for the year.
  - <strong>🌍 Localized Labels:</strong> All chart/table labels and month names are fully translated.
- <strong>📑 Financial Reports:</strong>
  - <strong>Reports Page:</strong> Generate detailed reports for any year. View income/expenses tables, monthly breakdowns, and totals.
  - <strong>Year Selector:</strong> Dropdown in the AppBar to select report year, matching the charts page style.
  - <strong>Localized Tables:</strong> All headers, month names, and totals use translation keys for multi-language support.
- <strong>🧾 Bills & Payments:</strong> Track scheduled bills, due dates, and payment statuses. Manage recurring or one-time bills.
- <strong>🎯 Goals:</strong> Set and monitor financial goals for revenue, savings, or expense reduction. Visual progress indicators help you stay on track.
- <strong>💱 Currency Profiles:</strong> Manage multiple currencies for clinics in different regions. Set default currency and view all financials in your preferred currency.
- <strong>🔒 Security & Permissions:</strong> All financial data is securely managed and access is restricted to authorized users.
- <strong>🌐 Localization:</strong> The entire financials module supports English and Arabic, with all UI elements and data labels translated.

#### Layered Structure & Key Classes

- <strong>Data Layer</strong> (lib/src/features/financials/data/):
  - <code>financials_firebase_api.dart</code>: Handles all Firestore operations for financial data (CRUD for transactions, bills, goals, currency profiles).
  - <code>abstract_financial_api.dart</code>: Abstracts the data source for easier testing and swapping implementations.
- <strong>Domain Layer</strong> (lib/src/features/financials/domain/):
  - <code>models/</code>: Data models for transactions, goals, currency profiles, invoices, etc.
  - <code>usecases/financials_usecase.dart</code>: Business logic for financial operations (add, update, fetch, delete, aggregate, etc).
- <strong>Presentation Layer</strong> (lib/src/features/financials/presentation/):
  - <code>bloc/financials_bloc.dart</code>: BLoC for all financials state and events (fetching, updating, error handling, etc).
  - <code>pages/financials_page.dart</code>: Main entry for the financials module, with navigation to dashboard, charts, reports, etc.
  - <code>pages/charts_page.dart</code>: All chart widgets, year selector, and toggleable bar/line charts.
  - <code>pages/reports_page.dart</code>: Financial reports, tables, and year selector.
  - <code>pages/bills_and_payments_page.dart</code>: Manage bills, due dates, and payment statuses.
  - <code>pages/goals_page.dart</code>: Set and track financial goals.
  - <code>widgets/</code>: Reusable UI components for financials (charts, cards, etc).

#### Key Highlights

- 🖱️ All charts are interactive and support toggling between bar and line views.
- 🗓️ Year selectors in both charts and reports pages are styled for consistency and easy access.
- 🎨 Financial data is presented in a clear, visually appealing format, with support for dark and light themes.
- 🔗 Financials integrates seamlessly with other modules (appointments, patients, etc) for a unified clinic management experience.

<br/>
<em>For more details on using the Financials feature, see the in-app help or contact support.</em>

</details>





### 📆 Appointments, Sessions & Evaluations <img src="https://img.icons8.com/ios-filled/32/appointment-reminders.png" height="20"/>

<details>
<summary><strong>📦 Module Structure Map</strong> (click to expand)</summary>

<pre>
lib/src/features/appointments/
├── sessions/
│   ├── data/
│   │   ├── remote/
│   │   │   └── session_firebase_api.dart         # Firestore CRUD for sessions
│   │   └── repositories/
│   │       └── sessions_repository_impl.dart     # Implements session repository
│   ├── domain/
│   │   ├── models/session_model.dart             # Session entity
│   │   ├── repositories/abstract_sessions_repository.dart
│   │   └── usecases/sessions_usecase.dart        # Session business logic
│   └── presentation/
│       ├── bloc/sessions_bloc.dart               # BLoC for sessions
│       ├── pages/sessions_page.dart              # Sessions list/search UI
│       ├── pages/add_session_page.dart           # Add/edit session UI
│       └── widgets/session_list_item.dart        # Session list item widget
├── evaluations/
│   ├── data/remote/evaluation_firebase_api.dart  # Firestore CRUD for evaluations
│   ├── domain/
│   │   ├── models/evaluation_model.dart          # Evaluation entity
│   │   └── usecases/evaluations_usecase.dart     # Evaluation business logic
│   └── presentation/
│       ├── bloc/evaluations_bloc.dart            # BLoC for evaluations
│       ├── pages/evaluations_page.dart           # Evaluations list/search UI
│       ├── pages/add_evaluation_page.dart        # Add/edit evaluation UI
│       └── widgets/evaluation_list_item.dart     # Evaluation list item widget
</pre>
</details>

- **Sessions Management**: View, add, edit, and manage appointment sessions for patients. Sessions are tightly integrated with financials and patient records.
- **Evaluations Management**: Manage patient evaluations, including creation, editing, and review of evaluation data.

#### Layered Structure & Key Classes

See the map above for file responsibilities in each layer.

---



### 🤝 AI Integration <img src="https://img.icons8.com/ios-filled/32/artificial-intelligence.png" height="20"/>
- <strong>AI Chat Support</strong>: Use AI to discuss patient cases and get instant insights.
- <strong>Integration with Vertex AI, GPT, and more</strong>: Enhance decision-making and automate tasks.

### 🌍 Localization <img src="https://img.icons8.com/ios-filled/32/language.png" height="20"/>
- <strong>Multi-Language Support</strong>: English & Arabic — easy localization for a global user base.

### 🛡️ Security <img src="https://img.icons8.com/ios-filled/32/lock-2.png" height="20"/>

---


## 🖼️ Visual Gallery

<div align="center">
  <img src="docs/screenshots/appointments.gif" alt="Appointments Demo" width="350" style="margin:8px;"/>
  <img src="docs/screenshots/financials.gif" alt="Financials Demo" width="350" style="margin:8px;"/>
  <img src="docs/screenshots/copilot-chat.gif" alt="Copilot Chat Demo" width="350" style="margin:8px;"/>
  <br/>
  <em>Above: Appointments, Financials, and Copilot Chat in action.<br/>
  (Replace these with your own GIFs/screenshots in <code>docs/screenshots/</code>.)</em>
</div>

---

## 🧩 Main Modules & Features

- **Authentication**: Google Sign-In, Supabase, secure token storage, and account management.
- **Navigation**: Responsive side menu, keyboard navigation, and deep linking.
- **Calendar**: Syncs with Google Calendar, supports event creation, editing, and reminders.
- **Patients**: CRUD for patient records, search, and medical history management.
- **Appointments**: Session and evaluation scheduling, reminders, and status tracking.
- **Financials**: See above for full details.
- **Copilot Chat**: AI-powered chat for case discussion, powered by Vertex AI, GPT, Gemini, and more. Supports file/image upload and multi-model selection.
- **Notifications**: In-app and push notifications for appointments, bills, and more.
- **Settings**: Theme, language, privacy, and account settings.
- **Security**: All sensitive data is encrypted and managed via secure storage and Doppler.
- **Localization**: All UI and data labels are translatable. RTL support for Arabic.
- **OTA Updates**: Seamless over-the-air updates via [Shorebird](https://shorebird.dev/).

---

## 🛠️ Developer Notes

- **Project Structure**: All features are under `lib/src/features/`. Shared/core logic is under `lib/src/core/`.
- **Dependency Injection**: Register new services/blocs in the relevant `*_injections.dart` and `core/injections.dart`.
- **Routing**: Add new routes in `lib/src/core/router/routing_config.dart`.
- **Testing**: Place tests in `test/` mirroring the `lib/` structure. Use mocks for external services.
- **Adding a Language**: Add a new JSON file in `assets/translations/` and update `pubspec.yaml`.
- **Adding a Feature**: Scaffold a new folder in `lib/src/features/`, implement domain/data/presentation layers, and wire up DI and routing.
- **CI/CD**: See `.github/workflows/` for GitHub Actions setup. All major platforms are supported.
- **Release Checklist**: See `docs/RELEASE_CHECKLIST.md` for production readiness.

---
- **Secrets Management with Doppler**: Securely manage API keys and sensitive data using Doppler.

---

## Setup Instructions

### Prerequisites
- **Flutter SDK**: Ensure Flutter is installed on your system. [Flutter Installation Guide](https://flutter.dev/docs/get-started/install)
- **Doppler CLI**: Install the Doppler CLI for managing secrets. [Doppler CLI Installation Guide](https://docs.doppler.com/docs/cli-installation)
- **Firebase**: Set up Firebase for authentication and other backend services. [Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup)

### Project Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/alionour22/dr_copilot.git
   cd dr_copilot
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up Firebase:
   - Add the `google-services.json` file to the `android/app` directory.
   - Add the `GoogleService-Info.plist` file to the `ios/Runner` directory.

4. Set up Doppler:
   - Authenticate with Doppler:
     ```bash
     doppler login
     ```
   - Configure Doppler for the project:
     ```bash
     doppler setup
     ```
   - Add the required secrets:
     ```bash
     doppler secrets set GOOGLE_CLIENT_ID="your-client-id"
     doppler secrets set GOOGLE_CLIENT_SECRET="your-client-secret"
     doppler secrets set REDIRECT_PORT="5000"
     doppler secrets set VERTEX_AI_KEY="YOUR_VERTEX_AI_API_KEY"
     doppler secrets set GPT_KEY="your-gpt-key"
     doppler secrets set GEMINI_KEY="your-gemini-key"
     doppler secrets set DEEP_SEEK_KEY="your-deep-seek-key"
     doppler secrets set QWEN_KEY="your-qwen-key"
     doppler secrets set CLAUDE_KEY="your-claude-key"
     ```

5. Run the app:
   ```bash
   doppler run -- flutter run
   ```

---

## Usage Guidelines

### Accessing Features
- **Authentication**: Log in using your Google account to access the app.
- **Navigation**: Use the side menu to navigate between different sections of the app.
- **Calendar**: View and manage appointments directly from the calendar page.
- **Copilot**: Interact with Dr Copilot for AI-powered assistance.
- **Patients**: Search, view, and manage patient information.
- **Financials**: Track and manage clinic finances.

### Accessing Secrets in Code
Secrets are accessed in the app using environment variables. For example:
```dart
final clientId = Platform.environment['GOOGLE_CLIENT_ID'];
final clientSecret = Platform.environment['GOOGLE_CLIENT_SECRET'];
final redirectPort = Platform.environment['REDIRECT_PORT'];
```

---

## Contributing

We welcome contributions to Dr Copilot! To contribute:
1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Commit your changes and push them to your fork.
4. Submit a pull request with a detailed description of your changes.

---

## License

Dr Copilot is licensed under the MIT License. See the `LICENSE` file for more details.

### Running and Building the App with Doppler

Dr Copilot uses Doppler to manage secrets securely. Below are the commands to run and build the app for different platforms with Doppler.

#### Run the App on Android
```bash
doppler run -- flutter run -d android
```

#### Run the App on iOS
```bash
doppler run -- flutter run -d ios
```

#### Run the App on Web
```bash
doppler run -- flutter run -d web
```

#### Run the App on Windows
```bash
doppler run -- flutter run -d windows
```

#### Run the App on macOS
```bash
doppler run -- flutter run -d macos
```

#### Run the App on Linux
```bash
doppler run -- flutter run -d linux
```

#### Build the App for Android
```bash
doppler run -- flutter build apk
```

#### Build the App for iOS
```bash
doppler run -- flutter build ios
```

#### Build the App for Web
```bash
doppler run -- flutter build web
```

#### Build the App for Windows
```bash
doppler run -- flutter build windows
```

#### Build the App for macOS
```bash
doppler run -- flutter build macos
```

#### Build the App for Linux
```bash
doppler run -- flutter build linux
```

---

## Continuous Integration & Delivery (CI/CD)

Dr Copilot uses **GitHub Actions** for CI/CD to automatically analyze, test, and build the app for all major platforms on every push and pull request. The workflow is defined in `.github/workflows/flutter_ci.yaml` and covers:

- **Web**: Build and test on Ubuntu.
- **Windows**: Build and test on Windows.
- **Linux**: Build and test on Ubuntu.
- **Android**: Build APK and AppBundle on Ubuntu.
- **iOS**: Build on macOS (no code signing in CI).
- **macOS**: Build and test on macOS.

Each job installs dependencies, runs static analysis, executes tests, and builds the app for its platform. See the workflow file for details and customization.

---

## Building and Releasing with Shorebird

[Shorebird](https://shorebird.dev/) enables seamless over-the-air (OTA) updates for Flutter apps. Dr Copilot supports building and releasing with Shorebird for supported platforms.

### Prerequisites
- Install the [Shorebird CLI](https://docs.shorebird.dev/getting-started/installation).
- Authenticate with Shorebird:
  ```bash
  shorebird login
  ```
- Configure your app with Shorebird as needed.

### Building with Shorebird

#### Build for Android
```bash
doppler run -- shorebird build android
```

#### Build for iOS
```bash
doppler run -- shorebird build ios
```

#### Build for Windows
```bash
doppler run -- shorebird build windows
```

#### Build for macOS
```bash
doppler run -- shorebird build macos
```

### Releasing with Shorebird

#### Release for Android
```bash
shorebird release android
```

#### Release for iOS
```bash
shorebird release ios
```

#### Release for Windows
```bash
shorebird release windows
```

#### Release for macOS
```bash
shorebird release macos
```

For more details, see the [Shorebird documentation](https://docs.shorebird.dev/).

# Testing Google Play Auto-Deployment
