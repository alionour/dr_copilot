# Google Play Auto-Deploy to Internal Testing - Setup Guide

## ✅ What's Been Done

Created GitHub Actions workflow (`.github/workflows/deploy-android-dev.yaml`) that:
- Triggers automatically on pushes to `dev` branch
- Auto-increments build number using commit count
- Builds signed Android App Bundle (.aab)
- Uploads to Google Play internal testing track

## 🔗 Critical URLs (Quick Links)

| Type | URL |
|------|-----|
| **Privacy Policy** | `https://drcopilot-bfc9e.web.app/privacy_policy.html` |
| **Web App** | `https://drcopilot-bfc9e.web.app/` |
| **Backend API** | `https://hg4orotvf0.execute-api.us-east-1.amazonaws.com` |
| **Play Console** | [Google Play Console](https://play.google.com/console/) |

## 🔧 What You Need to Do

### 1. Create Google Play Service Account

**In Google Cloud Console:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **IAM & Admin** → **Service Accounts**
3. Click **Create Service Account**
   - Name: `github-actions-deploy`
   - Description: `Automated Android deployment from GitHub Actions`
4. Click **Create and Continue**
5. Skip role assignment (will do in Play Console)
6. Click **Done**
7. Click on the created service account
8. Go to **Keys** tab
9. Click **Add Key** → **Create New Key**
10. Choose **JSON** format
11. Save the downloaded JSON file securely

### 2. Grant Permissions in Google Play Console

**In Google Play Console:**
1. Go to [Google Play Console](https://play.google.com/console/)
2. Navigate to **Setup** → **API access**
3. If not already linked, click **Link** to connect your Google Cloud Project
4. Find your service account in the list
5. Click **Grant Access**
6. Select permissions:
   - **Admin (all permissions)** OR
   - **Release Manager** (recommended - minimum required)
7. Click **Invite User**
8. Click **Send Invite**

⚠️ **Important**: Permission changes can take **24-48 hours** to propagate!

### 3. Add GitHub Secret

**In GitHub Repository:**
1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
5. Value: Paste the **entire content** of the JSON file you downloaded
6. Click **Add secret**

### 4. Verify Package Name

Ensure the package name in the workflow matches your app:
- Workflow uses: `com.alionour.drcopilot`
- Verify in `android/app/build.gradle` under `applicationId`
- If different, update the workflow file

### 5. Create Internal Testing Track (if not exists)

**In Google Play Console:**
1. Go to your app → **Testing** → **Internal testing**
2. Click **Create new release** (if no releases exist)
3. Upload any .aab manually for the first time
4. Add release notes
5. Click **Save** and **Review release**
6. Click **Start rollout to Internal testing**

## 🧪 Testing the Workflow

### Option 1: Push to Dev Branch
```bash
git checkout dev
git pull
# Make a small change
echo "# Test" >> README.md
git add README.md
git commit -m "test: trigger internal testing deployment"
git push origin dev
```

### Option 2: Manual Trigger
1. Go to GitHub → **Actions** tab
2. Select **Deploy Android to Google Play Internal Testing**
3. Click **Run workflow**
4. Select `dev` branch
5. Click **Run workflow**

## 📊 Monitoring Deployment

### In GitHub Actions
1. Go to **Actions** tab
2. Look for the running workflow
3. Click to view logs
4. Verify all steps pass (especially "Upload to Google Play")

### In Google Play Console
1. Go to **Testing** → **Internal testing**
2. Check **Releases** tab
3. New build should appear with auto-incremented version
4. Status should show as "Available"

## ⚠️ Troubleshooting

### "Service account not found" or "Permission denied"
- Wait 24-48 hours after granting permissions
- Verify service account email matches exactly
- Check permissions were granted in Play Console

### "Package name not found"
- Verify `com.alionour.drcopilot` matches your app
- Check if app is published (at least in closed testing)

### Build number conflicts
- Each build must have unique version code
- Auto-increment should handle this
- Manual builds in console might cause conflicts

### Missing mapping file
- ProGuard mapping files are optional for internal testing
- Workflow will continue even if mapping.txt is missing

## 📝 Release Notes

Release notes are stored in `android/release-notes/en-US/default.txt`

To customize per release:
1. Create `whatsnew-en-US` file in release-notes directory
2. Add release-specific notes
3. Workflow will use these instead of default

## 🎯 Next Steps

After successful deployment:

1. **Add Internal Testers**
   - Go to **Testing** → **Internal testing**
   - Click **Testers** tab
   - Create email list or use Google Group
   - Add testers

2. **Share Testing Link**
   - Copy opt-in URL from testers page
   - Share with your testing team
   - They can install via Play Store

3. **Monitor Feedback**
   - Check pre-launch reports
   - Review crash analytics
   - Gather tester feedback

## 🔄 Regular Usage

Once set up, the workflow runs automatically:
1. Develop features on feature branches
2. Merge to `dev` branch
3. Workflow deploys to internal testing automatically
4. Testers receive update via Play Store
5. Gather feedback
6. Repeat!

## 🚀 Production Deployment

When ready for production:
1. Test thoroughly in internal testing
2. Promote to closed testing (optional)
3. Use existing `deploy-android.yaml` for production
4. Tag release: `git tag v1.0.0 && git push --tags`

## 📞 Support

If you encounter issues:
- Check GitHub Actions logs
- Review Google Play Console error messages
- Verify all secrets are correctly set
- Ensure 24-48 hour waiting period for permissions

---

**🎉 Once set up, you'll have automatic deployments to internal testing on every dev branch push!**
