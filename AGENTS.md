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
- Subscription Plan Translations

## 1. Translation files — add before last `}` in each

### en.json (35 new keys at end)
```json
  "planFree": "Free",
  "planPro": "Pro",
  "planElite": "Elite",
  "planFreeDesc": "Perfect for trying out Dr. AI",
  "planProDesc": "Best for individual practitioners",
  "planEliteDesc": "For power users & clinics",
  "planFreeFeature1": "Core Patient Management",
  "planFreeFeature2": "Standard AI Chat (Gemini Flash)",
  "planFreeFeature3": "Native Speech-to-Text",
  "planFreeFeature4": "5 AI chats/day limit",
  "planProFeature1": "Unlimited AI Chat",
  "planProFeature2": "GPT-3.5 & Gemini Access",
  "planProFeature3": "Deepgram Speech Recognition",
  "planProFeature4": "Cloud Backup",
  "planProFeature5": "Basic Image Analysis",
  "planProFeature6": "50 image analyses/month",
  "planEliteFeature1": "Claude 3.5 Sonnet & GPT-4o",
  "planEliteFeature2": "Unlimited Image Analysis",
  "planEliteFeature3": "Priority Support",
  "planEliteFeature4": "Advanced Exporting",
  "planEliteFeature5": "Multi-clinic Support",
  "planHeaderTitle": "All-In-One Price, Zero Hassle.",
  "planSubHeader": "Cancel Anytime. Let's Get Started!",
  "planDescription": "Unlock advanced features, unlimited AI models, and premium support",
  "planMonthly": "Monthly",
  "planYearly": "Yearly",
  "planSavePercent": "Save 20%",
  "planCurrentPlan": "Current Plan",
  "planGetStarted": "Get Started",
  "planSubscribeNow": "Subscribe Now",
  "planDowngrade": "Downgrade",
  "planRecommended": "RECOMMENDED",
  "planWhatsIncluded": "What's Included",
  "planPlanDetails": "{} Plan Details",
  "planPaymentOpened": "Payment page opened. Please verify payment in the app when done.",
  "planCouldNotOpenPayment": "Could not open payment page",
  "planPleaseSignIn": "Please sign in first",
  "planDowngradeManage": "To downgrade, please manage your subscription in settings.",
  "planSubscribedToPlan": "You are currently subscribed to this plan.",
  "planPerYear": "/year",
  "planPerMonth": "/month"
```

### ar.json (same keys, Arabic values)
```json
  "planFree": "مجاني",
  "planPro": "احترافي",
  "planElite": "ممتاز",
  "planFreeDesc": "مثالي لتجربة د. أي آي",
  "planProDesc": "الأفضل للأطباء المستقلين",
  "planEliteDesc": "للمستخدمين المحترفين والعيادات",
  "planFreeFeature1": "إدارة المرضى الأساسية",
  "planFreeFeature2": "دردشة ذكاء اصطناعي قياسية (Gemini Flash)",
  "planFreeFeature3": "تحويل الصوت إلى نص محلي",
  "planFreeFeature4": "حد 5 محادثات ذكاء اصطناعي/يوم",
  "planProFeature1": "دردشة ذكاء اصطناعي غير محدودة",
  "planProFeature2": "الوصول إلى GPT-3.5 و Gemini",
  "planProFeature3": "التعرف على الكلام من Deepgram",
  "planProFeature4": "نسخ احتياطي سحابي",
  "planProFeature5": "تحليل صور أساسي",
  "planProFeature6": "50 تحليل صورة/شهر",
  "planEliteFeature1": "Claude 3.5 Sonnet و GPT-4o",
  "planEliteFeature2": "تحليل صور غير محدود",
  "planEliteFeature3": "دعم ذو أولوية",
  "planEliteFeature4": "تصدير متقدم",
  "planEliteFeature5": "دعم متعدد العيادات",
  "planHeaderTitle": "سعر شامل، بدون متاعب.",
  "planSubHeader": "يمكنك الإلغاء في أي وقت. لنبدأ!",
  "planDescription": "افتح الميزات المتقدمة ونماذج الذكاء الاصطناعي غير المحدودة والدعم المميز",
  "planMonthly": "شهري",
  "planYearly": "سنوي",
  "planSavePercent": "وفر 20%",
  "planCurrentPlan": "الخطة الحالية",
  "planGetStarted": "ابدأ الآن",
  "planSubscribeNow": "اشترك الآن",
  "planDowngrade": "تخفيض الخطة",
  "planRecommended": "موصى به",
  "planWhatsIncluded": "ما هو مشمول",
  "planPlanDetails": "تفاصيل خطة {}",
  "planPaymentOpened": "تم فتح صفحة الدفع. يرجى التحقق من الدفع في التطبيق عند الانتهاء.",
  "planCouldNotOpenPayment": "تعذر فتح صفحة الدفع",
  "planPleaseSignIn": "يرجى تسجيل الدخول أولاً",
  "planDowngradeManage": "لتخفيض الخطة، يرجى إدارة اشتراكك في الإعدادات.",
  "planSubscribedToPlan": "أنت مشترك حالياً في هذه الخطة.",
  "planPerYear": "/سنة",
  "planPerMonth": "/شهر"
```

### fr.json (same keys, French values)
```json
  "planFree": "Gratuit",
  "planPro": "Pro",
  "planElite": "Elite",
  "planFreeDesc": "Parfait pour essayer Dr AI",
  "planProDesc": "Idéal pour les praticiens individuels",
  "planEliteDesc": "Pour les utilisateurs avancés et les cliniques",
  "planFreeFeature1": "Gestion de base des patients",
  "planFreeFeature2": "Chat IA standard (Gemini Flash)",
  "planFreeFeature3": "Reconnaissance vocale native",
  "planFreeFeature4": "Limite de 5 chats IA/jour",
  "planProFeature1": "Chat IA illimité",
  "planProFeature2": "Accès GPT-3.5 et Gemini",
  "planProFeature3": "Reconnaissance vocale Deepgram",
  "planProFeature4": "Sauvegarde cloud",
  "planProFeature5": "Analyse d'image de base",
  "planProFeature6": "50 analyses d'image/mois",
  "planEliteFeature1": "Claude 3.5 Sonnet et GPT-4o",
  "planEliteFeature2": "Analyse d'image illimitée",
  "planEliteFeature3": "Support prioritaire",
  "planEliteFeature4": "Exportation avancée",
  "planEliteFeature5": "Support multi-cliniques",
  "planHeaderTitle": "Prix tout-en-un, zéro tracas.",
  "planSubHeader": "Annulez à tout moment. Commençons !",
  "planDescription": "Débloquez des fonctionnalités avancées, des modèles IA illimités et un support premium",
  "planMonthly": "Mensuel",
  "planYearly": "Annuel",
  "planSavePercent": "Économisez 20%",
  "planCurrentPlan": "Plan actuel",
  "planGetStarted": "Commencer",
  "planSubscribeNow": "S'abonner",
  "planDowngrade": "Rétrograder",
  "planRecommended": "RECOMMANDÉ",
  "planWhatsIncluded": "Ce qui est inclus",
  "planPlanDetails": "Détails du plan {}",
  "planPaymentOpened": "Page de paiement ouverte. Veuillez vérifier le paiement dans l'application une fois terminé.",
  "planCouldNotOpenPayment": "Impossible d'ouvrir la page de paiement",
  "planPleaseSignIn": "Veuillez d'abord vous connecter",
  "planDowngradeManage": "Pour rétrograder, veuillez gérer votre abonnement dans les paramètres.",
  "planSubscribedToPlan": "Vous êtes actuellement abonné à ce plan.",
  "planPerYear": "/an",
  "planPerMonth": "/mois"
```

### es.json (same keys, Spanish values)
```json
  "planFree": "Gratis",
  "planPro": "Pro",
  "planElite": "Élite",
  "planFreeDesc": "Perfecto para probar Dr. AI",
  "planProDesc": "Ideal para profesionales individuales",
  "planEliteDesc": "Para usuarios avanzados y clínicas",
  "planFreeFeature1": "Gestión básica de pacientes",
  "planFreeFeature2": "Chat IA estándar (Gemini Flash)",
  "planFreeFeature3": "Reconocimiento de voz nativo",
  "planFreeFeature4": "Límite de 5 chats IA/día",
  "planProFeature1": "Chat IA ilimitado",
  "planProFeature2": "Acceso a GPT-3.5 y Gemini",
  "planProFeature3": "Reconocimiento de voz Deepgram",
  "planProFeature4": "Copia de seguridad en la nube",
  "planProFeature5": "Análisis de imágenes básico",
  "planProFeature6": "50 análisis de imágenes/mes",
  "planEliteFeature1": "Claude 3.5 Sonnet y GPT-4o",
  "planEliteFeature2": "Análisis de imágenes ilimitado",
  "planEliteFeature3": "Soporte prioritario",
  "planEliteFeature4": "Exportación avanzada",
  "planEliteFeature5": "Soporte multi-clínica",
  "planHeaderTitle": "Precio todo en uno, sin complicaciones.",
  "planSubHeader": "Cancela cuando quieras. ¡Comencemos!",
  "planDescription": "Desbloquea funciones avanzadas, modelos de IA ilimitados y soporte premium",
  "planMonthly": "Mensual",
  "planYearly": "Anual",
  "planSavePercent": "Ahorra 20%",
  "planCurrentPlan": "Plan actual",
  "planGetStarted": "Comenzar",
  "planSubscribeNow": "Suscribirse",
  "planDowngrade": "Degradar",
  "planRecommended": "RECOMENDADO",
  "planWhatsIncluded": "Qué está incluido",
  "planPlanDetails": "Detalles del plan {}",
  "planPaymentOpened": "Página de pago abierta. Por favor, verifica el pago en la aplicación cuando termines.",
  "planCouldNotOpenPayment": "No se pudo abrir la página de pago",
  "planPleaseSignIn": "Por favor, inicia sesión primero",
  "planDowngradeManage": "Para degradar, gestiona tu suscripción en los ajustes.",
  "planSubscribedToPlan": "Actualmente estás suscrito a este plan.",
  "planPerYear": "/año",
  "planPerMonth": "/mes"
```

### de.json (same keys, German values)
```json
  "planFree": "Kostenlos",
  "planPro": "Pro",
  "planElite": "Elite",
  "planFreeDesc": "Perfekt zum Ausprobieren von Dr. AI",
  "planProDesc": "Am besten für Einzelpraktiker",
  "planEliteDesc": "Für Power-User und Kliniken",
  "planFreeFeature1": "Grundlegende Patientenverwaltung",
  "planFreeFeature2": "Standard-KI-Chat (Gemini Flash)",
  "planFreeFeature3": "Native Sprachsteuerung",
  "planFreeFeature4": "Limit von 5 KI-Chats/Tag",
  "planProFeature1": "Unbegrenzter KI-Chat",
  "planProFeature2": "Zugriff auf GPT-3.5 und Gemini",
  "planProFeature3": "Deepgram Spracherkennung",
  "planProFeature4": "Cloud-Backup",
  "planProFeature5": "Bildanalyse (Basis)",
  "planProFeature6": "50 Bildanalysen/Monat",
  "planEliteFeature1": "Claude 3.5 Sonnet und GPT-4o",
  "planEliteFeature2": "Unbegrenzte Bildanalyse",
  "planEliteFeature3": "Prioritäts-Support",
  "planEliteFeature4": "Erweiterter Export",
  "planEliteFeature5": "Multi-Klinik-Support",
  "planHeaderTitle": "All-in-One-Preis, null Aufwand.",
  "planSubHeader": "Jederzeit kündbar. Legen wir los!",
  "planDescription": "Schalte erweiterte Funktionen, unbegrenzte KI-Modelle und Premium-Support frei",
  "planMonthly": "Monatlich",
  "planYearly": "Jährlich",
  "planSavePercent": "20% sparen",
  "planCurrentPlan": "Aktueller Tarif",
  "planGetStarted": "Loslegen",
  "planSubscribeNow": "Jetzt abonnieren",
  "planDowngrade": "Herabstufen",
  "planRecommended": "EMPFEHLUNG",
  "planWhatsIncluded": "Was ist enthalten",
  "planPlanDetails": "{} Tarifdetails",
  "planPaymentOpened": "Zahlungsseite geöffnet. Bitte bestätigen Sie die Zahlung in der App, wenn Sie fertig sind.",
  "planCouldNotOpenPayment": "Zahlungsseite konnte nicht geöffnet werden",
  "planPleaseSignIn": "Bitte melden Sie sich zuerst an",
  "planDowngradeManage": "Um herabzustufen, verwalten Sie Ihr Abonnement in den Einstellungen.",
  "planSubscribedToPlan": "Sie haben diesen Tarif aktuell abonniert.",
  "planPerYear": "/Jahr",
  "planPerMonth": "/Monat"
```

---

## 2. subscription_pricing_page.dart changes

### Replace `_handleUpgrade` method (lines 18-77)
Replace hardcoded SnackBar strings:
```dart
// Line 33:
).showSnackBar(SnackBar(content: SelectionArea(child: Text('planPleaseSignIn'.tr()))));
// Line 59-61:
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: SelectionArea(child: Text('planPaymentOpened'.tr()))),
);
// Line 66:
SnackBar(content: SelectionArea(child: Text('planCouldNotOpenPayment'.tr()))),
```

### Replace build method strings (lines 99-206)
```dart
// Line 100: 'All-In-One Price, Zero Hassle.' → 'planHeaderTitle'.tr()
// Line 109: 'Cancel Anytime...' → 'planSubHeader'.tr()
// Line 117: 'Unlock advanced...' → 'planDescription'.tr()
// Line 136: 'Monthly' → 'planMonthly'.tr()
// Line 139: 'Yearly' → 'planYearly'.tr()
// Line 141: 'Save 20%' → 'planSavePercent'.tr()
// Line 156: 'Free' → 'planFree'.tr()
// Line 159: 'Perfect for trying...' → 'planFreeDesc'.tr()
// Line 161-165: features → ['planFreeFeature1'.tr(), ..., 'planFreeFeature4'.tr()]
//   → Change `const` list to non-const:
//   ```
//   features: [
//     'planFreeFeature1'.tr(),
//     'planFreeFeature2'.tr(),
//     'planFreeFeature3'.tr(),
//     'planFreeFeature4'.tr(),
//   ],
//   ```
// Line 166: 'Current Plan' → 'planCurrentPlan'.tr()
// Line 173: 'Pro' → 'planPro'.tr()
// Line 176: 'Best for...' → 'planProDesc'.tr()
// Line 178-184: features → same pattern with planProFeature1-6
// Line 185: 'Get Started' → 'planGetStarted'.tr()
// Line 191: 'Elite' → 'planElite'.tr()
// Line 194: 'For power users...' → 'planEliteDesc'.tr()
// Line 196-201: features → same pattern with planEliteFeature1-5
// Line 202: 'Get Started' → 'planGetStarted'.tr()
```

### Replace `_PricingCard` price/period strings (line 329-330)
```dart
final priceText = price == 0 ? 'planPriceFree'.tr() : '\$${price.toStringAsFixed(2)}';
final period = widget.isYearly ? 'planPerYear'.tr() : 'planPerMonth'.tr();
```

Also need to add `"planPriceFree": "$0"` to translation files if you want that localized.

### Replace 'RECOMMENDED' (line 381-382)
```dart
child: Text('planRecommended'.tr(),
```

---

## 3. plan_details_page.dart changes

### Replace build method strings
```dart
// Line 112: '\$0' → `'planPriceFree'.tr()` (or add a new key)
// Line 113: '/year' → `'planPerYear'.tr()`, '/month' → `'planPerMonth'.tr()`
// Line 118: '${widget.title} Plan Details' → `'planPlanDetails'.tr(args: [widget.title])`
// Line 147: widget.description → keep as-is, it's now a .tr() key mapped through
// Line 180: 'What\'s Included' → `'planWhatsIncluded'.tr()`
// Line 195: widget.features → keep as-is, they're now .tr() keys mapped
```

### Replace button text (lines 255-259)
```dart
child: Text(
  widget.isCurrent
      ? 'planCurrentPlan'.tr()
      : (widget.title == 'Free'
          ? 'planDowngrade'.tr()
          : 'planSubscribeNow'.tr()),
```

### Replace SnackBar strings (lines 76-77, 236-240)
```dart
// Line 76-77: → 'planPaymentOpened'.tr()
// Line 238-240: → 'planDowngradeManage'.tr()
```

### Replace "You are currently subscribed" (line 272)
```dart
Text("planSubscribedToPlan".tr(),
```

---

## 4. Verify

After all changes: `flutter analyze`

Expected: 0 new issues. All pre-existing warnings/infos unchanged.
- Subscription Plan Translations

## 1. Translation files — add before last `}` in each

### en.json (35 new keys at end)
```json
  "planFree": "Free",
  "planPro": "Pro",
  "planElite": "Elite",
  "planFreeDesc": "Perfect for trying out Dr. AI",
  "planProDesc": "Best for individual practitioners",
  "planEliteDesc": "For power users & clinics",
  "planFreeFeature1": "Core Patient Management",
  "planFreeFeature2": "Standard AI Chat (Gemini Flash)",
  "planFreeFeature3": "Native Speech-to-Text",
  "planFreeFeature4": "5 AI chats/day limit",
  "planProFeature1": "Unlimited AI Chat",
  "planProFeature2": "GPT-3.5 & Gemini Access",
  "planProFeature3": "Deepgram Speech Recognition",
  "planProFeature4": "Cloud Backup",
  "planProFeature5": "Basic Image Analysis",
  "planProFeature6": "50 image analyses/month",
  "planEliteFeature1": "Claude 3.5 Sonnet & GPT-4o",
  "planEliteFeature2": "Unlimited Image Analysis",
  "planEliteFeature3": "Priority Support",
  "planEliteFeature4": "Advanced Exporting",
  "planEliteFeature5": "Multi-clinic Support",
  "planHeaderTitle": "All-In-One Price, Zero Hassle.",
  "planSubHeader": "Cancel Anytime. Let's Get Started!",
  "planDescription": "Unlock advanced features, unlimited AI models, and premium support",
  "planMonthly": "Monthly",
  "planYearly": "Yearly",
  "planSavePercent": "Save 20%",
  "planCurrentPlan": "Current Plan",
  "planGetStarted": "Get Started",
  "planSubscribeNow": "Subscribe Now",
  "planDowngrade": "Downgrade",
  "planRecommended": "RECOMMENDED",
  "planWhatsIncluded": "What's Included",
  "planPlanDetails": "{} Plan Details",
  "planPaymentOpened": "Payment page opened. Please verify payment in the app when done.",
  "planCouldNotOpenPayment": "Could not open payment page",
  "planPleaseSignIn": "Please sign in first",
  "planDowngradeManage": "To downgrade, please manage your subscription in settings.",
  "planSubscribedToPlan": "You are currently subscribed to this plan.",
  "planPerYear": "/year",
  "planPerMonth": "/month"
```

### ar.json (same keys, Arabic values)
```json
  "planFree": "مجاني",
  "planPro": "احترافي",
  "planElite": "ممتاز",
  "planFreeDesc": "مثالي لتجربة د. أي آي",
  "planProDesc": "الأفضل للأطباء المستقلين",
  "planEliteDesc": "للمستخدمين المحترفين والعيادات",
  "planFreeFeature1": "إدارة المرضى الأساسية",
  "planFreeFeature2": "دردشة ذكاء اصطناعي قياسية (Gemini Flash)",
  "planFreeFeature3": "تحويل الصوت إلى نص محلي",
  "planFreeFeature4": "حد 5 محادثات ذكاء اصطناعي/يوم",
  "planProFeature1": "دردشة ذكاء اصطناعي غير محدودة",
  "planProFeature2": "الوصول إلى GPT-3.5 و Gemini",
  "planProFeature3": "التعرف على الكلام من Deepgram",
  "planProFeature4": "نسخ احتياطي سحابي",
  "planProFeature5": "تحليل صور أساسي",
  "planProFeature6": "50 تحليل صورة/شهر",
  "planEliteFeature1": "Claude 3.5 Sonnet و GPT-4o",
  "planEliteFeature2": "تحليل صور غير محدود",
  "planEliteFeature3": "دعم ذو أولوية",
  "planEliteFeature4": "تصدير متقدم",
  "planEliteFeature5": "دعم متعدد العيادات",
  "planHeaderTitle": "سعر شامل، بدون متاعب.",
  "planSubHeader": "يمكنك الإلغاء في أي وقت. لنبدأ!",
  "planDescription": "افتح الميزات المتقدمة ونماذج الذكاء الاصطناعي غير المحدودة والدعم المميز",
  "planMonthly": "شهري",
  "planYearly": "سنوي",
  "planSavePercent": "وفر 20%",
  "planCurrentPlan": "الخطة الحالية",
  "planGetStarted": "ابدأ الآن",
  "planSubscribeNow": "اشترك الآن",
  "planDowngrade": "تخفيض الخطة",
  "planRecommended": "موصى به",
  "planWhatsIncluded": "ما هو مشمول",
  "planPlanDetails": "تفاصيل خطة {}",
  "planPaymentOpened": "تم فتح صفحة الدفع. يرجى التحقق من الدفع في التطبيق عند الانتهاء.",
  "planCouldNotOpenPayment": "تعذر فتح صفحة الدفع",
  "planPleaseSignIn": "يرجى تسجيل الدخول أولاً",
  "planDowngradeManage": "لتخفيض الخطة، يرجى إدارة اشتراكك في الإعدادات.",
  "planSubscribedToPlan": "أنت مشترك حالياً في هذه الخطة.",
  "planPerYear": "/سنة",
  "planPerMonth": "/شهر"
```

### fr.json (same keys, French values)
```json
  "planFree": "Gratuit",
  "planPro": "Pro",
  "planElite": "Elite",
  "planFreeDesc": "Parfait pour essayer Dr AI",
  "planProDesc": "Idéal pour les praticiens individuels",
  "planEliteDesc": "Pour les utilisateurs avancés et les cliniques",
  "planFreeFeature1": "Gestion de base des patients",
  "planFreeFeature2": "Chat IA standard (Gemini Flash)",
  "planFreeFeature3": "Reconnaissance vocale native",
  "planFreeFeature4": "Limite de 5 chats IA/jour",
  "planProFeature1": "Chat IA illimité",
  "planProFeature2": "Accès GPT-3.5 et Gemini",
  "planProFeature3": "Reconnaissance vocale Deepgram",
  "planProFeature4": "Sauvegarde cloud",
  "planProFeature5": "Analyse d'image de base",
  "planProFeature6": "50 analyses d'image/mois",
  "planEliteFeature1": "Claude 3.5 Sonnet et GPT-4o",
  "planEliteFeature2": "Analyse d'image illimitée",
  "planEliteFeature3": "Support prioritaire",
  "planEliteFeature4": "Exportation avancée",
  "planEliteFeature5": "Support multi-cliniques",
  "planHeaderTitle": "Prix tout-en-un, zéro tracas.",
  "planSubHeader": "Annulez à tout moment. Commençons !",
  "planDescription": "Débloquez des fonctionnalités avancées, des modèles IA illimités et un support premium",
  "planMonthly": "Mensuel",
  "planYearly": "Annuel",
  "planSavePercent": "Économisez 20%",
  "planCurrentPlan": "Plan actuel",
  "planGetStarted": "Commencer",
  "planSubscribeNow": "S'abonner",
  "planDowngrade": "Rétrograder",
  "planRecommended": "RECOMMANDÉ",
  "planWhatsIncluded": "Ce qui est inclus",
  "planPlanDetails": "Détails du plan {}",
  "planPaymentOpened": "Page de paiement ouverte. Veuillez vérifier le paiement dans l'application une fois terminé.",
  "planCouldNotOpenPayment": "Impossible d'ouvrir la page de paiement",
  "planPleaseSignIn": "Veuillez d'abord vous connecter",
  "planDowngradeManage": "Pour rétrograder, veuillez gérer votre abonnement dans les paramètres.",
  "planSubscribedToPlan": "Vous êtes actuellement abonné à ce plan.",
  "planPerYear": "/an",
  "planPerMonth": "/mois"
```

### es.json (same keys, Spanish values)
```json
  "planFree": "Gratis",
  "planPro": "Pro",
  "planElite": "Élite",
  "planFreeDesc": "Perfecto para probar Dr. AI",
  "planProDesc": "Ideal para profesionales individuales",
  "planEliteDesc": "Para usuarios avanzados y clínicas",
  "planFreeFeature1": "Gestión básica de pacientes",
  "planFreeFeature2": "Chat IA estándar (Gemini Flash)",
  "planFreeFeature3": "Reconocimiento de voz nativo",
  "planFreeFeature4": "Límite de 5 chats IA/día",
  "planProFeature1": "Chat IA ilimitado",
  "planProFeature2": "Acceso a GPT-3.5 y Gemini",
  "planProFeature3": "Reconocimiento de voz Deepgram",
  "planProFeature4": "Copia de seguridad en la nube",
  "planProFeature5": "Análisis de imágenes básico",
  "planProFeature6": "50 análisis de imágenes/mes",
  "planEliteFeature1": "Claude 3.5 Sonnet y GPT-4o",
  "planEliteFeature2": "Análisis de imágenes ilimitado",
  "planEliteFeature3": "Soporte prioritario",
  "planEliteFeature4": "Exportación avanzada",
  "planEliteFeature5": "Soporte multi-clínica",
  "planHeaderTitle": "Precio todo en uno, sin complicaciones.",
  "planSubHeader": "Cancela cuando quieras. ¡Comencemos!",
  "planDescription": "Desbloquea funciones avanzadas, modelos de IA ilimitados y soporte premium",
  "planMonthly": "Mensual",
  "planYearly": "Anual",
  "planSavePercent": "Ahorra 20%",
  "planCurrentPlan": "Plan actual",
  "planGetStarted": "Comenzar",
  "planSubscribeNow": "Suscribirse",
  "planDowngrade": "Degradar",
  "planRecommended": "RECOMENDADO",
  "planWhatsIncluded": "Qué está incluido",
  "planPlanDetails": "Detalles del plan {}",
  "planPaymentOpened": "Página de pago abierta. Por favor, verifica el pago en la aplicación cuando termines.",
  "planCouldNotOpenPayment": "No se pudo abrir la página de pago",
  "planPleaseSignIn": "Por favor, inicia sesión primero",
  "planDowngradeManage": "Para degradar, gestiona tu suscripción en los ajustes.",
  "planSubscribedToPlan": "Actualmente estás suscrito a este plan.",
  "planPerYear": "/año",
  "planPerMonth": "/mes"
```

### de.json (same keys, German values)
```json
  "planFree": "Kostenlos",
  "planPro": "Pro",
  "planElite": "Elite",
  "planFreeDesc": "Perfekt zum Ausprobieren von Dr. AI",
  "planProDesc": "Am besten für Einzelpraktiker",
  "planEliteDesc": "Für Power-User und Kliniken",
  "planFreeFeature1": "Grundlegende Patientenverwaltung",
  "planFreeFeature2": "Standard-KI-Chat (Gemini Flash)",
  "planFreeFeature3": "Native Sprachsteuerung",
  "planFreeFeature4": "Limit von 5 KI-Chats/Tag",
  "planProFeature1": "Unbegrenzter KI-Chat",
  "planProFeature2": "Zugriff auf GPT-3.5 und Gemini",
  "planProFeature3": "Deepgram Spracherkennung",
  "planProFeature4": "Cloud-Backup",
  "planProFeature5": "Bildanalyse (Basis)",
  "planProFeature6": "50 Bildanalysen/Monat",
  "planEliteFeature1": "Claude 3.5 Sonnet und GPT-4o",
  "planEliteFeature2": "Unbegrenzte Bildanalyse",
  "planEliteFeature3": "Prioritäts-Support",
  "planEliteFeature4": "Erweiterter Export",
  "planEliteFeature5": "Multi-Klinik-Support",
  "planHeaderTitle": "All-in-One-Preis, null Aufwand.",
  "planSubHeader": "Jederzeit kündbar. Legen wir los!",
  "planDescription": "Schalte erweiterte Funktionen, unbegrenzte KI-Modelle und Premium-Support frei",
  "planMonthly": "Monatlich",
  "planYearly": "Jährlich",
  "planSavePercent": "20% sparen",
  "planCurrentPlan": "Aktueller Tarif",
  "planGetStarted": "Loslegen",
  "planSubscribeNow": "Jetzt abonnieren",
  "planDowngrade": "Herabstufen",
  "planRecommended": "EMPFEHLUNG",
  "planWhatsIncluded": "Was ist enthalten",
  "planPlanDetails": "{} Tarifdetails",
  "planPaymentOpened": "Zahlungsseite geöffnet. Bitte bestätigen Sie die Zahlung in der App, wenn Sie fertig sind.",
  "planCouldNotOpenPayment": "Zahlungsseite konnte nicht geöffnet werden",
  "planPleaseSignIn": "Bitte melden Sie sich zuerst an",
  "planDowngradeManage": "Um herabzustufen, verwalten Sie Ihr Abonnement in den Einstellungen.",
  "planSubscribedToPlan": "Sie haben diesen Tarif aktuell abonniert.",
  "planPerYear": "/Jahr",
  "planPerMonth": "/Monat"
```

---

## 2. subscription_pricing_page.dart changes

### Replace `_handleUpgrade` method (lines 18-77)
Replace hardcoded SnackBar strings:
```dart
// Line 33:
).showSnackBar(SnackBar(content: SelectionArea(child: Text('planPleaseSignIn'.tr()))));
// Line 59-61:
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: SelectionArea(child: Text('planPaymentOpened'.tr()))),
);
// Line 66:
SnackBar(content: SelectionArea(child: Text('planCouldNotOpenPayment'.tr()))),
```

### Replace build method strings (lines 99-206)
```dart
// Line 100: 'All-In-One Price, Zero Hassle.' → 'planHeaderTitle'.tr()
// Line 109: 'Cancel Anytime...' → 'planSubHeader'.tr()
// Line 117: 'Unlock advanced...' → 'planDescription'.tr()
// Line 136: 'Monthly' → 'planMonthly'.tr()
// Line 139: 'Yearly' → 'planYearly'.tr()
// Line 141: 'Save 20%' → 'planSavePercent'.tr()
// Line 156: 'Free' → 'planFree'.tr()
// Line 159: 'Perfect for trying...' → 'planFreeDesc'.tr()
// Line 161-165: features → ['planFreeFeature1'.tr(), ..., 'planFreeFeature4'.tr()]
//   → Change `const` list to non-const:
//   ```
//   features: [
//     'planFreeFeature1'.tr(),
//     'planFreeFeature2'.tr(),
//     'planFreeFeature3'.tr(),
//     'planFreeFeature4'.tr(),
//   ],
//   ```
// Line 166: 'Current Plan' → 'planCurrentPlan'.tr()
// Line 173: 'Pro' → 'planPro'.tr()
// Line 176: 'Best for...' → 'planProDesc'.tr()
// Line 178-184: features → same pattern with planProFeature1-6
// Line 185: 'Get Started' → 'planGetStarted'.tr()
// Line 191: 'Elite' → 'planElite'.tr()
// Line 194: 'For power users...' → 'planEliteDesc'.tr()
// Line 196-201: features → same pattern with planEliteFeature1-5
// Line 202: 'Get Started' → 'planGetStarted'.tr()
```

### Replace `_PricingCard` price/period strings (line 329-330)
```dart
final priceText = price == 0 ? 'planPriceFree'.tr() : '\$${price.toStringAsFixed(2)}';
final period = widget.isYearly ? 'planPerYear'.tr() : 'planPerMonth'.tr();
```

Also need to add `"planPriceFree": "$0"` to translation files if you want that localized.

### Replace 'RECOMMENDED' (line 381-382)
```dart
child: Text('planRecommended'.tr(),
```

---

## 3. plan_details_page.dart changes

### Replace build method strings
```dart
// Line 112: '\$0' → `'planPriceFree'.tr()` (or add a new key)
// Line 113: '/year' → `'planPerYear'.tr()`, '/month' → `'planPerMonth'.tr()`
// Line 118: '${widget.title} Plan Details' → `'planPlanDetails'.tr(args: [widget.title])`
// Line 147: widget.description → keep as-is, it's now a .tr() key mapped through
// Line 180: 'What\'s Included' → `'planWhatsIncluded'.tr()`
// Line 195: widget.features → keep as-is, they're now .tr() keys mapped
```

### Replace button text (lines 255-259)
```dart
child: Text(
  widget.isCurrent
      ? 'planCurrentPlan'.tr()
      : (widget.title == 'Free'
          ? 'planDowngrade'.tr()
          : 'planSubscribeNow'.tr()),
```

### Replace SnackBar strings (lines 76-77, 236-240)
```dart
// Line 76-77: → 'planPaymentOpened'.tr()
// Line 238-240: → 'planDowngradeManage'.tr()
```

### Replace "You are currently subscribed" (line 272)
```dart
Text("planSubscribedToPlan".tr(),
```

---

## 4. Verify

After all changes: `flutter analyze`

Expected: 0 new issues. All pre-existing warnings/infos unchanged.
be1-6
// Line 185: 'Get Started' → 'planGetStarted'.tr()
// Line 191: 'Elite' → 'planElite'.tr()
// Line 194: 'For power users...' → 'planEliteDesc'.tr()
// Line 196-201: features → same pattern with planEliteFeature1-5
// Line 202: 'Get Started' → 'planGetStarted'.tr()
```

### Replace `_PricingCard` price/period strings (line 329-330)
```dart
final priceText = price == 0 ? 'planPriceFree'.tr() : '\$${price.toStringAsFixed(2)}';
final period = widget.isYearly ? 'planPerYear'.tr() : 'planPerMonth'.tr();
```

Also need to add `"planPriceFree": "$0"` to translation files if you want that localized.

### Replace 'RECOMMENDED' (line 381-382)
```dart
child: Text('planRecommended'.tr(),
```

---

## 3. plan_details_page.dart changes

### Replace build method strings
```dart
// Line 112: '\$0' → `'planPriceFree'.tr()` (or add a new key)
// Line 113: '/year' → `'planPerYear'.tr()`, '/month' → `'planPerMonth'.tr()`
// Line 118: '${widget.title} Plan Details' → `'planPlanDetails'.tr(args: [widget.title])`
// Line 147: widget.description → keep as-is, it's now a .tr() key mapped through
// Line 180: 'What\'s Included' → `'planWhatsIncluded'.tr()`
// Line 195: widget.features → keep as-is, they're now .tr() keys mapped
```

### Replace button text (lines 255-259)
```dart
child: Text(
  widget.isCurrent
      ? 'planCurrentPlan'.tr()
      : (widget.title == 'Free'
          ? 'planDowngrade'.tr()
          : 'planSubscribeNow'.tr()),
```

### Replace SnackBar strings (lines 76-77, 236-240)
```dart
// Line 76-77: → 'planPaymentOpened'.tr()
// Line 238-240: → 'planDowngradeManage'.tr()
```

### Replace "You are currently subscribed" (line 272)
```dart
Text("planSubscribedToPlan".tr(),
```

---

## 4. Verify

After all changes: `flutter analyze`

Expected: 0 new issues. All pre-existing warnings/infos unchanged.
- do it
