# 📝 Changelog

All notable changes to **Dr Copilot** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---


## [Unreleased]
### Added
- Dr Copilot logo SVG and new app icon assets for all platforms
- App icon generation instructions and automation (flutter_launcher_icons)
- Multi-clinic onboarding documentation and flows
- Firestore export script and migration tools
- Billing summary and app context documentation
- Enhanced localization: new translations and improved RTL support
- New onboarding and invitation flows for clinics
- Financials: currency profiles, revenue charts, and improved dashboard
- Security: migration to flutter_secure_storage, improved release checklist
- CI/CD: Doppler integration, Shorebird OTA, GitHub Actions workflows
- Clinic selection dropdown to evaluation and session pages
- Firestore export to JSON functionality
- Roles and permissions structure with enums and mapping
- Month labels and financial report translations for Arabic and English
- Toggleable Bar/Line chart for revenue vs expenses
- Bill management: fetch, add, update, delete, payment processing
- Delete functionality for invoices and transactions by reference ID
- Invoice and transaction handling in evaluations bloc
- Direction field in transaction model

### Changed
- Refactored navigation and BLoC structure for sessions and financials
- Improved session and evaluation search and filtering (filter by patient name, better data retrieval)
- Modularized codebase for maintainability and scalability
- Updated app icon and branding across all platforms
- Enhanced accessibility and theming
- Refactored ChartsPage to use StatefulWidget and year selection
- Refactored transaction queries for user scoping and ordering
- Improved transaction fetching order (ascending by creation date)
- Refactored financials and transactions handling for better state management
- Updated color handling in widgets for alpha transparency

### Fixed
- Improved transaction and bill management logic
- Fixed bugs in patient and session CRUD operations
- Enhanced error handling and state management in BLoCs
- Enhanced session and evaluation retrieval by dynamically fetching patient names and including document IDs
- Improved transaction list item logic for income detection

### Removed
- Deprecated/unused files and legacy code


---

## [1.0.0] - 2025-05-16
### Added
- First public release of Dr Copilot 🚀
- Modular architecture: Clean Architecture, BLoC, DI, go_router, localization, theming, error handling, testing, security, analytics, accessibility.
- Features: Authentication, Navigation, Calendar, Patients, Appointments, Financials, Copilot Chat, Notifications, Settings, OTA updates.
- Financials: Dashboard, transactions, charts, reports, bills, goals, currency profiles.
- Appointments/Sessions/Evaluations: Full CRUD, search, integration with financials and patients.
- AI Copilot: Chat, multi-model support (Vertex AI, GPT, Gemini, etc).
- Accessibility: Semantic widgets, high-contrast, RTL, keyboard navigation.
- CI/CD: GitHub Actions, Shorebird OTA, Doppler secrets management.

### Changed
- N/A

### Fixed
- N/A

### Removed
- N/A

---

[Unreleased]: https://github.com/alionour22/dr_copilot/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/alionour22/dr_copilot/releases/tag/v1.0.0
