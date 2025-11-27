# Web App Security - API Keys

## The Problem

When building a Flutter web app, API keys passed via `--dart-define` get compiled into the JavaScript bundle. This means anyone can:
1. Open browser DevTools
2. Search through the JavaScript files
3. Find your API keys

## Current Situation

For the **invitation acceptance flow**, the web app needs:
- ✅ `WEB_CLIENT_ID` - Google OAuth (safe, meant to be public)
- ❌ `GEMINI_KEY` - AI service (risky if exposed)
- ❌ `GPT_KEY` - AI service (risky if exposed)
- ❌ `DEEPGRAM_KEY` - Speech-to-text (risky if exposed)

## Recommended Solution

### Option 1: Minimal Web App (Best for Invitation Flow)

Build the web app **without AI features**. The invitation acceptance flow doesn't need AI:

```bash
flutter build web --release \
  --dart-define=WEB_CLIENT_ID=253522261255-cb415bhb6n4ni58mqslcqhq7547gqmbb.apps.googleusercontent.com
```

**What works**:
- ✅ Accept invitations
- ✅ Sign up with Google
- ✅ Firebase Authentication
- ✅ Backend API calls

**What doesn't work**:
- ❌ AI chat features (not needed for invitations)
- ❌ Speech-to-text (not needed for invitations)

### Option 2: Backend Proxy (Best for Full Features)

Move all AI API calls to your backend:

```javascript
// Backend route
router.post('/ai/chat', async (req, res) => {
  const { message } = req.body;
  
  // Use API key from environment (secure)
  const response = await callGeminiAPI(process.env.GEMINI_KEY, message);
  
  res.json(response);
});
```

```dart
// Flutter web app
Future<String> chatWithAI(String message) async {
  // No API key needed in web app!
  final response = await http.post(
    Uri.parse('$backendUrl/ai/chat'),
    body: json.encode({'message': message}),
  );
  return response.body;
}
```

### Option 3: Separate Builds

- **Desktop build**: Full features with all API keys (from Doppler)
- **Web build**: Limited features, only public keys

## Security Best Practices

### Safe to Expose
- ✅ Google OAuth Client ID (`WEB_CLIENT_ID`)
- ✅ Firebase Config (project ID, API key)
- ✅ Public API endpoints

### Never Expose
- ❌ API keys with billing (Gemini, GPT, Claude)
- ❌ Database credentials
- ❌ Service account keys
- ❌ Secret tokens

## Recommendation for Your App

**For now (invitation flow only)**:
```bash
# Build with minimal keys
flutter build web --release \
  --dart-define=WEB_CLIENT_ID=YOUR_CLIENT_ID
```

**For future (full web app)**:
1. Create backend proxy routes for AI services
2. Keep API keys on backend only
3. Web app calls backend, backend calls AI services

## Current Risk Level

If you deploy with all API keys:
- 🟡 **Medium Risk**: Someone could extract and abuse your API keys
- 💰 **Financial Impact**: Potential unauthorized usage charges
- 🔒 **Mitigation**: Set usage quotas and monitor API usage

## Action Items

1. ✅ Use minimal build for invitation flow (only WEB_CLIENT_ID)
2. ⏳ Set up API usage quotas in Google Cloud Console
3. ⏳ Monitor API usage regularly
4. 🔄 For full features, implement backend proxy
