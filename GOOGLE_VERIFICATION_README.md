# Resolving "Google hasn't verified this app" Warning

The warning you are seeing is standard behavior for Google OAuth when an app requests **sensitive scopes** (like Google Drive, Google Docs, and Calendar) but hasn't gone through Google's verification process.

Since your app currently requests full access to Drive and Docs (as seen in `google_signin_helper.dart`), Google blocks unauthorized users from signing in unless they are explicitly added as testers.

## Option 1: Development & Testing (Immediate Fix)

If you are still developing the app and only you or a small team needs to sign in, you can bypass this screen by adding **Test Users**.

1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Select your project (`dr-copilot` or similar).
3. Navigate to **APIs & Services** > **OAuth consent screen**.
4. Under **User Type**, make sure it is set to **External**.
5. Scroll down to the **Test users** section.
6. Click **+ ADD USERS**.
7. Enter your email address (e.g., `nourrehabcenter@gmail.com`) and the emails of anyone else testing the app.
8. Click **Save**.

**Result:** Users in this list can sign in. They may still see a warning, but they will have a "Continue" button (hidden under "Advanced") to proceed.

## Option 2: Production (Remove Screen for Everyone)

If you are releasing this app to the public, you must verify the app. This process can take several weeks.

1. Go to **APIs & Services** > **OAuth consent screen**.
2. Click **Publish App**.
3. You will need to submit:
   - **Privacy Policy URL**.
   - **Terms of Service URL**.
   - **YouTube Video** showing how you use the data.
   - **Written explanation** of why you need these scopes.
4. Google Trust & Safety team will review your submission.

## Advanced: Proceeding Past the Warning

If you are just testing and see the warning:
1. Click **Advanced** (usually vaguely labeled text).
2. Click **Go to [App Name] (unsafe)** at the bottom.
3. This will allow you to grant permissions and sign in.
