# Setup Instructions for Backend Deployment

## Required Environment Variables

You need to add the following secrets to Doppler before deployment:

### 1. FIREBASE_SERVICE_ACCOUNT

**How to get it:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `drcopilot-bfc9e`
3. Click the gear icon ⚙️ > Project Settings
4. Go to "Service Accounts" tab
5. Click "Generate New Private Key"
6. Download the JSON file
7. Convert it to a single-line string (remove all newlines and spaces)

**Add to Doppler:**
```bash
# Option 1: If you have the JSON file
doppler secrets set FIREBASE_SERVICE_ACCOUNT "$(cat path/to/service-account.json | jq -c .)"

# Option 2: Manual (copy the minified JSON)
doppler secrets set FIREBASE_SERVICE_ACCOUNT '{"type":"service_account","project_id":"drcopilot-bfc9e",...}'
```

### 2. SES_FROM_EMAIL

**How to set it up:**
1. Go to [AWS SES Console](https://console.aws.amazon.com/ses/) (us-east-1 region)
2. Click "Verified Identities" in the left menu
3. Click "Create Identity"
4. Choose "Email address" and enter your email (e.g., `no-reply@yourdomain.com`)
5. Verify the email by clicking the link sent to your inbox
6. Once verified, add it to Doppler

**Add to Doppler:**
```bash
doppler secrets set SES_FROM_EMAIL "your-verified-email@domain.com"
```

### 3. APP_URL

**Already set!** ✓ Set to `http://localhost:3000`

You can update it later for production:
```bash
doppler secrets set APP_URL "https://your-production-domain.com"
```

### 4. WEB_CLIENT_ID (for Flutter Web)

This is needed to run the Flutter app on the web with Google Sign-In.

**How to get it:**
1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Navigate to **APIs & Services > Credentials**.
3. Under "OAuth 2.0 Client IDs", copy the Client ID for your **Web application**.

**Value:**
`991809114105-7st6rs7ntt1a8j2rdp8iveffjhobsn93.apps.googleusercontent.com`

**Usage:**
This is not stored in Doppler. It's passed as a compile-time variable when running the app:
```bash
--dart-define=WEB_CLIENT_ID=991809114105-7st6rs7ntt1a8j2rdp8iveffjhobsn93.apps.googleusercontent.com
```

## Next Steps

After adding these secrets to Doppler, I'll proceed with the deployment automatically.
