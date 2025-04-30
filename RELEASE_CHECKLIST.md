# Dr Copilot Release Checklist

This checklist covers what you have and what you might still be missing for a production-ready Flutter app.

---

## ✅ What You Have
- MIT License (2025)
- README with CI/CD and Shorebird docs
- CI/CD: GitHub Actions for all major platforms (Android, iOS, web, Windows, Linux, macOS)
- Shorebird: OTA update support and docs
- Localization: Easy Localization with translation files
- Authentication: Firebase Auth, Google Sign-In, persistent token logic
- Clean Architecture: Use cases, repositories, BLoC, DI
- Assets: SVGs, translations, icons
- Platform folders: android, ios, linux, macos, windows, web
- Tests: Some test structure present

---

## ❗️What You Might Be Missing

### 1. App Store/Play Store Readiness
- App icons and splash screens for all platforms
  - Design and generate icons/splashes using [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) and [flutter_native_splash](https://pub.dev/packages/flutter_native_splash).
  - Add generated assets to each platform folder and update pubspec.yaml.
- Store listing assets (screenshots, descriptions)
  - Take screenshots on all platforms and prepare marketing text.
  - Upload to Google Play Console, App Store Connect, Microsoft Store, etc.
- Code signing setup for iOS and Android
  - For Android: Set up keystore and update `key.properties` and `build.gradle`.
  - For iOS: Set up certificates and provisioning profiles in Xcode.
- Privacy policy and terms of service
  - Write documents and host them (e.g., in-app, on a website, or GitHub Pages).
  - Link to them in your app and store listings.

### 2. Security & Privacy
- [x] Secure storage for sensitive tokens (not just SharedPreferences) ✅
  - [x] All sensitive tokens and secrets are managed via Doppler environment variables ✅
  - [x]  Use [flutter_secure_storage] (https://pub.dev/packages/flutter_secure_storage) for Android/iOS/macOS/Linux, or platform keychains.✅
  - [x]  **Do NOT use SharedPreferences for sensitive data, even with encryption, unless absolutely necessary (e.g., on web).** ✅
  - [x]  Replace any usage of SharedPreferences for storing tokens with flutter_secure_storage.✅
  - Example usage:
    ```dart
    import 'package:flutter_secure_storage/flutter_secure_storage.dart';
    final storage = FlutterSecureStorage();
    // To write
    await storage.write(key: 'auth_token', value: token);
    // To read
    String? token = await storage.read(key: 'auth_token');
    // To delete
    await storage.delete(key: 'auth_token');
    ``` 
  - Audit your codebase to ensure all sensitive data (tokens, refresh tokens, etc.) are stored securely.
- Remove/rotate any test credentials or API keys
  - Audit code and environment files for secrets.
  - Rotate and remove any test or hardcoded keys.
- GDPR/CCPA compliance if needed
  - Add consent dialogs and update privacy policy as required by your target regions.

### 3. Production Configuration
- Proper `firebase_options.dart` for all environments
  - Generate with `flutterfire configure` for each environment (dev, prod).
- Release build configuration for all platforms
  - Use `flutter build` with `--release` for each target.
  - Update build flavors if needed.
- [x] Environment variable management (Doppler, .env, etc.) ✅
  - Store secrets in Doppler or .env files and load them securely in your app.

### 4. Testing
- More comprehensive unit, widget, and integration tests
  - Write tests for all business logic, UI, and critical flows.
  - Use `flutter test` and integration test packages.
- Automated test coverage reporting in CI
  - Add a step in GitHub Actions to run `flutter test --coverage` and upload results (e.g., to Codecov).

### 5. Error Handling & Analytics
- Crash reporting (e.g., Sentry, Firebase Crashlytics)
  - Add the relevant package and initialize in `main.dart`.
- Analytics integration (Firebase Analytics, etc.)
  - Add analytics package and log key events.
- User feedback mechanism
  - Add a feedback form or link to email/support in the app.

### 6. Documentation
- API documentation (for any backend)
  - Use tools like Swagger or Postman for backend APIs.
- Developer setup instructions (local dev, build, release)
  - Add a section in README for setup, build, and release steps.
- Contribution guidelines (CONTRIBUTING.md)
  - Create a CONTRIBUTING.md with PR, code style, and review process.
- Changelog (CHANGELOG.md)
  - Create and maintain a CHANGELOG.md for every release.

### 7. Accessibility & Internationalization
- Accessibility checks (a11y)
  - Use Flutter's accessibility tools and test with screen readers.
- Complete and accurate translations for all supported languages
  - Review and update all translation files in `assets/translations/`.

### 8. Performance
- App size optimization (tree shaking, asset compression)
  - Use `flutter build --release` and compress images/assets.
- Lazy loading for large assets or features
  - Implement lazy loading for images, data, or modules as needed.

### 9. Legal
- Third-party license attributions (if required)
  - Use [license_checker](https://pub.dev/packages/license_checker) or similar to generate attributions.
- Up-to-date LICENSE file
  - Review and update LICENSE as needed.

### 10. Deployment
- Automated deployment scripts for stores (optional)
  - Use Fastlane, GitHub Actions, or Codemagic for automated store uploads.
- OTA update configuration (Shorebird)
  - Follow [Shorebird docs](https://docs.shorebird.dev/) to configure and test OTA updates.

---

## Recommended Free AI Tools for App Splash and Logo Generation

- **Microsoft Designer** ([designer.microsoft.com](https://designer.microsoft.com/))
  - Free, AI-powered logo and splash image generation, easy export.
  - Steps: Go to the site, describe your app/brand, let the AI generate options, customize, and download.

- **Canva (with AI features)** ([canva.com](https://www.canva.com/))
  - Free tier, AI logo generator, templates for splash screens, export in PNG/SVG.
  - Steps: Sign up, search for "logo" or "splash screen" templates, use Magic Design/AI features, customize, and export.

- **Hatchful by Shopify** ([hatchful.shopify.com](https://hatchful.shopify.com/))
  - 100% free, AI-powered logo generator, many styles, instant download.
  - Steps: Go to the site, select your industry/style, enter your app name, choose icons/colors, and download.

- **Fotor AI Logo Generator** ([fotor.com/tools/ai-logo-generator](https://www.fotor.com/tools/ai-logo-generator/))
  - Free tier, AI logo and splash image generation, easy export.
  - Steps: Enter your app/brand name, pick a style, let AI generate, customize, and download.

- **Appicon.co** ([appicon.co](https://appicon.co/))
  - Not AI, but lets you upload your logo and generate all splash/icon sizes for all platforms for free.
  - Steps: Upload your logo, select platforms, and download all required icon/splash sizes.

**Tip:**
- For splash screens, use Canva or Microsoft Designer to create a background + logo, then export as PNG.
- For logos, use Hatchful, Fotor, or Microsoft Designer for AI-generated options.

---

## Next Steps
- Review the above checklist and address any missing items relevant to your app’s goals.
- If you want, generate templates for missing docs (e.g., CONTRIBUTING.md, CHANGELOG.md), or set up code signing, analytics, or store assets.
