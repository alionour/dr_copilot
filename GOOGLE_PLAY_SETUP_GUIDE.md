# Step-by-Step Guide: Google Play Auto-Deployment Setup (27 Steps)

## 📋 Prerequisites Checklist

Before starting, ensure you have:
- [ ] Google Play Console account with your app published (at least in internal testing)
- [ ] Google Cloud Platform account (same Google account as Play Console)
- [ ] GitHub repository access with admin permissions
- [ ] Your app's package name: `com.alionour.drcopilot`

---

## Part 1: Create Google Cloud Service Account

### Step 1: Access Google Cloud Console

> [!NOTE]
> You can use a **different Google account** for Google Cloud Console than for Google Play Console. The service account you create will work across accounts.

1. Open your web browser
2. Go to https://console.cloud.google.com/
3. Sign in with your **Google Cloud account** (can be different from Play Console)
4. If prompted, select your project (or create one if needed)
   - If you don't have a project, click **CREATE PROJECT**
   - Name it something like `dr-copilot-ci-cd`
   - Click **CREATE**

### Step 2: Navigate to Service Accounts

1. In the left sidebar, click on **☰** (hamburger menu)
2. Hover over **IAM & Admin**
3. Click on **Service Accounts**
4. You should see a list of service accounts (might be empty)

### Step 3: Create New Service Account

1. Click the **+ CREATE SERVICE ACCOUNT** button at the top
2. Fill in the form:
   - **Service account name**: `github-actions-deploy`
   - **Service account ID**: Will auto-fill to `github-actions-deploy`
   - **Description**: `Automated Android deployment from GitHub Actions`
3. Click **CREATE AND CONTINUE**

### Step 4: Skip Role Assignment

1. In the "Grant this service account access to project" section
2. **Do NOT select any roles** (we'll grant permissions in Play Console instead)
3. Click **CONTINUE**

### Step 5: Skip User Access

1. In the "Grant users access to this service account" section
2. Leave it blank
3. Click **DONE**

### Step 6: Create JSON Key

1. You should now see your service account in the list
2. **Click on the service account name** (github-actions-deploy)
3. Go to the **KEYS** tab at the top
4. Click **ADD KEY** → **Create new key**
5. Select **JSON** as the key type
6. Click **CREATE**
7. A JSON file will download automatically
8. **IMPORTANT**: Save this file securely - you'll need it later
9. **Note the service account email** - it looks like:
   ```
   github-actions-deploy@your-project-123456.iam.gserviceaccount.com
   ```

---

## Part 2: Grant Permissions in Google Play Console

### Step 7: Access Google Play Console

> [!IMPORTANT]
> If you used a **different Google account** for Google Cloud Console, that's fine! You'll now sign in to Play Console with your **Play Console account** and link the service account you just created.

1. Go to https://play.google.com/console/
2. Sign in with your **Google Play Console account**
3. Select your app (**Dr. Copilot**)

### Step 8: Navigate to Users and Permissions

> [!IMPORTANT]
> **Google Play Console Updated in 2025**: The "API access" menu has been **removed or relocated**. Service accounts are now managed through **"Users and permissions"**.

1. In the Google Play Console left sidebar, click **"Users and permissions"**
2. This is where you'll grant access to your service account

### Step 9: Invite Service Account as User

> [!NOTE]
> You're now inviting the service account as if it were a user, but with API-specific permissions.

1. Click **"Invite new users"** button (top right)
2. In the **"Email address"** field, paste your service account email:
   ```
   github-actions-deploy@drcopilot-bfc9e.iam.gserviceaccount.com
   ```
   (Use the exact email from Step 6)
3. **Do not** set an access expiration date (leave it permanent)

### Step 10: Grant Permissions to Service Account

> [!IMPORTANT]
> These are the **minimum required permissions** for deployment:

1. Under **"App permissions"**, select your app (**Dr. Copilot**)
2. Under **"Account permissions"**, you can choose:
   
   **Option A: Admin (Recommended - You chose this)**
   - ✅ **"Admin (all permissions)"**
   - Gives full access to manage releases, view reports, etc.
   
   **Option B: Minimal Permissions**
   - ✅ **"View app information and download bulk reports (read-only)"**
   - ✅ **"Manage testing releases"** (for internal testing only)

3. Scroll down and click **"Invite user"**
4. The invitation will be sent (service accounts auto-accept)

### Step 11: Verify Service Account Access

1. You should now see the service account listed under **"Users and permissions"**
2. Status should show as **"Active"** or **"Invitation accepted"**
3. Permissions should show the ones you just granted

### Step 12: Wait for Permissions to Propagate

⏰ **CRITICAL**: Service account permissions take **24-48 hours** to fully propagate!

- Make a note of the current date and time
- Set a reminder for 48 hours from now
- Do not attempt to use the workflow until after this waiting period

---

## Part 3: Add Secret to Doppler

### Step 13: Verify Service Account is in Doppler

✅ **Already completed!** The service account JSON has been uploaded to Doppler as `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`.

You can verify by running:
```bash
doppler secrets get GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
```

> [!NOTE]
> The workflow uses a **dual-source approach** for maximum reliability:
> 1. **Primary**: Fetches from Doppler
> 2. **Fallback**: Uses GitHub Secrets if Doppler fails
> 
> This ensures deployment continues even if one source is temporarily unavailable.

### Step 14: Verify DOPPLER_TOKEN in GitHub

1. Go to https://github.com/alionour33/dr_copilot (or your repo URL)
2. Click **Settings** tab (far right)
3. In the left sidebar, click **Secrets and variables**
4. Click **Actions**
5. Verify `DOPPLER_TOKEN` exists in the secrets list

If it doesn't exist, you'll need to add it from your Doppler dashboard.

### Step 14b: (Optional) Add GitHub Secrets Backup

> [!TIP]
> **Recommended for redundancy**: Store the service account JSON in GitHub Secrets as a backup.
> The workflow will automatically use Doppler first, then fall back to GitHub if Doppler fails.

1. If you want a backup, click **New repository secret**
2. Name: `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
3. Value: Paste the entire JSON content from `C:\Users\Ali Nour\Downloads\drcopilot-bfc9e-1fcb140bf1c2.json`
4. Click **Add secret**

This provides redundancy: Doppler (primary) → GitHub Secrets (fallback).

---

## Part 4: Verify Configuration

### Step 15: Check Package Name

1. Open your project in your code editor
2. Navigate to `android/app/build.gradle`
3. Find the `applicationId` line:
   ```gradle
   defaultConfig {
       applicationId "com.alionour.drcopilot"  // ← This line
       ...
   }
   ```
4. Verify it matches: `com.alionour.drcopilot`
5. If different, update the workflow file:
   - Open `.github/workflows/deploy-android-dev.yaml`
   - Find line with `packageName:`
   - Update to match your applicationId

### Step 16: Verify Workflow File Exists

1. Check that this file exists:
   ```
   .github/workflows/deploy-android-dev.yaml
   ```
2. If it doesn't exist, the file was already created for you

### Step 17: Ensure You Have a Dev Branch

1. Open terminal in your project directory
2. Check if dev branch exists:
   ```bash
   git branch -a
   ```
3. If `dev` branch doesn't exist locally, create it:
   ```bash
   git checkout -b dev
   ```
4. **Push dev branch to GitHub** (required for workflow to trigger):
   ```bash
   git push -u origin dev
   ```
   
   > [!IMPORTANT]
   > The dev branch **must exist on GitHub** for the workflow to trigger! 
   > If you get authentication errors, you may need to:
   > - Use GitHub CLI: `gh auth login`
   > - Or use SSH: Update remote to SSH URL
   > - Or authenticate via GitHub Desktop

5. Verify dev branch is on GitHub:
   - Go to https://github.com/YOUR_USERNAME/dr_copilot
   - Check that "dev" appears in the branch dropdown

---

## Part 5: First Deployment Test (After 48 Hours)

### Step 18: Wait for Permissions

⏰ **You must wait 24-48 hours after Step 11 before proceeding!**

### Step 19: Make a Test Change

1. Ensure you're on the dev branch:
   ```bash
   git checkout dev
   git pull origin dev
   ```

2. Make a small test change:
   ```bash
   echo "# Testing auto-deployment" >> README.md
   ```

3. Commit the change:
   ```bash
   git add README.md
   git commit -m "test: trigger Google Play internal testing deployment"
   ```

4. Push to dev branch:
   ```bash
   git push origin dev
   ```

### Step 20: Monitor GitHub Actions

1. Go to your GitHub repository
2. Click the **Actions** tab
3. You should see a new workflow run:
   - Name: "Deploy Android to Google Play Internal Testing"
   - Status: Yellow (in progress) or Green (completed)
4. Click on the workflow run to see detailed logs
5. Watch the steps execute:
   - ✅ Checkout code
   - ✅ Set up Flutter
   - ✅ Get build number
   - ✅ Update version
   - ✅ Install dependencies
   - ✅ Build App Bundle
   - ✅ **Upload to Google Play** ← Most important step
   - ✅ Upload artifacts
   - ✅ Comment on commit

### Step 21: Check for Errors

If the workflow **fails**:

1. Click on the failed step to see error details
2. Common errors and solutions:

   **"Service account not authorized"**
   - Wait the full 48 hours
   - Check permissions in Play Console
   - Verify service account email matches exactly

   **"Package not found"**
   - Verify package name matches in build.gradle
   - Ensure app is published (at least in closed testing)

   **"Doppler secrets not found"**
   - Check DOPPLER_TOKEN secret exists in GitHub
   - Verify Doppler project configuration

   **"Invalid JSON"**
   - Re-copy the service account JSON
   - Ensure no extra spaces or characters
   - Re-add the GitHub secret

### Step 22: Verify in Google Play Console

1. Go to https://play.google.com/console/
2. Select your app (Dr. Copilot)
3. Click **Testing** in the left sidebar
4. Click **Internal testing**
5. Under **Releases**, you should see:
   - A new release with version code matching the commit count
   - Status: "Available"
   - Upload time: Just now

If you see the release, **congratulations!** 🎉

---

## Part 6: Add Internal Testers

### Step 23: Create Tester List

1. Still in **Internal testing** section
2. Click the **Testers** tab
3. Click **Create email list**
4. Name it: `Internal Testers`
5. Add email addresses of testers (one per line):
   ```
   tester1@example.com
   tester2@example.com
   ```
6. Click **Save changes**

### Step 24: Share Testing Link

1. In the **Testers** tab, find the **How testers join your test** section
2. Copy the **opt-in URL**
3. Share this URL with your testers via:
   - Email
   - Slack
   - Discord
   - Internal documentation

### Step 25: Testers Join and Install

Instruct your testers to:
1. Click the opt-in URL
2. Click **Become a tester**
3. Open Google Play Store on their Android device
4. Search for "Dr. Copilot" or use the direct link
5. Install the app
6. They'll receive updates automatically when you push to dev

---

## Part 7: Regular Usage

### Step 26: Daily Development Workflow

From now on, every time you push to the `dev` branch:

1. **Develop your feature**:
   ```bash
   git checkout -b feature/my-new-feature
   # Make changes
   git commit -am"feat: add new feature"
   ```

2. **Merge to dev**:
   ```bash
   git checkout dev
   git pull origin dev
   git merge feature/my-new-feature
   git push origin dev
   ```

3. **Automatic deployment happens**:
   - GitHub Actions builds the .aab
   - Uploads to Google Play internal testing
   - Testers receive update notification
   - Version number auto-increments

4. **Monitor in Actions tab**:
   - Check workflow completes successfully
   - Look for green checkmarks

5. **Testers receive update**:
   - They get a Play Store notification
   - Can update via Play Store
   - Provide feedback on new features

### Step 27: When Ready for Production

When a build is stable and ready for production:

1. **Promote from internal testing** (optional):
   ```
   Internal testing → Closed testing → Open testing → Production
   ```

2. **Or use production workflow**:
   ```bash
   git checkout main
   git merge dev
   git tag v1.0.0
   git push origin main --tags
   ```
   This triggers the existing `deploy-android.yaml` workflow

---

## 🎯 Quick Reference

### Trigger Auto-Deployment
```bash
git checkout dev
git pull origin dev
# Make changes
git commit -am "your message"
git push origin dev
```

### Check Deployment Status
1. GitHub → Actions tab
2. Look for "Deploy Android to Google Play Internal Testing"
3. Click to view logs

### View in Play Console
1. Play Console → Your App
2. Testing → Internal testing
3. Releases tab

### Manual Workflow Trigger
1. GitHub → Actions tab
2. "Deploy Android to Google Play Internal Testing"
3. Run workflow → Select `dev` branch

---

## ⚠️ Important Reminders

- ✅ Wait **24-48 hours** after granting permissions before first test
- ✅ Build numbers always increment (can't reuse)
- ✅ This deploys to **internal testing only**
- ✅ Production releases use the existing workflow
- ✅ Keep service account JSON secret secure
- ✅ Maximum 100 internal testers per track

---

## 🆘 Troubleshooting

If something goes wrong:
1. Check GitHub Actions logs for error messages
2. Verify Google Play Console permissions
3. Ensure 48-hour waiting period has passed
4. Check all secrets are correctly set
5. Verify package name matches

For detailed troubleshooting, see [GOOGLE_PLAY_DEPLOYMENT.md](file:///f:/Ali/Projects/alionour33/dr_copilot/GOOGLE_PLAY_DEPLOYMENT.md)

---

## ✅ Success Checklist

You know it's working when:
- [ ] Workflow runs successfully on dev branch pushes
- [ ] Green checkmarks in GitHub Actions
- [ ] New releases appear in Play Console internal testing
- [ ] Version codes increment with each build
- [ ] Testers can install and update via Play Store
- [ ] Commit gets an automated success comment

**That's it! You're now set up for automatic deployments!** 🚀
