# Dr Copilot

Dr Copilot is a comprehensive application designed to assist doctors in managing their clinics, appointments, and providing AI chat support to discuss patient cases. This document provides a detailed overview of the app's features, setup instructions, and usage guidelines.

---

## Features

### Authentication
- **Google Sign-In**: Users can sign in using their Google account.
- **Supabase Integration**: Authentication is managed using Supabase for secure and scalable user management.

### Navigation
- **Side Menu**: A side menu for easy navigation between different sections of the app.
- **Routing**: Managed using `go_router` for seamless navigation and route management.

### Calendar
- **Calendar Page**: View and manage clinic appointments with an intuitive calendar interface.

### Notifications
- **Notifications Page**: View and manage notifications to stay updated on important events.

### Settings
- **Settings Page**: Customize app settings, including themes, language preferences, and more.

### Copilot
- **Copilot Page**: A unique feature where doctors can interact with Dr Copilot, a digital assistant that provides AI chat support to discuss patient cases and assist with various tasks.

### Patients
- **Patients Page**: View and manage patient information, including medical history and contact details.
- **Patient Search**: Search for patients using a search bar with suggestions for quick access.

### Financials
- **Financials Page**: Manage clinic finances, including income, expenses, and financial reports.

### Appointments
- **Sessions Management**: View, edit, and manage appointment sessions.
- **Evaluations Management**: Manage patient evaluations and related data.

### AI Integration
- **AI Chat Support**: Use AI to discuss patient cases and provide insights.
- **Integration with Vertex AI, GPT, and other AI services**: Enhance decision-making and automate tasks.

### Localization
- **Multi-Language Support**: Supports English and Arabic with easy localization for a global user base.

### Security
- **Secrets Management with Doppler**: Securely manage API keys and other sensitive data using Doppler.

---

## Setup Instructions

### Prerequisites
- **Flutter SDK**: Ensure Flutter is installed on your system. [Flutter Installation Guide](https://flutter.dev/docs/get-started/install)
- **Doppler CLI**: Install the Doppler CLI for managing secrets. [Doppler CLI Installation Guide](https://docs.doppler.com/docs/cli-installation)
- **Firebase**: Set up Firebase for authentication and other backend services. [Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup)

### Project Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/dr_copilot.git
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

