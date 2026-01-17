# Dr. Copilot - Project Documentation

This document provides a comprehensive overview of the Dr. Copilot application, including its architecture, features, and setup instructions.

## Table of Contents

1.  [Project Overview and Architecture](#1-project-overview-and-architecture)
2.  [Developer Onboarding Guide](01_Developer_Onboarding_Guide.md)
3.  [Feature Documentation](02_Feature_Documentation.md)
4.  [API and Data Model Documentation](03_API_and_Data_Model_Documentation.md)

## 1. Project Overview and Architecture

Dr. Copilot is a comprehensive clinic management application built with Flutter. It is designed to assist healthcare professionals in managing their clinic's operations efficiently.

**Key Features:**

*   **Patient and Staff Management:** Manage patient records and staff information.
*   **Appointment Scheduling:** A robust appointment scheduling system using Syncfusion Calendar.
*   **Clinical Reporting:** Generate and manage clinical reports.
*   **Financial Tracking:** Tools for managing clinic finances.
*   **AI Copilot:** An advanced AI-powered voice and text assistant to help with various tasks. It supports multiple AI models like Gemini, GPT, and Claude.

### 1.1. Architecture

The application follows a clean, modular, and feature-based architecture.

#### 1.1.1. Project Structure

The project is organized into features, with each feature being a self-contained module. The main source code is located in `lib/src`.

*   `lib/src/core`: Contains the core functionalities of the application, such as routing, dependency injection, and global state management.
*   `lib/src/features`: Each subdirectory in this folder represents a feature of the application (e.g., `auth`, `patients`, `appointments`).
*   `lib/src/shared`: Contains shared widgets, utilities, and other code that is used across multiple features.

#### 1.1.2. State Management

The application uses a hybrid state management approach:

*   **Provider:** Used for managing global application state.
*   **BLoC (Business Logic Component):** Used for managing the state of individual features. This keeps the business logic separated from the UI and allows for more complex state management within features.

#### 1.1.3. Navigation

Navigation is handled using the `go_router` package. The routing configuration can be found in `lib/src/core/router/routing_config.dart`.

#### 1.1.4. Dependency Injection

The `get_it` package is used for service location and dependency injection. The main dependency injection setup is in `lib/src/core/injections.dart`, with each feature having its own injection configuration file (e.g., `lib/src/features/auth/auth_injections.dart`).

#### 1.1.5. Backend

The backend is powered by Firebase:

*   **Firebase Authentication:** Used for user authentication (login, registration).
*   **Firestore:** Used as the primary database for storing application data like patient records, appointments, etc.

#### 1.1.6. AI Copilot

The AI Copilot is a key feature of the application. It is designed to be provider-agnostic, with services for:

*   Gemini
*   GPT
*   Claude
*   VertexAI

It also uses `speech_to_text` and `deepgram_speech_to_text` for voice input.
