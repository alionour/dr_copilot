# Dual-Source Secret Management

## Overview

The deployment workflow now uses a **dual-source approach** for maximum reliability:

```
1st Attempt: Doppler (Primary)
     ↓ (if fails)
2nd Attempt: GitHub Secrets (Fallback)
     ↓ (if both fail)
Deployment fails with error
```

## How It Works

### In the Workflow

```yaml
- name: Get service account JSON from Doppler (with GitHub fallback)
  run: |
    # Try Doppler first
    if SA_JSON=$(doppler secrets get GOOGLE_PLAY_SERVICE_ACCOUNT_JSON --plain 2>/dev/null); then
      echo "✅ Using service account from Doppler"
      # Use Doppler value
    elif [ -n "${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON }}" ]; then
      echo "⚠️ Doppler failed, using service account from GitHub Secrets"
      # Use GitHub Secrets value
    else
      echo "❌ Service account JSON not found in either source"
      exit 1
    fi
```

### Workflow Execution

The workflow will:
1. **Attempt Doppler** - Try to fetch from Doppler CLI
2. **Silent failure** - If Doppler fails, don't error immediately
3. **Check GitHub** - Look for the secret in GitHub Secrets
4. **Use fallback** - If found in GitHub, use that instead
5. **Only fail if both fail** - Only error if neither source has the secret

## Benefits

✅ **High availability** - Deployment continues even if Doppler is down  
✅ **Automatic failover** - No manual intervention needed  
✅ **Visible in logs** - Workflow logs show which source was used  
✅ **Easy testing** - Can test failover by temporarily removing from Doppler  
✅ **Zero downtime** - Deployments won't fail due to single point of failure

## Setup

### Current Status (Recommended)
- ✅ **Doppler**: `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` (Primary)
- ⚠️ **GitHub Secrets**: `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` (Not set - Optional backup)

### To Add GitHub Secrets Backup (Optional)

1. Go to GitHub repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
4. Value: Paste JSON content from downloaded file
5. Click "Add secret"

## Testing the Fallback

To verify the fallback mechanism works:

### Test Doppler Success
```bash
# Normal deployment - should use Doppler
git push origin dev
# Check workflow logs for: ✅ Using service account from Doppler
```

### Test GitHub Fallback
```bash
# Temporarily remove from Doppler
doppler secrets delete GOOGLE_PLAY_SERVICE_ACCOUNT_JSON

# Push to trigger deployment
git push origin dev
# Check workflow logs for: ⚠️ Doppler failed, using service account from GitHub Secrets

# Restore to Doppler
doppler secrets set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON < service-account.json
```

## When Fallback Triggers

The workflow will use GitHub Secrets fallback when:
- Doppler CLI is unavailable
- Network issues connecting to Doppler
- `DOPPLER_TOKEN` is invalid/expired
- Secret not found in Doppler project
- Doppler service is down

## Logs

**Using Doppler (Normal):**
```
Get service account JSON from Doppler (with GitHub fallback)
✅ Using service account from Doppler
```

**Using GitHub Fallback:**
```
Get service account JSON from Doppler (with GitHub fallback)
⚠️ Doppler failed, using service account from GitHub Secrets
```

**Both Failed:**
```
Get service account JSON from Doppler (with GitHub fallback)
❌ Service account JSON not found in Doppler or GitHub Secrets
Error: Process completed with exit code 1.
```

## Extending to Other Secrets

You can use the same pattern for other Doppler secrets:

```yaml
- name: Get keystore password (with fallback)
  run: |
    if KS_PASS=$(doppler secrets get ANDROID_KEYSTORE_PASSWORD --plain 2>/dev/null); then
      echo "Using keystore password from Doppler"
      echo "password=$KS_PASS" >> $GITHUB_OUTPUT
    elif [ -n "${{ secrets.ANDROID_KEYSTORE_PASSWORD }}" ]; then
      echo "Using keystore password from GitHub Secrets"
      echo "password=${{ secrets.ANDROID_KEYSTORE_PASSWORD }}" >> $GITHUB_OUTPUT
    else
      echo "Keystore password not found"
      exit 1
    fi
```

## Best Practices

1. **Keep Doppler as primary** - It's more secure and centralized
2. **Add GitHub backup for critical secrets** - Like service accounts, keystores
3. **Monitor workflow logs** - Check which source is being used
4. **Test fallback periodically** - Ensure GitHub backup is up to date
5. **Document secret locations** - Keep track of what's where

## Security Considerations

- Both Doppler and GitHub Secrets are encrypted at rest
- GitHub Secrets are masked in logs (not visible)
- Doppler provides centralized secret management
- Having secrets in both places increases attack surface slightly
- Trade-off: Availability vs. minimal attack surface
- **Recommended**: Use for critical deployment secrets only

---

**This dual-source approach ensures your deployments are resilient to single points of failure.** 🛡️
