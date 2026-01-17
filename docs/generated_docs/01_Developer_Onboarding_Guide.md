# Developer Onboarding Guide

This guide provides instructions for setting up the development environment for the Dr. Copilot application.

## 1. Prerequisites

*   **Flutter SDK:** Make sure you have the Flutter SDK installed. You can find the installation instructions on the [official Flutter website](https://flutter.dev/docs/get-started/install).
*   **Firebase Account:** You will need a Firebase project to connect the application to Firebase services.
*   **IDE:** An IDE like Visual Studio Code or Android Studio with the Flutter plugin.

## 2. Project Setup

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd dr_copilot
    ```

2.  **Configure Firebase:**
    *   Follow the instructions to add Firebase to your Flutter app for [Android](https://firebase.google.com/docs/flutter/setup?platform=android) and [iOS](https://firebase.google.com/docs/flutter/setup?platform=ios).
    *   You will need to place your `google-services.json` file in `android/app/` and `GoogleService-Info.plist` in `ios/Runner/`.
    *   Enable Firebase Authentication and Firestore in your Firebase project console.

3.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

## 3. Running the Application

You can run the application using the following command:

```bash
flutter run
```

To run on a specific device, use the `-d` flag:

```bash
flutter run -d <device-id>
```

## 4. Code Generation

The project uses code generation for some tasks. If you make changes to files that require code generation, run the following command:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 5. Project Structure

For an overview of the project structure and architecture, please refer to the [Project Overview and Architecture](README.md#1-project-overview-and-architecture) section in the main documentation.
