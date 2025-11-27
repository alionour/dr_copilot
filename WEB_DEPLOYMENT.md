# Web App Deployment Instructions

## Overview

This guide shows how to build and deploy the Flutter web app to Firebase Hosting, then update the backend to use the deployed URL.

## Prerequisites

- ✅ Flutter web enabled
- ✅ Firebase project configured (`drcopilot-bfc9e`)
- ✅ Firebase CLI installed (`firebase --version`)
- ✅ Backend deployed to AWS

## Step 1: Build Flutter Web App

**Important**: Your app uses API keys from Doppler (Gemini, GPT, Claude, etc.). These must be passed during build.

```bash
cd f:\Ali\Projects\alionour33\dr_copilot

# Build with Doppler secrets
doppler run -- flutter build web --release
```

**Expected output**:
- Doppler loads secrets from environment
- Build completes successfully
- Files generated in `build/web/` directory
- Build time: 2-5 minutes

**What this does**:
- Loads API keys from Doppler (GEMINI_KEY, GPT_KEY, CLAUDE_KEY, etc.)
- Compiles Flutter code to JavaScript with secrets embedded
- Optimizes assets
- Creates static HTML/CSS/JS files
- Output: `build/web/` folder ready for hosting

**Secrets included in build**:
- `GEMINI_KEY`, `GEMINI_KEY_2` - For Gemini AI
- `GPT_KEY` - For OpenAI
- `VERTEX_AI_KEY` - For Google Vertex AI
- `DEEP_SEEK_KEY` - For DeepSeek
- `QWEN_KEY` - For Qwen
- `CLAUDE_KEY` - For Claude
- `DEEPGRAM_KEY` - For Deepgram
- `WEB_CLIENT_ID`, `WEB_CLIENT_SECRET` - For Google Sign-In
- `WEB_REDIRECT_PORT` - For OAuth redirect

## Step 2: Deploy to Firebase Hosting

### Option A: First Time Deployment

If you haven't initialized Firebase Hosting yet:

```bash
cd f:\Ali\Projects\alionour33\dr_copilot

# Initialize Firebase Hosting
firebase init hosting

# When prompted:
# - Select: Use existing project
# - Choose: drcopilot-bfc9e
# - Public directory: build/web
# - Configure as SPA: Yes
# - Set up automatic builds: No
# - Overwrite index.html: No

# Deploy
firebase deploy --only hosting
```

### Option B: Subsequent Deployments

If already initialized (firebase.json exists):

```bash
cd f:\Ali\Projects\alionour33\dr_copilot

# Just deploy
firebase deploy --only hosting
```

**Expected output**:
```
✔ Deploy complete!

Project Console: https://console.firebase.google.com/project/drcopilot-bfc9e/overview
Hosting URL: https://drcopilot-bfc9e.web.app
```

**Your Firebase URLs** (based on project ID):
- Primary: `https://drcopilot-bfc9e.web.app`
- Alternative: `https://drcopilot-bfc9e.firebaseapp.com`

## Step 3: Update Backend APP_URL

After deployment, update the backend to use your Firebase URL:

```bash
cd f:\Ali\Projects\alionour33\dr_copilot\backend

# Set the Firebase URL (use your actual URL from step 2)
doppler secrets set APP_URL "https://drcopilot-bfc9e.web.app"

# Verify it was set
doppler secrets get APP_URL

# Redeploy backend with new URL
doppler run -- npx serverless deploy
```

**Expected output**:
- Doppler confirms APP_URL updated
- Backend redeploys in ~70-90 seconds
- Invitation emails will now use Firebase URL

## Step 4: Verify Deployment

### Test Web App

1. Open browser to: `https://drcopilot-bfc9e.web.app`
2. Should see your login page
3. Test navigation works

### Test Invitation Link

1. Create an invitation from your desktop app
2. Check email - link should be:
   ```
   https://drcopilot-bfc9e.web.app/accept-invitation?token=...
   ```
3. Click link - should open AcceptInvitationPage
4. Verify invitation details display correctly

## Complete Deployment Commands

Here's the full sequence in one place:

```bash
# 1. Build web app with Doppler secrets
cd f:\Ali\Projects\alionour33\dr_copilot
doppler run -- flutter build web --release

# 2. Deploy to Firebase
firebase deploy --only hosting

# 3. Update backend (replace URL with your actual Firebase URL)
cd backend
doppler secrets set APP_URL "https://drcopilot-bfc9e.web.app"
doppler run -- npx serverless deploy

# 4. Test
# Open: https://drcopilot-bfc9e.web.app
```

## Troubleshooting

### Build Fails

**Error**: `Target of URI doesn't exist`
**Fix**: Run `flutter pub get` first

**Error**: `Web is not supported`
**Fix**: Run `flutter config --enable-web`

### Firebase Deploy Fails

**Error**: `Not authorized`
**Fix**: Run `firebase login`

**Error**: `Project not found`
**Fix**: Run `firebase use drcopilot-bfc9e`

### Web App Shows Blank Page

**Check**:
1. Browser console (F12) for errors
2. Ensure `build/web/index.html` exists
3. Try clearing browser cache
4. Redeploy: `firebase deploy --only hosting`

### Invitation Links Don't Work

**Check**:
1. APP_URL in Doppler matches Firebase URL
2. Backend redeployed after APP_URL change
3. Email link format: `https://your-app.web.app/accept-invitation?token=...`

## Firebase Hosting Features

### View Deployment History

```bash
firebase hosting:channel:list
```

### Rollback to Previous Version

```bash
firebase hosting:clone SOURCE_SITE_ID:SOURCE_CHANNEL_ID TARGET_SITE_ID:live
```

### View Hosting Logs

Go to: https://console.firebase.google.com/project/drcopilot-bfc9e/hosting

## Custom Domain (Optional)

If you want to use a custom domain like `drcopilot.com`:

1. Go to Firebase Console → Hosting
2. Click "Add custom domain"
3. Follow DNS configuration steps
4. Update APP_URL to your custom domain
5. Redeploy backend

## Environment-Specific URLs

For different environments:

```bash
# Development
doppler secrets set APP_URL "http://localhost:3000" --config dev

# Staging
doppler secrets set APP_URL "https://drcopilot-staging.web.app" --config staging

# Production
doppler secrets set APP_URL "https://drcopilot-bfc9e.web.app" --config prod
```

## Continuous Deployment (Optional)

Set up GitHub Actions to auto-deploy on push:

1. Create `.github/workflows/deploy.yml`
2. Add Firebase token: `firebase login:ci`
3. Add token to GitHub Secrets
4. Push to trigger deployment

## Summary

**Build**: `doppler run -- flutter build web --release` (includes API keys)  
**Deploy**: `firebase deploy --only hosting`  
**Update Backend**: `doppler secrets set APP_URL "https://drcopilot-bfc9e.web.app"`  
**Redeploy Backend**: `doppler run -- npx serverless deploy`  

**Your URLs**:
- Web App: `https://drcopilot-bfc9e.web.app`
- Backend API: `https://hg4orotvf0.execute-api.us-east-1.amazonaws.com`

**Important**: The web app needs Doppler secrets at build time for AI API keys (Gemini, GPT, Claude, etc.). These are embedded in the compiled JavaScript. The backend uses separate Doppler secrets for Firebase and SES.
