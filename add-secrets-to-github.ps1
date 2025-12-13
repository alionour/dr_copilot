#!/usr/bin/env pwsh
# Automated script to add secrets to GitHub repository using GitHub CLI

Write-Host "`n🔐 Adding Secrets to GitHub Repository" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

# Check if gh CLI is installed and authenticated
try {
    $ghAuth = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ GitHub CLI not authenticated" -ForegroundColor Red
        Write-Host "Run: gh auth login" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✅ GitHub CLI authenticated" -ForegroundColor Green
} catch {
    Write-Host "❌ GitHub CLI not found" -ForegroundColor Red
    Write-Host "Install from: https://cli.github.com/" -ForegroundColor Yellow
    exit 1
}

# Secrets to add
$secrets = @(
    "ANDROID_KEYSTORE_BASE64",
    "ANDROID_KEYSTORE_PASSWORD",
    "ANDROID_KEY_PASSWORD",
    "ANDROID_KEY_ALIAS",
    "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"
)

Write-Host "`nAdding secrets to alionour/dr_copilot..." -ForegroundColor Yellow

$successCount = 0
$errorCount = 0

foreach ($secret in $secrets) {
    $tempFile = "temp_$secret.txt"
    
    if (Test-Path $tempFile) {
        try {
            Write-Host "`n  Adding $secret..." -ForegroundColor Cyan
            
            # Read secret value from temp file
            $value = Get-Content $tempFile -Raw
            
            # Add secret using gh CLI
            $value | gh secret set $secret --repo alionour/dr_copilot
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✅ $secret added successfully" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "  ❌ Failed to add $secret" -ForegroundColor Red
                $errorCount++
            }
        } catch {
            $errorMsg = $_.Exception.Message
            Write-Host "  ❌ Error adding ${secret}: $errorMsg" -ForegroundColor Red
            $errorCount++
        }
    } else {
        Write-Host "  ⚠️  $tempFile not found - skipping" -ForegroundColor Yellow
        $errorCount++
    }
}

Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
Write-Host "Results:" -ForegroundColor Cyan
Write-Host "  ✅ Success: $successCount" -ForegroundColor Green
Write-Host "  ❌ Failed: $errorCount" -ForegroundColor Red

if ($successCount -eq $secrets.Count) {
    Write-Host "`n🎉 All secrets added successfully!" -ForegroundColor Green
    Write-Host "`nCleaning up temp files..." -ForegroundColor Yellow
    Remove-Item temp_*.txt -ErrorAction SilentlyContinue
    Write-Host "✅ Temp files deleted" -ForegroundColor Green
    
    Write-Host "`n🚀 Next steps:" -ForegroundColor Cyan
    Write-Host "1. Workflow is ready to run!" -ForegroundColor White
    Write-Host "2. Push to dev branch to trigger deployment:" -ForegroundColor White
    Write-Host "   git push origin dev" -ForegroundColor Yellow
    Write-Host "3. Monitor at: https://github.com/alionour/dr_copilot/actions" -ForegroundColor White
} else {
    Write-Host "`n⚠️  Some secrets failed to add" -ForegroundColor Yellow
    Write-Host "Check errors above and try again" -ForegroundColor Yellow
}

Write-Host ""
