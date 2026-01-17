# Bot Account OAuth Setup Instructions

## What You Need

You'll need to add **3 secrets** to Doppler for the bot account OAuth to work:

1. `GOOGLE_OAUTH_CLIENT_ID` - From Google Cloud Console
2. `GOOGLE_OAUTH_CLIENT_SECRET` - From Google Cloud Console  
3. `GOOGLE_REFRESH_TOKEN` - From running the setup tool

---

## Step-by-Step Setup

### 1. Create Bot Google Account (5 minutes)

Create a dedicated Google account for your app:

```
Email: drcopilot.reports@gmail.com (or similar)
Password: [Strong password - save it securely]
```

This account will store all clinical report documents (15GB free).

---

### 2. Get OAuth Credentials from Google Cloud (10 minutes)

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your project: `drcopilot-bfc9e`
3. Go to **APIs & Services** → **Credentials**

#### Update OAuth Consent Screen:
- Click **OAuth consent screen**
- **Publishing status**: Set to **"In production"** (not "Testing")
  - This is CRITICAL - tokens expire in 7 days if left in "Testing"
- **Scopes**: Ensure these are added:
  - `https://www.googleapis.com/auth/drive.file`
  - `https://www.googleapis.com/auth/documents`

#### Create/Update OAuth Client:
- Click **Create Credentials** → **OAuth client ID**
- **Application type**: Web application
- **Name**: Dr Copilot OAuth Client
- **Authorized redirect URIs**: Add `http://localhost:8080/auth/callback`
- Click **Create**
- **Download JSON** or copy the credentials

You should now have:
- **Client ID**: `123456789-abc.apps.googleusercontent.com`
- **Client Secret**: `GOCSPX-xxxxxxx`

---

### 3. Add OAuth Credentials to Doppler (2 minutes)

```bash
# Add Client ID
doppler secrets set GOOGLE_OAUTH_CLIENT_ID="YOUR_CLIENT_ID_HERE"

# Add Client Secret  
doppler secrets set GOOGLE_OAUTH_CLIENT_SECRET="YOUR_CLIENT_SECRET_HERE"
```

Or use the Doppler dashboard to add them.

---

### 4. Run OAuth Setup Tool (5 minutes)

Now run the setup tool to get the refresh token:

```bash
doppler run -- dart run tools/oauth_setup.dart
```

**What happens:**
1. Browser opens to Google sign-in
2. **IMPORTANT**: Sign in with your **BOT account** (drcopilot.reports@gmail.com)
3. Grant permissions when prompted
4. Terminal will display the refresh token

**Copy the refresh token** - it looks like:
```
1//0gEVs_QYkRm8hCgYIARAAGBASNwF-L9IrXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

---

### 5. Store Refresh Token in Doppler (1 minute)

```bash
doppler secrets set GOOGLE_REFRESH_TOKEN="PASTE_YOUR_REFRESH_TOKEN_HERE"
```

**Security Note:** The refresh token is sensitive! Never commit it to git or share it.

---

### 6. Restart Your App

```bash
doppler run -- flutter run -d windows
```

The app will now automatically use the OAuth credentials from Doppler.

---

## Testing

1. **Create a clinical report**
2. **Fill in patient and title**
3. **Click Save**
4. Document should be created in bot account's Drive
5. WebView should load with Google Docs editor

Check the console for logs like:
```
[GoogleOAuthTokenService] Loading refresh token from environment...
[GoogleOAuthTokenService] Refresh token loaded successfully
[GoogleOAuthTokenService] Exchanging refresh token for access token...
[GoogleOAuthTokenService] Access token refreshed successfully
[GoogleDocsService] Creating document with title: Clinical Report - 5 Dec 2025
[GoogleDocsService] Document created with ID: 1abc...
```

---

## Verify in Bot Account

1. Sign in to the bot account: drcopilot.reports@gmail.com
2. Go to [Google Drive](https://drive.google.com)
3. You should see the created documents!

---

## Troubleshooting

### "GOOGLE_REFRESH_TOKEN not found in environment"
- Run: `doppler secrets` to list all secrets
- Make sure you added the refresh token to Doppler
- Restart your app after adding secrets

### "Token refresh failed"
- Check that Client ID and Client Secret are correct
- Ensure OAuth consent screen is in "Production" mode
- Try running `oauth_setup.dart` again to get a fresh token

### "The caller does not have permission" (403)
- This should NOT happen anymore with this approach
- If it does, verify the bot account is the one that got the refresh token
- Check that Drive and Docs APIs are enabled

---

## Security Best Practices

✅ **DO:**
- Store tokens only in Doppler (encrypted)
- Use strong password for bot account
- Enable 2FA on bot account (optional)
- Monitor bot account for unauthorized access
- Rotate refresh token if compromised

❌ **DON'T:**
- Never commit tokens to git
- Never log refresh tokens
- Never share bot account credentials
- Never use personal Google account as bot account

---

## Summary

After completing these steps, you'll have:

✅ Bot Google account with 15GB storage  
✅ OAuth credentials in Doppler  
✅ Refresh token in Doppler  
✅ Automatic token refresh working  
✅ Google Docs creation working  

**Total time:** ~25 minutes one-time setup

All clinical reports will now be created automatically in the bot account's Drive without any user sign-in! 🎉
