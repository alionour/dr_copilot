# Firebase Deployment - Node.js Compatibility Issue

## Problem

Firebase CLI is not compatible with Node.js v25.0.0. You're getting this error:
```
TypeError: Cannot read properties of undefined (reading 'prototype')
```

## Solution Options

### Option 1: Use NVM to Switch Node Version (Recommended)

Install and use Node.js v24 (LTS):

```bash
# Install NVM for Windows if not installed
# Download from: https://github.com/coreybutler/nvm-windows/releases

# Install Node.js 24 (LTS)
nvm install 24

# Use Node.js 24
nvm use 24

# Verify version
node --version  # Should show v24.x.x

# Now deploy
cd f:\Ali\Projects\alionour33\dr_copilot
firebase deploy --only hosting
```

### Option 2: Manual Upload to Firebase Console

Since the web app is already built in `build/web/`, you can manually upload:

1. Go to: https://console.firebase.google.com/project/drcopilot-bfc9e/hosting
2. Click "Get started" or "Add another site"
3. Drag and drop the `build/web` folder
4. Get your hosting URL

### Option 3: Use Firebase Hosting GitHub Action

Set up automatic deployment via GitHub Actions (bypasses local Node version):

1. Push your code to GitHub
2. Add `.github/workflows/firebase-hosting.yml`:
```yaml
name: Deploy to Firebase Hosting
on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter build web --release
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: drcopilot-bfc9e
```

## Quick Fix for Now

### Use the Built Files

Your web app is already built! The files are in:
```
f:\Ali\Projects\alionour33\dr_copilot\build\web\
```

You can:
1. **Test locally**: Open `build/web/index.html` in a browser
2. **Host elsewhere**: Upload to any static hosting (Netlify, Vercel, GitHub Pages)
3. **Wait for Node fix**: Downgrade Node.js or wait for Firebase CLI update

## Temporary Workaround: Update APP_URL Anyway

Even without deploying, you can update the backend to use localhost for testing:

```bash
cd f:\Ali\Projects\alionour33\dr_copilot\backend

# For local testing
doppler secrets set APP_URL "http://localhost:3000"
doppler run -- npx serverless deploy

# Test locally
cd ..
flutter run -d chrome
```

## When Firebase Deploy Works

After switching to Node.js 24 or using manual upload:

1. Get your Firebase URL (e.g., `https://drcopilot-bfc9e.web.app`)
2. Update backend:
```bash
cd backend
doppler secrets set APP_URL "https://drcopilot-bfc9e.web.app"
doppler run -- npx serverless deploy
```

## Current Status

✅ **Web app built successfully** - Files in `build/web/`  
❌ **Firebase deploy blocked** - Node.js v25 incompatibility  
✅ **Backend ready** - Just needs APP_URL update  

## Recommended Next Step

**Install NVM and switch to Node.js 24**, then deploy:

```bash
# After installing NVM
nvm install 24
nvm use 24
cd f:\Ali\Projects\alionour33\dr_copilot
firebase deploy --only hosting
```

This will resolve the compatibility issue permanently.
