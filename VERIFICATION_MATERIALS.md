# Google App Verification Materials

This document contains all necessary materials for submitting Dr Copilot for Google App Verification.

---

## Required URLs

### Privacy Policy
**URL:** `https://hg4orotvf0.execute-api.us-east-1.amazonaws.com/privacy_policy.html`

### Terms of Service
**URL:** `https://hg4orotvf0.execute-api.us-east-1.amazonaws.com/terms_of_service.html`

---

## OAuth Scopes Justification

Dr Copilot requests the following Google OAuth scopes:

### 1. Google Drive (drive.file) - **SENSITIVE SCOPE**
**Scope:** `https://www.googleapis.com/auth/drive.file`

**Justification:**
Dr Copilot is a clinical documentation tool for healthcare professionals. We need access to Google Drive to:
- **Create Google Docs** for clinical reports directly within the user's Google Drive
- **Edit and manage** clinical reports that the app has created
- **Delete** outdated or finalized clinical reports when requested by the user

**Key Points:**
- We use the **`drive.file`** scope (NOT full `drive` access)
- This means we can ONLY access files that Dr Copilot itself creates
- We **cannot** see, access, or modify any other files in the user's Drive
- This is a privacy-conscious choice that limits our access to the minimum necessary

**User Benefit:**
- Users get seamless clinical documentation stored in their own Google Drive
- All documents are owned by the user, not locked in a proprietary system
- Users can access their reports from any device with Google Drive

---

### 2. Google Calendar - **SENSITIVE SCOPE**
**Scopes:** 
- `https://www.googleapis.com/auth/calendar`
- `https://www.googleapis.com/auth/calendar.events`
- `https://www.googleapis.com/auth/calendar.readonly`
- `https://www.googleapis.com/auth/calendar.events.readonly`
- `https://www.googleapis.com/auth/calendar.settings.readonly`

**Justification:**
Healthcare professionals need to manage appointments and schedules efficiently. We need access to Google Calendar to:
- **Create appointments** for patient consultations
- **View existing events** to prevent scheduling conflicts
- **Update/delete appointments** as patient schedules change

**User Benefit:**
- Integrated scheduling without switching between apps
- Automatic conflict detection
- Seamless workflow for busy healthcare professionals

---

## Video Demo Script (If Required)

> **Note:** For `drive.file` scope (as opposed to full `drive`), Google *may* still require a video demonstration, but the requirements are less stringent than for Restricted scopes.

### Video Outline (2-3 minutes)

1. **Introduction (15 seconds)**
   - "Hi, I'm demonstrating Dr Copilot, a clinical documentation assistant for healthcare professionals."

2. **Sign-In Flow (30 seconds)**
   - Show the app's sign-in screen
   - Click "Sign in with Google"
   - Show the OAuth consent screen highlighting the scopes requested
   - Complete sign-in

3. **Google Drive Usage (60 seconds)**
   - Navigate to the "Clinical Reports" section
   - Click "Create New Report"
   - Show the app creating a Google Doc in the user's Drive
   - Demonstrate editing the clinical report within the app
   - Show the Google Docs editor (can be in a webview or external browser)
   - Navigate to Google Drive separately and show the created file
   - Explain: "Notice that Dr Copilot can only see files it created, not other files in your Drive"

4. **Google Calendar Usage (45 seconds)**
   - Navigate to the "Schedule" or "Calendar" section
   - Create a new appointment for a patient
   - Show the app writing to Google Calendar
   - Open Google Calendar separately and verify the event appears
   - Demonstrate editing/deleting an appointment

5. **Data Privacy (15 seconds)**
   - "All data stays in your Google account. Dr Copilot cannot access files it didn't create."

---

## Submission Checklist

Before submitting to Google:

- [x] Privacy Policy URL is live and accessible
- [x] Terms of Service URL is live and accessible
- [x] OAuth scopes have been downgraded to `drive.file` (NOT full `drive`)
- [ ] Record video demonstration (if required)
- [ ] Upload video to YouTube (Unlisted is fine)
- [ ] Prepare written explanation of scope usage (see above)
- [ ] Ensure app developer email is `nourrehabcenter@gmail.com`

---

## Submitting for Verification

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Navigate to **APIs & Services** > **OAuth consent screen**
4. Click **Publish App** (if not already published)
5. Click **Prepare for Verification** or **Submit for Verification**
6. Fill in the form:
   - **Privacy Policy URL:** `https://hg4orotvf0.execute-api.us-east-1.amazonaws.com/privacy_policy.html`
   - **Terms of Service URL:** `https://hg4orotvf0.execute-api.us-east-1.amazonaws.com/terms_of_service.html`
   - **YouTube Video Link:** (If required)
   - **Scope Justification:** Copy the text from this document
7. Submit and wait for review (typically 3-7 business days for Sensitive scopes)

---

## Expected Timeline

- **Sensitive Scopes (drive.file, calendar):** 3-7 business days
- **Review Contact:** Google may email `nourrehabcenter@gmail.com` for clarification

---

## Troubleshooting

### If verification is rejected:
1. Read the rejection email carefully
2. Address specific concerns raised
3. Resubmit with updated information

### Common issues:
- **Video not clear enough:** Re-record with better screen capture quality
- **Scope justification unclear:** Be more specific about *why* you need each scope
- **Privacy policy missing details:** Ensure it explicitly mentions Google API data usage
