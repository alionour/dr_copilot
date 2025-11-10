# Feature Documentation

This document provides an overview of the features in the Dr. Copilot application.

## Features

*   [Appointments](#appointments)
*   [Auth](#auth)
*   [Calendar](#calendar)
*   [Charts](#charts)
*   [Clinical Reports](#clinical-reports)
*   [Copilot Chat](#copilot-chat)
*   [Doctors](#doctors)
*   [Financials](#financials)
*   [Home](#home)
*   [Live Voice Assistant](#live-voice-assistant)
*   [Navigation Side](#navigation-side)
*   [Notifications](#notifications)
*   [Patients](#patients)
*   [Settings](#settings)
*   [Staff](#staff)

---

### Appointments

**Purpose:** Manages patient appointments.

The appointments feature is divided into two sub-features:

*   **Evaluations:** Manages the evaluation of patients.
*   **Sessions:** Manages appointment sessions.

Both sub-features follow the standard `data`, `domain`, and `presentation` structure.

---

### Auth

**Purpose:** Handles user authentication (login, registration, password reset).

**Key Components:**
*   `auth_injections.dart`: Handles dependency injection for the auth feature.
*   `data/`: Contains the data layer, including the Firebase API for authentication and data models.
*   `domain/`: Contains the business logic (use cases) and entities for authentication.
*   `presentation/`: Contains the UI for the authentication screens (login, signup) and the BLoC for state management.

---

### Calendar

**Purpose:** Provides a calendar view for appointments and schedules.

---

### Charts

**Purpose:** Displays charts and graphs for data visualization.

---

### Clinical Reports

**Purpose:** Manages clinical reports for patients.

---

### Copilot Chat

**Purpose:** Provides a chat interface for the AI Copilot.

---

### Doctors

**Purpose:** Manages doctor information.

---

### Financials

**Purpose:** Manages financial data and reporting.

---

### Home

**Purpose:** The main dashboard or home screen of the application.

---

### Live Voice Assistant

**Purpose:** Provides a live voice assistant powered by AI.

---

### Navigation Side

**Purpose:** The side navigation bar of the application.

---

### Notifications

**Purpose:** Manages and displays notifications.

---

### Patients

**Purpose:** Manages patient information and records.

---

### Settings

**Purpose:** Provides application settings for the user.

---

### Staff

**Purpose:** Manages staff information and roles.
